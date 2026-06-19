;====
; Utils for writing data to VRAM
;====

.define utils.vram 1

;====
; Constants
;====
.define utils.vram.DATA_PORT $be

;====
; Dependencies
;====
.ifndef utils.registers
    .include "utils/registers.asm"
.endif

;====
; Writes a byte to the data port and increments the write address
;
; @in   value   the value to write
; @in   VRAM    pointer to address (with write command set)
; @out  VRAM    pointer to given address + 1
;====
.macro "utils.vram.writeByte" args value
    .ifndef value
        out (utils.vram.DATA_PORT), a
    .else
        utils.assert.range value, 0, 255, "\.: Value out of byte range"

        utils.clobbers "af"
            utils.registers.loadA value

            ; Output and increment VRAM address
            out (utils.vram.DATA_PORT), a
        utils.clobbers.end
    .endif
.endm
