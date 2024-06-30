;====
; Alias for utils.registers.preserve
;====

.define utils.preserve

;====
; Dependencies
;====
.ifndef utils.registers.ENABLED
    .include "utils/registers.asm"
.endif

;====
; Alias for utils.registers.preserve
;====
.macro "utils.preserve"
    .if nargs == 0
        utils.registers.preserve
    .elif nargs == 1
        utils.registers.preserve \1
    .elif nargs == 2
        utils.registers.preserve \1 \2
    .elif nargs == 3
        utils.registers.preserve \1 \2 \3
    .elif nargs == 4
        utils.registers.preserve \1 \2 \3 \4
    .elif nargs == 5
        utils.registers.preserve \1 \2 \3 \4 \5
    .elif nargs == 6
        utils.registers.preserve \1 \2 \3 \4 \5 \6
    .elif nargs == 7
        utils.registers.preserve \1 \2 \3 \4 \5 \6 \7
    .elif nargs == 8
        utils.registers.preserve \1 \2 \3 \4 \5 \6 \7 \8
    .elif nargs == 9
        utils.registers.preserve \1 \2 \3 \4 \5 \6 \7 \8 \9
    .elif nargs == 10
        utils.registers.preserve \1 \2 \3 \4 \5 \6 \7 \8 \9 \10
    .elif nargs == 11
        utils.registers.preserve \1 \2 \3 \4 \5 \6 \7 \8 \9 \10 \11
    .else
        .print "\.: Too many arguments passed\n"
        .fail
    .endif
.endm

;====
; Closes a preserve scope without producing the restore instructions. Sometimes
; needed by branching clobber scopes which restore the registers separately
;====
.macro "utils.preserve.close"
    utils.registers.closePreserveScope
.endm