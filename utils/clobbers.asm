.define utils.clobbers

;====
; Dependencies
;====
.ifndef utils.registers.ENABLED
    .include "utils/registers.asm"
.endif

;====
; Variables
;====
.define utils.clobbers.index -1       ; the current clobber scope

;====
; (Private) Starts a new clobber scope, specifying which registers are about to
; be clobbed.
;
; @in   clobbing    the registers being clobbed (utils.registers.XX constants
;                   ORed together)
;====
.macro "utils.clobbers._startScope" args clobbing
    utils.assert.range clobbing utils.registers.AF, utils.registers.ALL, "\.: clobbing should be the register.* constants ORed together"

    ; Increment the clobber index
    .if utils.clobbers.index == -1
        utils.registers.onInitialClobberScope
    .endif

    .redefine utils.clobbers.index utils.clobbers.index + 1

    ; Preserve registers that need preserving and are being clobbered
    utils.registers.getVulnerable
    utils.registers._preserveRegisters (clobbing & utils.registers.getVulnerable.returnValue)
.endm

;====
; Starts a clobber scope, in which the specific registers will be clobbered.
; If the current preserve scope needs these values to be preserved they will
; be pushed to the stack
;
; @in   ...registers    list of registers that will be clobbered
;                       Valid values:
;                           "AF", "BC", "DE", "HL", "IX", "IY", "I",
;                           "af", "bc", "de", "hl", "ix", "iy", "i"
;                           "AF'", "BC'", "DE'", "HL'"
;                           "af'", "bc'", "de'", "hl'",
;                           or one or more utils.registers.xx constants ORed
;                           together
;====
.macro "utils.clobbers"
    .if nargs == 0
        .print "\.: Expected at least 1 register to be passed\n"
        .fail
    .endif

    ; Combine (OR) all given registers into a single value
    .redefine \.._clobbing 0
    .repeat nargs
        ; Parse the register string into a constant
        utils.registers.parse \1
        .redefine \.._clobbing (\.._clobbing | utils.registers.parse.returnValue)
        .shift  ; shift args (\2 => \1)
    .endr

    utils.clobbers._startScope (\.._clobbing)
.endm

;====
; Starts a clobber scope that behaves the same way as standard scopes but
; supports jumps outside the clobber scope. The scope works independently from
; other active scopes so the branching logic knows what needs to be restored
;
; @in   ...registers    list of registers that will be clobbered
;                       Valid values:
;                           "AF", "BC", "DE", "HL", "IX", "IY", "I",
;                           "af", "bc", "de", "hl", "ix", "iy", "i"
;                           "AF'", "BC'", "DE'", "HL'"
;                           "af'", "bc'", "de'", "hl'",
;                           or one or more utils.registers.xx constants ORed
;                           together
;====
.macro "utils.clobbers.withBranching"
    .if nargs == 0
        .print "\.: Expected at least 1 register to be passed\n"
        .fail
    .endif

    ; Combine (OR) all given registers into a single value
    .redefine \.._clobbing 0
    .repeat nargs
        ; Parse the register string into a constant
        utils.registers.parse \1
        .redefine \.._clobbing (\.._clobbing | utils.registers.parse.returnValue)
        .shift  ; shift args (\2 => \1)
    .endr

    ;===
    ; Isolate the scope within its own preserve scope so it doesn't affect
    ; outer scopes, allowing conditional jumps to pop registers without
    ; causing mismatches in some edge cases
    ;===
    ; Get registers that should be preserved
    utils.registers.getProtected

    ; Start preserve scope
    utils.registers.preserve (\.._clobbing & utils.registers.getProtected.returnValue)

    ; Start clobber scope
    utils.clobbers._startScope (\.._clobbing)

    .define utils.clobbers{utils.clobbers.index}.isIsolated
.endm

;====
; Marks the end of a clobber scope
;====
.macro "utils.clobbers.end"
    ; Assert there are clobber scopes in progress
    .if utils.clobbers.index == -1
        .print "\. was called but no clobber scopes are in progress\n"
        .fail
    .endif

    ; If this is the last clobber scope in progress
    .if utils.clobbers.index == 0
        utils.registers.onFinalClobberScopeEnd
    .endif

    ; If this was an isolated scope
    .ifdef utils.clobbers{utils.clobbers.index}.isIsolated
        .undefine utils.clobbers{utils.clobbers.index}.isIsolated
        utils.registers.restore
    .endif

    .redefine utils.clobbers.index utils.clobbers.index - 1
.endm
