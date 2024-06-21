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
; @in   type        if "standard", registers that have already been preserved
;                   within the current preserve scope (or its ancestors) won't
;                   be preserved again. If "isolated", they will be preserved again.
;====
.macro "utils.clobbers._startScope" args clobbing type
    utils.assert.range clobbing utils.registers.AF, utils.registers.ALL, "\.: clobbing should be the register.* constants ORed together"

    ; Increment the clobber index
    .if utils.clobbers.index == -1
        utils.registers.onInitialClobberScope
    .endif

    .redefine utils.clobbers.index utils.clobbers.index + 1

    ; Preserve registers that need preserving and are being clobbered
    .if type == "standard"
        ; Registers that should be protected and haven't been yet
        utils.registers.getVulnerable
        utils.registers._preserveRegisters (clobbing & utils.registers.getVulnerable.returnValue)
    .elif type == "isolated"
        ; Registers that are marked as protected
        utils.registers.getProtected
        utils.registers._preserveRegisters (clobbing & utils.registers.getProtected.returnValue)
    .else
        utils.assert.fail "\.: Invalid type" type "standard or isolated"
    .endif
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

    utils.clobbers._startScope (\.._clobbing) "standard"
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
    ; Start an isolated clobber scope so it preserves registers independently of
    ; the preserve scope. This allows it to know what to restore when jumping
    ;===
    utils.clobbers._startScope (\.._clobbing) "isolated"
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

    .redefine utils.clobbers.index utils.clobbers.index - 1

    ; If there are no more clobber scopes in progress
    .if utils.clobbers.index == -1
        utils.registers.onFinalClobberScopeEnd
    .endif
.endm
