.define utils.restore

;====
; Dependencies
;====
.ifndef utils.registers.ENABLED
    .include "utils/registers.asm"
.endif

;====
; Proxy for utils.registers.restore
;====
.macro "utils.restore"
    utils.registers.restore
.endm
