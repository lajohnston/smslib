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
; Starts a clobber scope, in which the specific registers will be clobbered.
; If the current preserve scope needs these values to be preserved they will
; be pushed to the stack
;
; @in   ...registers    list of registers that will be clobbered
;                       Valid values:
;                           "AF", "BC", "DE", "HL", "IX", "IY", "I",
;                           "af", "bc", "de", "hl", "ix", "iy", "i"
;                           "AF'", "BC'", "DE'", "HL'"
;                           "af'", "bc'", "de'", "hl'"
;====
.macro "utils.clobbers"
    .if nargs == 0
        .print "\.: Expected at least 1 register to be passed\n"
        .fail
    .endif

    .if utils.clobbers.index == -1
        utils.registers.onInitialClobberScope
    .endif

    ; Increment the clobber index
    .redefine utils.clobbers.index utils.clobbers.index + 1

    ; Combine (OR) all given registers into a single value
    .define \.\@_clobbing 0
    .repeat nargs
        ; Parse the register string into a constant
        utils.registers.parse \1
        .redefine \.\@_clobbing (\.\@_clobbing | utils.registers.parse.returnValue)
        .shift  ; shift args (\2 => \1)
    .endr

    ; Get list of registers that should be preserved but haven't been yet
    utils.registers.getVulnerable

    ; Preserve registers that are vulnerable and are being clobbered
    utils.registers._preserveRegisters (\.\@_clobbing & utils.registers.getVulnerable.returnValue)
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
