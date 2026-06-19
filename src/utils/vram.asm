;====
; Utils for writing data to VRAM
;====

.define utils.vram 1

;====
; Constants
;====
.define utils.vram.COMMAND_PORT $bf
.define utils.vram.DATA_PORT $be
.define utils.vram.WRITE_VRAM_COMMAND%01000000   ; OR mask

;====
; Dependencies
;====
.ifndef utils.registers
    .include "utils/registers.asm"
.endif

;====
; Prepares the VDP to write to the given VRAM write address
;
; @in   address     the VRAM write address
; @in   [setPort]   if 1 (the default) then the C register will be loaded with
;                   the VDP data port. Set to 0 if the port is already set to
;                   saves 7 cycles
; @out  c           data port, ready to output data to with out, outi etc.
;====
.macro "utils.vram.setWriteAddress" args address setPort
    ; Assert address is in VRAM range
    utils.assert.range address 0 $3fff "\.: Address should be a valid VRAM address"

    ; Default setPort to 1
    .ifndef setPort
        .redefine setPort 1
    .endif

    utils.clobbers "af"
        ; Output low byte to VDP
        utils.registers.loadA <address
        out (utils.vram.COMMAND_PORT), a

        ; Output high byte to VDP with write command set
        ld a, >address | utils.vram.WRITE_VRAM_COMMAND
        out (utils.vram.COMMAND_PORT), a

        .if setPort == 1
            ; Port to write to
            ld c, utils.vram.DATA_PORT
        .endif
    utils.clobbers.end
.endm

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