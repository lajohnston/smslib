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
.ifndef utils.outiBlock
    .include "utils/outiBlock.asm"
.endif

.ifndef utils.registers
    .include "utils/registers.asm"
.endif

;====
; Writes a byte to the data port and increments the write address
;
; @in   value|a the value to write. If not set, outputs value in A
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
; Writes a fixed number of bytes to VRAM
;
; @in   bytes   the number of bytes to write
; @in   c       the output port
; @in   hl      the source data address
;====
.macro "utils.vram.writeBytes" args bytes
    utils.assert.range bytes 1 16384 "\.: Invalid bytes argument"
    utils.outiBlock.write bytes
.endm

;====
; Write a variable number of bytes between 1-128 bytes (inclusive)
;
; @in   b       the number of bytes to write. Must be > 0 and <= 128
; @in   c       the port to output the data to
; @in   hl      the address of the source data
; @in   vram    the VRAM address to write to, with write command set
; @out  vram    the VRAM address after writing the bytes
;====
.macro "utils.vram.writeUpTo128Bytes"
    utils.outiBlock.writeUpTo128Bytes
.endm

;====
; Like utils.vram.writeUpTo128Bytes but 'jp's to the routine, which will
; return to the original caller
;====
.macro "utils.vram.writeUpTo128BytesThenReturn"
    utils.outiBlock.writeUpTo128BytesThenReturn
.endm

;====
; Writes elements from an array of data to VRAM
;
; @in   dataAddress the address of the data to transfer
; @in   elementSize the size of each array element in bytes
; @in   count       the number of elements to transfer (1-based)
; @in   offset      the first item in the array to copy (0-based)
;====
.macro "utils.vram.writeSlice" args dataAddress elementSize count offset
    utils.outiBlock.writeSlice dataAddress, elementSize, count, offset
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