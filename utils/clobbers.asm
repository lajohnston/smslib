;====
; This is a proxy utility to decouple the main modules from the registers.asm
; register.clobbers and register.clobbersEnd macros. If the registers.asm module
; isn't present a warning will be printed and the register preservation won't
; take effect
;====
.define util.clobbers

;====
; Settings
;====

;===
; If 1, a warning will be printed (once) if the registers.asm module isn't
; present. Set to 0 to disable the warning completely
; Default = 1
;===
.ifndef utils.clobbers.DISPLAY_WARNING
    .define utils.clobbers.DISPLAY_WARNING 1
.endif

;====
; Prints a warning if registers.asm hasn't been included yet
;====
.macro "utils.clobbers.printRegistersWarning"
    .if utils.clobbers.DISPLAY_WARNING == 1
        .print "Warning: registers.asm module not found - automatic register "
        .print "preservation will not take place\n"
        .redefine utils.clobbers.DISPLAY_WARNING 0  ; don't display again
    .endif
.endm

;====
; Calls registers.clobbers if it exists, otherwise prints a warning and does
; nothing
;
; @in   ...registers    register strings. See registers.asm for details
;====
.macro "utils.clobbers"
    .ifndef registers.ENABLED
        utils.clobbers.printRegistersWarning
    .else
        .if nargs == 1
            registers.clobbers \1
        .elif nargs == 2
            registers.clobbers \1 \2
        .elif nargs == 3
            registers.clobbers \1 \2 \3
        .elif nargs == 4
            registers.clobbers \1 \2 \3 \4
        .elif nargs == 5
            registers.clobbers \1 \2 \3 \4 \5
        .elif nargs == 6
            registers.clobbers \1 \2 \3 \4 \5 \6
        .elif nargs == 7
            registers.clobbers \1 \2 \3 \4 \5 \6 \7
        .elif nargs == 8
            registers.clobbers \1 \2 \3 \4 \5 \6 \7 \8
        .else
            .print "\.: Doesn't currently support ", nargs, " arguments\n"
            .fail
        .endif
    .endif
.endm

;====
; Calls registers.clobberEnd if it exists, otherwise prints a warning and does
; nothing
;====
.macro "utils.clobbers.end"
    .ifndef registers.ENABLED
        utils.clobbers.printRegistersWarning
    .else
        registers.clobberEnd
    .endif
.endm