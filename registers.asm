;====
; Utilities to handle efficient register preservation on the stack.
;
; Macros that clobber registers can wrap the their code with registers.clobbers
; and registers.clobberEnd, stating which registers they clobber.
;
; Code that requires registers to be preserved when calling macros can wrap
; the call in registers.preserve and registers.restore calls. Any registers
; in the preserve list and that get clobbered will be preserved
;====
.define registers.ENABLED

;====
; Settings
;====

;===
; If set to 1, clobber scopes will automatically start a preserve scope if one
; isn't already in progress
; (Default = 0)
;===
.ifndef registers.AUTO_PRESERVE
    .define registers.AUTO_PRESERVE 0
.endif

;===
; The maximum size of the i-register preservation stack. Any unused entries
; will be discarded by wla-z80 unless it's invoked with the -k option
; (Default = 8)
;===
.ifndef registers.I_STACK_MAX_SIZE
    .define registers.I_STACK_MAX_SIZE 8
.endif

;====
; Constants
;====
.define registers.AF    %1
.define registers.BC    %10
.define registers.DE    %100
.define registers.HL    %1000
.define registers.IX    %10000
.define registers.IY    %100000
.define registers.I     %1000000
.define registers.ALL   %1111111

.define registers.SHADOW_AF  %10000000
.define registers.SHADOW_BC  %100000000
.define registers.SHADOW_DE  %1000000000
.define registers.SHADOW_HL  %10000000000
.define registers.SHADOW_ALL registers.SHADOW_AF | registers.SHADOW_BC | registers.SHADOW_DE | registers.SHADOW_HL

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
; Increase the max size by defining the registers.I_STACK_MAX_SIZE setting.
; wla-z80 should discard entries that aren't used unless using the -k option
;===
.repeat registers.I_STACK_MAX_SIZE index index
    .ramsection "registers.iStack.{index}" slot utils.ram.SLOT
        registers.iStack.{index}: db
    .ends
.endr

;====
; Variables
;====
.define registers.autoPreserveIndex -1  ; the current auto preserve scope
.define registers.clobberIndex -1       ; the current clobber scope
.define registers.preserveIndex -1      ; the current preserve scope
.define registers.iStackIndex -1        ; the current i register stack index

;===
; Also set:
;
; registers.doNotClobber{preserveIndex}
;   the registers that should be preserved if they are about to be clobbered
;
; registers.unpreserved{preserveIndex}
;   the registers that haven't been preserved on the stack yet, in the current
;   preserve scope or ancestor scopes
;
; registers.stack{preserveIndex}_size
;   the number of registers currently preserved on the stack
;
; registers.stack{preserveIndex}_{stackIndex}
;   the register that has been stored at a given stack index
;===

;====
; Called when the given register has been pushed to the stack
;
; @in   register    the register constant (i.e. registers.AF, registers.BC)
;====
.macro "registers._registerPushed" args register
    ; Keep a record of the register on the variable stack
    .define \.\@stackSize (registers.stack{registers.preserveIndex}_size)
    .redefine registers.stack{registers.preserveIndex}_{\.\@stackSize} register
    .redefine registers.stack{registers.preserveIndex}_size (\.\@stackSize + 1)

    ; Remove the register from the 'unpreserved' list
    .define \.\@currentValue registers.unpreserved{registers.preserveIndex}
    .redefine registers.unpreserved{registers.preserveIndex} (\.\@currentValue ~ register)
.endm

;====
; Adds a register to the 'do not clobber' list. Registers on this list will be
; preserved when a clobber scope states it will clobber that register
;====
.macro "registers._addDoNotClobber" args registers
    .define \.\@newValue (registers.doNotClobber{registers.preserveIndex} | registers)
    .redefine registers.doNotClobber{registers.preserveIndex} (\.\@newValue)
.endm

;====
; Creates a new preserve scope on top of the preserve scope stack
;====
.macro "registers._pushPreserveScope"
    ; Increment preserve scope index
    .redefine registers.preserveIndex registers.preserveIndex + 1

    ; Default to an empty 'do not clobber' register list
    .define registers.doNotClobber{registers.preserveIndex} 0

    ; Check for existing preserve scopes
    .if registers.preserveIndex > 0
        ; Inherit the unpreserved registers from the outer scope(s)
        ; Registers the outer scopes need that haven't been preserved yet
        .define \.\@previousDoNotClobber (registers.doNotClobber{registers.preserveIndex - 1})
        .define \.\@previousUnpreserved (registers.unpreserved{registers.preserveIndex - 1})
        registers._addDoNotClobber (\.\@previousDoNotClobber & \.\@previousUnpreserved)
    .endif

    ; All registers are currently unpreserved in this scope
    .define registers.unpreserved{registers.preserveIndex} (registers.ALL | registers.SHADOW_ALL)

    ; Initialise stack size to 0
    .define registers.stack{registers.preserveIndex}_size 0
.endm

;====
; Pops the most recent preserve scope from the preserve scope variable stack
;====
.macro "registers._popPreserveScope"
    ; Assert there are preserve scopes in progress
    .if registers.preserveIndex == -1
        .print "\.: was called but no preserve scopes are in progress\n"
        .fail
    .endif

    ; Clean up registers
    .undefine registers.doNotClobber{registers.preserveIndex}
    .undefine registers.unpreserved{registers.preserveIndex}
    .undefine registers.stack{registers.preserveIndex}_size

    ; Decrement scope index
    .redefine registers.preserveIndex registers.preserveIndex - 1
.endm

;====
; Parse a register string into one of the register constants
;
; @in       string  the register string (i.e. "AF", "af", "HL'", "hl'")
; @out      registers._parse.returnValue defined with the register constant
; @fails    if the string cannot be parsed
;====
.macro "registers._parse" args string
    ; Resolve register string to a constant
    .if string == "AF" || string == "af"
        .redefine registers._parse.returnValue registers.AF
    .elif string == "BC" || string == "bc"
        .redefine registers._parse.returnValue registers.BC
    .elif string == "DE" || string == "de"
        .redefine registers._parse.returnValue registers.DE
    .elif string == "HL" || string == "hl"
        .redefine registers._parse.returnValue registers.HL
    .elif string == "IX" || string == "ix"
        .redefine registers._parse.returnValue registers.IX
    .elif string == "IY" || string == "iy"
        .redefine registers._parse.returnValue registers.IY
    .elif string == "I" || string == "i"
        .redefine registers._parse.returnValue registers.I
    .elif string == "ALL" || string == "all"
        .redefine registers._parse.returnValue registers.ALL
    .elif string == "AF'" || string == "af'"
        .redefine registers._parse.returnValue registers.SHADOW_AF
    .elif string == "BC'" || string == "bc'"
        .redefine registers._parse.returnValue registers.SHADOW_BC
    .elif string == "DE'" || string == "de'"
        .redefine registers._parse.returnValue registers.SHADOW_DE
    .elif string == "HL'" || string == "hl'"
        .redefine registers._parse.returnValue registers.SHADOW_HL
    .else
        .print "\.: Unknown register value: ", string, "\n"
        .fail
    .endif
.endm

;====
; Restores the registers that have been preserved by the current preserve scope
;====
.macro "registers._restoreRegisters"
    .redefine \.\@stackSize registers.stack{registers.preserveIndex}_size

    ; Pop each register from the stack
    .repeat (\.\@stackSize) index index
        ; Reverse order (start from top of stack)
        .redefine index (\.\@stackSize) - index - 1

        ; Pop register identifier from variable stack
        .redefine \.\@register registers.stack{registers.preserveIndex}_{index}
        .undefine registers.stack{registers.preserveIndex}_{index}

        ; If it's one of the shadow registers
        .if \.\@register & (registers.SHADOW_BC | registers.SHADOW_DE | registers.SHADOW_HL)
            ; Switch to shadow set if we haven't already
            .ifndef \.\@exxUsed
                exx
                .define \.\@exxUsed
            .endif
        .elif \.\@register & (registers.BC | registers.DE | registers.HL)
            ; Non shadow register - switch to main set if needed
            .ifdef \.\@exxUsed
                exx ; switch back to non-shadow registers
                .undefine \.\@exxUsed
            .endif
        .endif

        ; Pop relevant register from RAM stack
        .if \.\@register == registers.AF
            pop af
        .elif \.\@register == registers.BC
            pop bc
        .elif \.\@register == registers.DE
            pop de
        .elif \.\@register == registers.HL
            pop hl
        .elif \.\@register == registers.IX
            pop ix
        .elif \.\@register == registers.IY
            pop iy
        .elif \.\@register == registers.SHADOW_AF
            ex af, af'
                pop af'
            ex af, af'
        .elif \.\@register == registers.SHADOW_BC
            pop bc' ; switched to shadow set above
        .elif \.\@register == registers.SHADOW_DE
            pop de' ; switched to shadow set above
        .elif \.\@register == registers.SHADOW_HL
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
;                           "AF", "BC", "DE", "HL", "IX", "IY", "I" and "ALL",
;                           "af", "bc", "de", "hl", "ix", "iy", "i" and "all",
;                           "AF'", "BC'", "DE'", "HL'"
;                           "af'", "bc'", "de'", "hl'"
;                       Default = "ALL"
;====
.macro "registers.preserve"
    ; Create a new preserve scope
    registers._pushPreserveScope

    ; Add the given registers to the doNotClobber list
    .if nargs == 0
        ; If no args, preserve all the main registers by default
        registers._addDoNotClobber registers.ALL
    .else
        ; Combine (OR) all given args into doNotClobber value
        .repeat nargs
            ; Parse the register string into a constant
            registers._parse \1
            .redefine \.\@register registers._parse.returnValue

            ; Set given bit in doNotClobber
            registers._addDoNotClobber (\.\@register)
            .shift  ; shift args
        .endr
    .endif
.endm

;====
; Marks the end of a preserve scope
;====
.macro "registers.restore"
    ; Assert there are preserve scopes in progress
    .if registers.preserveIndex == -1
        .print "\.: was called but no preserve scopes are in progress\n"
        .fail
    .endif

    ; Check if we need to restore the I register
    .if (registers.I & (registers.unpreserved{registers.preserveIndex} ~ $ff)) > 0
        .if registers.iStackIndex == -1
            .print "\.: I stack popped but there's no value on it\n"
            .fail
        .endif

        ; This will clobber A - if it's needed it will be restored further below
        ld a, (registers.iStack.{registers.iStackIndex})
        ld i, a

        .redefine registers.iStackIndex registers.iStackIndex - 1
    .endif

    ; Restore the registers
    registers._restoreRegisters

    ; Remove the preserve scope
    registers._popPreserveScope
.endm

;====
; Preserves the given list of registers
;
; @in   registers   the list of register constants (i.e. register.AF) ORed
;                   together into one value
;====
.macro "registers._preserveRegisters" args registers
    .if registers & registers.AF
        push af
        registers._registerPushed registers.AF
    .endif

    .if registers & registers.BC
        push bc
        registers._registerPushed registers.BC
    .endif

    .if registers & registers.DE
        push de
        registers._registerPushed registers.DE
    .endif

    .if registers & registers.HL
        push hl
        registers._registerPushed registers.HL
    .endif

    .if registers & registers.IX
        push ix
        registers._registerPushed registers.IX
    .endif

    .if registers & registers.IY
        push iy
        registers._registerPushed registers.IY
    .endif

    .if registers & registers.I
        .redefine registers.iStackIndex registers.iStackIndex + 1

        .if registers.iStackIndex >= registers.I_STACK_MAX_SIZE
            .print "\.: The I stack has exceeded its max size. Consider "
            .print "increasing the registers.I_STACK_MAX_SIZE value\n"
            .fail
        .endif

        push af
            ld a, i
            ld (registers.iStack.{registers.iStackIndex}), a
        pop af

        registers._registerPushed registers.I
    .endif

    .if registers & registers.SHADOW_AF
        ex af, af'
            push af
            registers._registerPushed registers.SHADOW_AF
        ex af, af'
    .endif

    ; 16-bit shadow registers
    .if registers & (registers.SHADOW_BC|registers.SHADOW_DE|registers.SHADOW_HL)
        exx ; switch to shadow registers
            .if registers & registers.SHADOW_BC
                push bc
                registers._registerPushed registers.SHADOW_BC
            .endif

            .if registers & registers.SHADOW_DE
                push de
                registers._registerPushed registers.SHADOW_DE
            .endif

            .if registers & registers.SHADOW_HL
                push hl
                registers._registerPushed registers.SHADOW_HL
            .endif
        exx ; switch back to non-shadow registers
    .endif
.endm

;====
; Starts a clobber scope, in which the specific registers will be clobbered.
; If the current preserve scope needs these values to be preserved they will
; be pushed to the stack
;
; @in   ...registers    list of registers that will be clobbered
;                       Valid values:
;                           "AF", "BC", "DE", "HL", "IX", "IY", "I" and "ALL",
;                           "af", "bc", "de", "hl", "ix", "iy", "i" and "all",
;                           "AF'", "BC'", "DE'", "HL'"
;                           "af'", "bc'", "de'", "hl'"
;                       Default = "ALL"
;====
.macro "registers.clobbers"
    .if nargs == 0
        .print "\.: Expected at least 1 register to be passed\n"
        .fail
    .endif

    ; If auto preserve is enabled
    .if registers.AUTO_PRESERVE == 1
        ; If there are no clobber scopes or preserve scope in progress
        .if registers.clobberIndex == -1 && registers.preserveIndex == -1
            ; Preserve all registers including shadow registers
            registers.preserve "ALL" "AF'" "BC'" "DE'" "HL'"
            .redefine registers.autoPreserveIndex registers.preserveIndex
        .endif
    .endif

    ; Increment the clobber index
    .redefine registers.clobberIndex registers.clobberIndex + 1

    ; Combine (OR) all given registers into a single value
    .define \.\@_clobbing 0
    .repeat nargs
        ; Parse the register string into a constant
        registers._parse \1
        .redefine \.\@_clobbing (\.\@_clobbing | registers._parse.returnValue)
        .shift  ; shift args (\2 => \1)
    .endr

    ; If there are preserve scopes in progress
    .if registers.preserveIndex > -1
        ; Get list of registers that are being clobbered, that should be preserved,
        ; but haven't yet been
        .define \.\@_doNotClobber (registers.doNotClobber{registers.preserveIndex})
        .define \.\@_unpreserved (registers.unpreserved{registers.preserveIndex})
        .define \.\@_shouldPush (\.\@_clobbing & \.\@_doNotClobber & \.\@_unpreserved)

        ; Preserve these registers
        registers._preserveRegisters (\.\@_shouldPush)
    .endif
.endm

;====
; Marks the end of a clobber scope
;====
.macro "registers.clobberEnd"
    ; Assert there are clobber scopes in progress
    .if registers.clobberIndex == -1
        .print "\. was called but no clobber scopes are in progress\n"
        .fail
    .endif

    .redefine registers.clobberIndex registers.clobberIndex - 1

    ; If there are no more clobber scopes in progress
    .if registers.clobberIndex == -1
        ; If this is the auto preserve scope
        .if registers.preserveIndex > -1 && registers.preserveIndex == registers.autoPreserveIndex
            registers.restore
            .redefine registers.autoPreserveIndex -1
        .endif
    .endif
.endm
