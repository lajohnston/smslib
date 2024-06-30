;====
; Utilities to handle efficient register preservation on the stack.
;
; Wrap macro calls within a preserve scope (utils.registers.preserve). Code
; that uses utils.clobbers to state which registers it clobbers will ensure
; the protected registers remain unclobbered.
;====
.define utils.registers.ENABLED

;====
; Settings
;====

;===
; If set to 1, clobber scopes will automatically start a preserve scope if one
; isn't already in progress
; (Default = 0)
;===
.ifndef utils.registers.AUTO_PRESERVE
    .define utils.registers.AUTO_PRESERVE 0
.endif

;===
; The maximum size of the i-register preservation stack. Any unused entries
; will be discarded by wla-z80 unless it's invoked with the -k option
; (Default = 8)
;===
.ifndef utils.registers.I_STACK_MAX_SIZE
    .define utils.registers.I_STACK_MAX_SIZE 8
.endif

;====
; Constants
;====
.define utils.registers.AF    %1
.define utils.registers.BC    %10
.define utils.registers.DE    %100
.define utils.registers.HL    %1000
.define utils.registers.IX    %10000
.define utils.registers.IY    %100000
.define utils.registers.I     %1000000

.define utils.registers.SHADOW_AF  %10000000
.define utils.registers.SHADOW_BC  %100000000
.define utils.registers.SHADOW_DE  %1000000000
.define utils.registers.SHADOW_HL  %10000000000

.define utils.registers.ALL   $ffff

;====
; Dependencies
;====
.ifndef utils.assert
    .include "utils/assert.asm"
.endif

.ifndef utils.ram
    .include "utils/ram.asm"
.endif

;====
; RAM
;====

;===
; A stack to preserve the i-register value, as it's inefficient to
; preserve on the main stack without clobbing AF.
;
; Increase the max size by defining the utils.registers.I_STACK_MAX_SIZE setting.
; wla-z80 should discard entries that aren't used unless using the -k option
;===
.repeat utils.registers.I_STACK_MAX_SIZE index index
    .ramsection "utils.registers.iStack.{index}" slot utils.ram.SLOT
        utils.registers.iStack.{index}: db
    .ends
.endr

;====
; Variables
;====
.define utils.registers.autoPreserveIndex -1  ; the current auto preserve scope
.define utils.registers.preserveIndex -1      ; the current preserve scope
.define utils.registers.iStackIndex -1        ; the current i register stack index

;===
; Also set:
;
; utils.registers.doNotClobber{preserveIndex}
;   the registers that should be preserved if they are about to be clobbered
;
; utils.registers.unpreserved{preserveIndex}
;   the registers that haven't been preserved on the stack yet, in the current
;   preserve scope or ancestor scopes
;
; utils.registers.stack{preserveIndex}_size
;   the number of registers currently preserved on the stack
;
; utils.registers.stack{preserveIndex}_{stackIndex}
;   the register that has been stored at a given stack index
;===

;====
; Called when the given register has been pushed to the stack
;
; @in   register    the register constant (i.e. utils.registers.AF, utils.registers.BC)
;====
.macro "utils.registers._registerPushed" args register
    ; Keep a record of the register on the variable stack
    .define \.\@stackSize (utils.registers.stack{utils.registers.preserveIndex}_size)
    .redefine utils.registers.stack{utils.registers.preserveIndex}_{\.\@stackSize} register
    .redefine utils.registers.stack{utils.registers.preserveIndex}_size (\.\@stackSize + 1)

    ; Remove the register from the 'unpreserved' list
    .define \.\@currentValue utils.registers.unpreserved{utils.registers.preserveIndex}
    .redefine utils.registers.unpreserved{utils.registers.preserveIndex} (\.\@currentValue ~ register)
.endm

;====
; Adds a register to the 'do not clobber' list. Registers on this list will be
; preserved when a clobber scope states it will clobber that register
;====
.macro "utils.registers._addDoNotClobber" args registers
    .define \.\@newValue (utils.registers.doNotClobber{utils.registers.preserveIndex} | registers)
    .redefine utils.registers.doNotClobber{utils.registers.preserveIndex} (\.\@newValue)
.endm

;====
; Creates a new preserve scope on top of the preserve scope stack
;====
.macro "utils.registers._pushPreserveScope"
    ; Increment preserve scope index
    .redefine utils.registers.preserveIndex utils.registers.preserveIndex + 1

    ; Default to an empty 'do not clobber' register list
    .define utils.registers.doNotClobber{utils.registers.preserveIndex} 0

    ; Check for existing preserve scopes
    .if utils.registers.preserveIndex > 0
        ; Inherit the unpreserved registers from the outer scope(s)
        ; Registers the outer scopes need that haven't been preserved yet
        .define \.\@previousDoNotClobber (utils.registers.doNotClobber{utils.registers.preserveIndex - 1})
        .define \.\@previousUnpreserved (utils.registers.unpreserved{utils.registers.preserveIndex - 1})
        utils.registers._addDoNotClobber (\.\@previousDoNotClobber & \.\@previousUnpreserved)
    .endif

    ; All registers are currently unpreserved in this scope
    .define utils.registers.unpreserved{utils.registers.preserveIndex} utils.registers.ALL

    ; Initialise stack size to 0
    .define utils.registers.stack{utils.registers.preserveIndex}_size 0
.endm

;====
; Pops the most recent preserve scope from the preserve scope variable stack
; without producing any restore instructions
;====
.macro "utils.registers.closePreserveScope"
    ; Assert there are preserve scopes in progress
    .if utils.registers.preserveIndex == -1
        .print "\.: was called but no preserve scopes are in progress\n"
        .fail
    .endif

    ; If I was preserved on i-stack
    .if (utils.registers.I & (utils.registers.unpreserved{utils.registers.preserveIndex} ~ $ff)) > 0
        ; Decrement i-stack size
        .redefine utils.registers.iStackIndex utils.registers.iStackIndex - 1
    .endif

    ; Clear preserve stack registers
    .repeat utils.registers.stack{utils.registers.preserveIndex}_size index index
        .undefine utils.registers.stack{utils.registers.preserveIndex}_{index}
    .endr

    ; Clean up registers
    .undefine utils.registers.doNotClobber{utils.registers.preserveIndex}
    .undefine utils.registers.unpreserved{utils.registers.preserveIndex}
    .undefine utils.registers.stack{utils.registers.preserveIndex}_size

    ; Decrement scope index
    .redefine utils.registers.preserveIndex utils.registers.preserveIndex - 1
.endm

;====
; Parse a register identifier into one of the register constants
;
; @in       rawValue    the register string (i.e. "AF", "af", "HL'", "hl'")
;                       or one or more register constants ORed together
;
; @out      utils.registers.parse.returnValue
;               defined with the register constant
;
; @fails    if the value cannot be parsed
;====
.macro "utils.registers.parse" args rawValue
    ; Resolve register string to a constant
    .if \?1 != ARG_STRING
        utils.assert.range \1 0 utils.registers.ALL "\.: Unknown register register value"
        .redefine utils.registers.parse.returnValue \1
    .elif rawValue == "AF" || rawValue == "af"
        .redefine utils.registers.parse.returnValue utils.registers.AF
    .elif rawValue == "BC" || rawValue == "bc"
        .redefine utils.registers.parse.returnValue utils.registers.BC
    .elif rawValue == "DE" || rawValue == "de"
        .redefine utils.registers.parse.returnValue utils.registers.DE
    .elif rawValue == "HL" || rawValue == "hl"
        .redefine utils.registers.parse.returnValue utils.registers.HL
    .elif rawValue == "IX" || rawValue == "ix"
        .redefine utils.registers.parse.returnValue utils.registers.IX
    .elif rawValue == "IY" || rawValue == "iy"
        .redefine utils.registers.parse.returnValue utils.registers.IY
    .elif rawValue == "I" || rawValue == "i"
        .redefine utils.registers.parse.returnValue utils.registers.I
    .elif rawValue == "AF'" || rawValue == "af'"
        .redefine utils.registers.parse.returnValue utils.registers.SHADOW_AF
    .elif rawValue == "BC'" || rawValue == "bc'"
        .redefine utils.registers.parse.returnValue utils.registers.SHADOW_BC
    .elif rawValue == "DE'" || rawValue == "de'"
        .redefine utils.registers.parse.returnValue utils.registers.SHADOW_DE
    .elif rawValue == "HL'" || rawValue == "hl'"
        .redefine utils.registers.parse.returnValue utils.registers.SHADOW_HL
    .else
        .print "\.: Unknown register value: ", string, "\n"
        .fail
    .endif
.endm

;====
; Restores the registers that have been preserved by the current preserve scope
;====
.macro "utils.registers.restoreRegisters"
    ; Assert there are preserve scopes in progress
    .if utils.registers.preserveIndex == -1
        .print "\.: was called but no preserve scopes are in progress\n"
        .fail
    .endif

    ; Check if we need to restore the I register
    .if (utils.registers.I & (utils.registers.unpreserved{utils.registers.preserveIndex} ~ $ff)) > 0
        .if utils.registers.iStackIndex == -1
            .print "\.: I stack popped but there's no value on it\n"
            .fail
        .endif

        ; This will clobber A - if it's needed it will be restored further below
        ld a, (utils.registers.iStack.{utils.registers.iStackIndex})
        ld i, a
    .endif

    ; Pop each register from the stack
    .redefine \.\@stackSize utils.registers.stack{utils.registers.preserveIndex}_size
    .repeat (\.\@stackSize) index index
        ; Reverse order (start from top of stack)
        .redefine index (\.\@stackSize) - index - 1

        ; Pop register identifier from variable stack
        .redefine \.\@register utils.registers.stack{utils.registers.preserveIndex}_{index}

        ; If it's one of the shadow registers
        .if \.\@register & (utils.registers.SHADOW_BC | utils.registers.SHADOW_DE | utils.registers.SHADOW_HL)
            ; Switch to shadow set if we haven't already
            .ifndef \.\@exxUsed
                exx
                .define \.\@exxUsed
            .endif
        .elif \.\@register & (utils.registers.BC | utils.registers.DE | utils.registers.HL)
            ; Non shadow register - switch to main set if needed
            .ifdef \.\@exxUsed
                exx ; switch back to non-shadow registers
                .undefine \.\@exxUsed
            .endif
        .endif

        ; Pop relevant register from RAM stack
        .if \.\@register == utils.registers.AF
            pop af
        .elif \.\@register == utils.registers.BC
            pop bc
        .elif \.\@register == utils.registers.DE
            pop de
        .elif \.\@register == utils.registers.HL
            pop hl
        .elif \.\@register == utils.registers.IX
            pop ix
        .elif \.\@register == utils.registers.IY
            pop iy
        .elif \.\@register == utils.registers.SHADOW_AF
            ex af, af'
                pop af'
            ex af, af'
        .elif \.\@register == utils.registers.SHADOW_BC
            pop bc' ; switched to shadow set above
        .elif \.\@register == utils.registers.SHADOW_DE
            pop de' ; switched to shadow set above
        .elif \.\@register == utils.registers.SHADOW_HL
            pop hl' ; switched to shadow set above
        .endif
    .endr

    ; Switch back to non-shadow registers if we've used exx
    .ifdef \.\@exxUsed
        exx
        .undefine \.\@exxUsed
    .endif
.endm

;====
; Adds the given registers to the preserve list. When a register.clobberStart is
; called with any of these registers, they will be preserved.
;
; @in   ...registers    (optional) strings of one or more register pair to
;                       preserve
;                       Valid values:
;                           "AF", "BC", "DE", "HL", "IX", "IY", "I"
;                           "af", "bc", "de", "hl", "ix", "iy", "i"
;                           "AF'", "BC'", "DE'", "HL'"
;                           "af'", "bc'", "de'", "hl'",
;                           or one or more utils.registers.xx constants ORed
;                           together
;                       Defaults to all registers
;====
.macro "utils.registers.preserve"
    ; Create a new preserve scope
    utils.registers._pushPreserveScope

    ; Add the given registers to the doNotClobber list
    .if nargs == 0
        ; If no args, preserve all the main registers by default
        utils.registers._addDoNotClobber utils.registers.ALL
    .else
        ; Combine (OR) all given args into doNotClobber value
        .repeat nargs
            ; Parse the register string into a constant
            utils.registers.parse \1
            .redefine \.\@register utils.registers.parse.returnValue

            ; Set given bit in doNotClobber
            utils.registers._addDoNotClobber (\.\@register)
            .shift  ; shift args
        .endr
    .endif
.endm

;====
; Marks the end of a preserve scope
;====
.macro "utils.registers.restore"
    ; Assert there are preserve scopes in progress
    .if utils.registers.preserveIndex == -1
        .print "\.: was called but no preserve scopes are in progress\n"
        .fail
    .endif

    ; Restore the registers
    utils.registers.restoreRegisters

    ; Remove the preserve scope
    utils.registers.closePreserveScope
.endm

;====
; Preserves the given list of registers
;
; @in   registers   the list of register constants (i.e. register.AF) ORed
;                   together into one value
;====
.macro "utils.registers._preserveRegisters" args registers
    .if registers & utils.registers.AF
        push af
        utils.registers._registerPushed utils.registers.AF
    .endif

    .if registers & utils.registers.BC
        push bc
        utils.registers._registerPushed utils.registers.BC
    .endif

    .if registers & utils.registers.DE
        push de
        utils.registers._registerPushed utils.registers.DE
    .endif

    .if registers & utils.registers.HL
        push hl
        utils.registers._registerPushed utils.registers.HL
    .endif

    .if registers & utils.registers.IX
        push ix
        utils.registers._registerPushed utils.registers.IX
    .endif

    .if registers & utils.registers.IY
        push iy
        utils.registers._registerPushed utils.registers.IY
    .endif

    .if registers & utils.registers.I
        .redefine utils.registers.iStackIndex utils.registers.iStackIndex + 1

        .if utils.registers.iStackIndex >= utils.registers.I_STACK_MAX_SIZE
            .print "\.: The I stack has exceeded its max size. Consider "
            .print "increasing the utils.registers.I_STACK_MAX_SIZE value\n"
            .fail
        .endif

        push af
            ld a, i
            ld (utils.registers.iStack.{utils.registers.iStackIndex}), a
        pop af

        utils.registers._registerPushed utils.registers.I
    .endif

    .if registers & utils.registers.SHADOW_AF
        ex af, af'
            push af
            utils.registers._registerPushed utils.registers.SHADOW_AF
        ex af, af'
    .endif

    ; 16-bit shadow registers
    .if registers & (utils.registers.SHADOW_BC|utils.registers.SHADOW_DE|utils.registers.SHADOW_HL)
        exx ; switch to shadow registers
            .if registers & utils.registers.SHADOW_BC
                push bc
                utils.registers._registerPushed utils.registers.SHADOW_BC
            .endif

            .if registers & utils.registers.SHADOW_DE
                push de
                utils.registers._registerPushed utils.registers.SHADOW_DE
            .endif

            .if registers & utils.registers.SHADOW_HL
                push hl
                utils.registers._registerPushed utils.registers.SHADOW_HL
            .endif
        exx ; switch back to non-shadow registers
    .endif
.endm

;====
; Returns the registers that are protected within the current preserve scope
; or its ancestors
;
; @out  utils.registers.getProtected.returnValue
;           the registers (i.e. utils.registers.AF) ORed into a single value
;====
.macro "utils.registers.getProtected"
    .if utils.registers.preserveIndex == -1
        .redefine utils.registers.getProtected.returnValue 0
    .else
        .redefine \.doNotClobber (utils.registers.doNotClobber{utils.registers.preserveIndex})
        .redefine utils.registers.getProtected.returnValue (\.doNotClobber)
    .endif
.endm

;====
; Returns the registers that should be protected but haven't been preserved yet
;
; @out  utils.registers.getVulnerable.returnValue
;           the registers (i.e. utils.registers.AF) ORed into a single value
;====
.macro "utils.registers.getVulnerable"
    .if utils.registers.preserveIndex == -1
        .redefine utils.registers.getVulnerable.returnValue 0
    .else
        .redefine \.doNotClobber (utils.registers.doNotClobber{utils.registers.preserveIndex})
        .redefine \.unpreserved (utils.registers.unpreserved{utils.registers.preserveIndex})
        .redefine utils.registers.getVulnerable.returnValue (\.doNotClobber & \.unpreserved)
    .endif
.endm

;====
; Should be called when the initial/outer-most clobber scope has been started
;====
.macro "utils.registers.onInitialClobberScope"
    ; If auto preserve is enabled and there are no existing preserve scopes
    .if utils.registers.AUTO_PRESERVE == 1 && utils.registers.preserveIndex == -1
        ; Preserve all registers including shadow registers
        utils.registers.preserve "af", "bc", "de", "hl", "ix", "iy", "i", "af'", "bc'", "de'", "hl'"
        .redefine utils.registers.autoPreserveIndex utils.registers.preserveIndex
    .endif
.endm

;====
; Should be called when the last/outer-most scope has been closed
;====
.macro "utils.registers.onFinalClobberScopeEnd"
    ; If this is the auto preserve scope
    .if utils.registers.preserveIndex > -1 && utils.registers.preserveIndex == utils.registers.autoPreserveIndex
        utils.registers.restore
        .redefine utils.registers.autoPreserveIndex -1
    .endif
.endm
