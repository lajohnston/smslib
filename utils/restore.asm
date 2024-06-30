;====
; Alias for utils.registers.restore
;====

.define utils.restore

;====
; Dependencies
;====
.ifndef utils.registers.ENABLED
    .include "utils/registers.asm"
.endif

;====
; Alias for utils.registers.restore
;====
.macro "utils.restore"
    utils.registers.restore
.endm
