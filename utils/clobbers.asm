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
; @in   type        (Optional) if "isolated", the scope will be wrapped in its
;                   own preserve scope. This is needed for branching clobber
;                   scopes
;====
.macro "utils.clobbers._startScope" args clobbing type
    utils.assert.range clobbing utils.registers.AF, utils.registers.ALL, "\.: clobbing should be the register.* constants ORed together"

    ; Increment the clobber index
    .redefine utils.clobbers.index utils.clobbers.index + 1

    ; Inform utils.registers (which may start an auto-preserve scope)
    .if utils.clobbers.index == 0   ; first scope
        utils.registers.onInitialClobberScope
    .endif

    ; If this is an isolated scope, start a preserve scope to wrap it
    .ifdef type
        .if type == "isolated"
            ; Get registers protected by existing preserve scopes
            utils.registers.getProtected

            ; Start preserve scope to isolate this clobber scope
            utils.registers.preserve (clobbing & utils.registers.getProtected.returnValue)
            .define utils.clobbers{utils.clobbers.index}.isIsolated
        .endif
    .endif

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
    ; Start a clobber scope wrapped within its own preserve scope so it doesn't
    ; affect outer scopes, allowing conditional jumps to pop registers without
    ; causing mismatches in some edge cases
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

    ; If this was an isolated scope with its own preserve scope
    .ifdef utils.clobbers{utils.clobbers.index}.isIsolated
        .undefine utils.clobbers{utils.clobbers.index}.isIsolated
        utils.registers.restore
    .endif

    ; If this is the last clobber scope in progress
    .if utils.clobbers.index == 0
        utils.registers.onFinalClobberScopeEnd
    .endif

    .redefine utils.clobbers.index utils.clobbers.index - 1
.endm

;====
; If a utils.clobbers.withBranching is in progress, restores the registers from
; its isolated preserve scope. This should be called before making jumps outside
; of the clobber scope
;
; @fails    if no utils.clobbers.withBranching scope is in progress
;====
.macro "utils.clobbers.endBranch"
    ; Ensure current scope is an isolated/branching scope
    .ifndef utils.clobbers{utils.clobbers.index}.isIsolated
        .print "\. called but no utils.clobbing.withBranching in progress\n"
        .fail
    .endif

    ; Restore registers (but don't end preserve scope)
    utils.registers.restoreRegisters
.endm

;====
; Closes the current utils.clobbers.withBranching scope without restoring the
; registers. This can be used if a utils.clobber.endBranch has already been
; called separately
;
; @fails    if no utils.clobbers.withBranching scope is in progress
;====
.macro "utils.clobbers.closeBranch"
    ; Ensure current scope is an isolated/branching scope
    .ifndef utils.clobbers{utils.clobbers.index}.isIsolated
        .print "\. called but no utils.clobbing.withBranching in progress\n"
        .fail
    .endif

    ; End the branching preserve scope
    utils.registers.closePreserveScope
    .undefine utils.clobbers{utils.clobbers.index}.isIsolated
    utils.clobbers.end
.endm

;====
; If carry is set, restore the registers for the active
; utils.clobbers.withBranching scope and jumps to the given label. If there are
; no registers to restore will just generate the jp c instruction
;
; @in   label   the label to jump to if carry is set
;====
.macro "utils.clobbers.end.jpc" args label
    utils.assert.equals NARGS 1 "\.: Expected a label argument"
    utils.assert.label label "\.: Argument should be a label"

    ; Check if there are any registers to restore within this scope
    utils.registers.getProtected
    .if utils.registers.getProtected.returnValue == 0
        ; No registers to restore - just generate jump
        jp c, label
    .else
        jr nc, _\@_\.
            ; Restore registers then jump
            utils.clobbers.endBranch
            jp label
        _\@_\.:
    .endif
.endm

;====
; If carry is reset, restore the registers for the active
; utils.clobbers.withBranching scope and jumps to the given label. If there are
; no registers to restore will just generate the jp nc instruction
;
; @in   label   the label to jump to if carry is set
;====
.macro "utils.clobbers.end.jpnc" args label
    utils.assert.equals NARGS 1 "\.: Expected a label argument"
    utils.assert.label label "\.: Argument should be a label"

    ; Check if there are any registers to restore within this scope
    utils.registers.getProtected
    .if utils.registers.getProtected.returnValue == 0
        ; No registers to restore - just generate jump
        jp nc, label
    .else
        jr c, _\@_\.
            ; Restore registers then jump
            utils.clobbers.endBranch
            jp label
        _\@_\.:
    .endif
.endm

;====
; If carry is set, restore the registers for the active
; utils.clobbers.withBranching scope and relative jumps to the given label. If
; there are no registers to restore will just generate the jr c instruction
;
; @in   label   the label to jump to if carry is set
;====
.macro "utils.clobbers.end.jrc" args label
    utils.assert.equals NARGS 1 "\.: Expected a label argument"
    utils.assert.label label "\.: Argument should be a label"

    ; Check if there are any registers to restore within this scope
    utils.registers.getProtected
    .if utils.registers.getProtected.returnValue == 0
        ; No registers to restore - just generate jump
        jr c, label
    .else
        jr nc, _\@_\.
            ; Restore registers then jump
            utils.clobbers.endBranch
            jr label
        _\@_\.:
    .endif
.endm

;====
; If carry is reset, restore the registers for the active
; utils.clobbers.withBranching scope and relative jumps to the given label. If
; there are no registers to restore will just generate the jr nc instruction
;
; @in   label   the label to jump to if carry is set
;====
.macro "utils.clobbers.end.jrnc" args label
    utils.assert.equals NARGS 1 "\.: Expected a label argument"
    utils.assert.label label "\.: Argument should be a label"

    ; Check if there are any registers to restore within this scope
    utils.registers.getProtected
    .if utils.registers.getProtected.returnValue == 0
        ; No registers to restore - just generate jump
        jr nc, label
    .else
        jr c, _\@_\.
            ; Restore registers then jump
            utils.clobbers.endBranch
            jr label
        _\@_\.:
    .endif
.endm

;====
; If parity/overflow is set, restore the registers for the active
; utils.clobbers.withBranching scope and jumps to the given label. If there are
; no registers to restore will just generate the jp po instruction
;
; @in   label   the label to jump to if carry is set
;====
.macro "utils.clobbers.end.jppe" args label
    utils.assert.equals NARGS 1 "\.: Expected a label argument"
    utils.assert.label label "\.: Argument should be a label"

    ; Check if there are any registers to restore within this scope
    utils.registers.getProtected
    .if utils.registers.getProtected.returnValue == 0
        ; No registers to restore - just generate jump
        jp pe, label
    .else
        jp po, _\@_\.
            ; Restore registers then jump
            utils.clobbers.endBranch
            jp label
        _\@_\.:
    .endif
.endm

;====
; If parity/overflow is reset, restore the registers for the active
; utils.clobbers.withBranching scope and jumps to the given label. If there are
; no registers to restore will just generate the jp po instruction
;
; @in   label   the label to jump to if carry is set
;====
.macro "utils.clobbers.end.jppo" args label
    utils.assert.equals NARGS 1 "\.: Expected a label argument"
    utils.assert.label label "\.: Argument should be a label"

    ; Check if there are any registers to restore within this scope
    utils.registers.getProtected
    .if utils.registers.getProtected.returnValue == 0
        ; No registers to restore - just generate jump
        jp po, label
    .else
        jp pe, _\@_\.
            ; Restore registers then jump
            utils.clobbers.endBranch
            jp label
        _\@_\.:
    .endif
.endm

;====
; If sign is reset, restore the registers for the active
; utils.clobbers.withBranching scope and jumps to the given label. If there are
; no registers to restore will just generate the jp p instruction
;
; @in   label   the label to jump to if carry is set
;====
.macro "utils.clobbers.end.jpp" args label
    utils.assert.equals NARGS 1 "\.: Expected a label argument"
    utils.assert.label label "\.: Argument should be a label"

    ; Check if there are any registers to restore within this scope
    utils.registers.getProtected
    .if utils.registers.getProtected.returnValue == 0
        ; No registers to restore - just generate jump
        jp p, label
    .else
        jp m, _\@_\.
            ; Restore registers then jump
            utils.clobbers.endBranch
            jp label
        _\@_\.:
    .endif
.endm

;====
; If sign is set, restore the registers for the active
; utils.clobbers.withBranching scope and jumps to the given label. If there are
; no registers to restore will just generate the jp m instruction
;
; @in   label   the label to jump to if carry is set
;====
.macro "utils.clobbers.end.jpm" args label
    utils.assert.equals NARGS 1 "\.: Expected a label argument"
    utils.assert.label label "\.: Argument should be a label"

    ; Check if there are any registers to restore within this scope
    utils.registers.getProtected
    .if utils.registers.getProtected.returnValue == 0
        ; No registers to restore - just generate jump
        jp m, label
    .else
        jp p, _\@_\.
            ; Restore registers then jump
            utils.clobbers.endBranch
            jp label
        _\@_\.:
    .endif
.endm

;====
; If Z is set, restore the registers for the active utils.clobbers.withBranching
; scope and jumps to the given label. If there are no registers to restore will
; just generate the jp z instruction
;
; @in   label   the label to jump to if Z is set
;====
.macro "utils.clobbers.end.jpz" args label
    utils.assert.equals NARGS 1 "\.: Expected a label argument"
    utils.assert.label label "\.: Argument should be a label"

    ; Check if there are any registers to restore within this scope
    utils.registers.getProtected
    .if utils.registers.getProtected.returnValue == 0
        ; No registers to restore - just generate jump
        jp z, label
    .else
        jr nz, _\@_\.
            ; Restore registers then jump
            utils.clobbers.endBranch
            jp label
        _\@_\.:
    .endif
.endm

;====
; If NZ is set, restore the registers for the active utils.clobbers.withBranching
; scope and jumps to the given label. If there are no registers to restore will
; just generate the jp nz instruction
;
; @in   label   the label to jump to if Z is reset
;====
.macro "utils.clobbers.end.jpnz" args label
    utils.assert.equals NARGS 1 "\.: Expected a label argument"
    utils.assert.label label "\.: Argument should be a label"

    ; Check if there are any registers to restore within this scope
    utils.registers.getProtected
    .if utils.registers.getProtected.returnValue == 0
        ; No registers to restore - just generate jump
        jp nz, label
    .else
        jr z, _\@_\.
            ; Restore registers then jump
            utils.clobbers.endBranch
            jp label
        _\@_\.:
    .endif
.endm

;====
; If Z is set, restore the registers for the active utils.clobbers.withBranching
; scope and relative jumps to the given label. If there are no registers to
; restore will just generate the jr z instruction
;
; @in   label   the label to jump to if Z is set
;====
.macro "utils.clobbers.end.jrz" args label
    utils.assert.equals NARGS 1 "\.: Expected a label argument"
    utils.assert.label label "\.: Argument should be a label"

    ; Check if there are any registers to restore within this scope
    utils.registers.getProtected
    .if utils.registers.getProtected.returnValue == 0
        ; No registers to restore - just generate jump
        jr z, label
    .else
        jr nz, _\@_\.
            ; Restore registers then jump
            utils.clobbers.endBranch
            jr label
        _\@_\.:
    .endif
.endm

;====
; If NZ is set, restore the registers for the active utils.clobbers.withBranching
; scope and relative jumps to the given label. If there are no registers to
; restore will just generate the jr nz instruction
;
; @in   label   the label to jump to if Z is reset
;====
.macro "utils.clobbers.end.jrnz" args label
    utils.assert.equals NARGS 1 "\.: Expected a label argument"
    utils.assert.label label "\.: Argument should be a label"

    ; Check if there are any registers to restore within this scope
    utils.registers.getProtected
    .if utils.registers.getProtected.returnValue == 0
        ; No registers to restore - just generate jump
        jr nz, label
    .else
        jr z, _\@_\.
            ; Restore registers then jump
            utils.clobbers.endBranch
            jr label
        _\@_\.:
    .endif
.endm
