.define utils.clobbers

;====
; Dependencies
;====
.ifndef utils.registers.ENABLED
    .include "utils/registers.asm"
.endif

;====
; Settings
;====

;====
; Calls utils.registers.clobbers if it exists, otherwise prints a warning and does
; nothing
;
; @in   ...registers    register strings. See registers.asm for details
;====
.macro "utils.clobbers"
    .if nargs == 1
        utils.registers.clobbers \1
    .elif nargs == 2
        utils.registers.clobbers \1 \2
    .elif nargs == 3
        utils.registers.clobbers \1 \2 \3
    .elif nargs == 4
        utils.registers.clobbers \1 \2 \3 \4
    .elif nargs == 5
        utils.registers.clobbers \1 \2 \3 \4 \5
    .elif nargs == 6
        utils.registers.clobbers \1 \2 \3 \4 \5 \6
    .elif nargs == 7
        utils.registers.clobbers \1 \2 \3 \4 \5 \6 \7
    .elif nargs == 8
        utils.registers.clobbers \1 \2 \3 \4 \5 \6 \7 \8
    .else
        .print "\.: Doesn't currently support ", nargs, " arguments\n"
        .fail
    .endif
.endm

;====
; Calls registers.clobberEnd if it exists, otherwise prints a warning and does
; nothing
;====
.macro "utils.clobbers.end"
    utils.registers.clobberEnd
.endm
