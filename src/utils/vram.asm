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

;====
; Zeroes the VRAM
;
; @in   vram    address and command set
; @in   bc      number of bytes to clear
;====
.section "utils.vram._writeZeroes" free
    utils.vram._writeZeroes:
        -:
            xor a
            out (utils.vram.DATA_PORT), a   ; output + increment VRAM address
            dec bc
            ld a, b
            or c
        jp nz, -
    ret
.ends

;====
; Zeroes the VRAM from the current write address for a given number of bytes
;
; @in   bytes       number of bytes to clear/set to zero (defaults to $4000 - all VRAM)
;====
.macro "utils.vram.writeZeroes" args bytes
    ; Default bytes parameter
    .ifndef bytes
        .define bytes $4000
    .else
        utils.assert.range bytes 0, $4000, "\.: bytes out of VRAM range"
    .endif

    utils.clobbers "bc"
        ld bc, bytes
        call utils.vram._writeZeroes
    utils.clobbers.end
.endm