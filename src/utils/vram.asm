;====
; Utils for writing data to VRAM
;====

.define utils.vram 1

;====
; Constants
;====
.define utils.vram.DATA_PORT $be

;====
; Variables
;====

; When 1, indicates active display is on and VRAM writes need to be rate limited
; Subsequent calls to utils.vram macros will respect this value
.define utils.vram.ACTIVE_DISPLAY 0

; Overrides the utils.vram.ACTIVE_DISPLAY value for the next call to a
; utils.vram macro, after which the macros will return to respecting the
; utils.vram.ACTIVE_DISPLAY value
; .define utils.vram.ACTIVE_DISPLAY_NEXT

;====
; Dependencies
;====
.ifndef utils.assert
    .include "utils/assert.asm"
.endif

.ifndef utils.outiBlock
    .include "utils/outiBlock.asm"
.endif

.ifndef utils.registers
    .include "utils/registers.asm"
.endif

;====
; Sets a utils.vram.isActiveDisplay.returnValue variable to 1 if
; utils.vram.ACTIVE_DISPLAY or utils.vram.ACTIVE_DISPLAY_NEXT is set.
; If utils.vram.ACTIVE_DISPLAY_NEXT is set it will be reset to 0
;====
.macro "utils.vram.isActiveDisplay"
    utils.assert.oneOf utils.vram.ACTIVE_DISPLAY 0 1 "\.: utils.vram.ACTIVE_DISPLAY must be 0 or 1"

    .ifdef utils.vram.ACTIVE_DISPLAY_NEXT
        utils.assert.oneOf utils.vram.ACTIVE_DISPLAY_NEXT, 0, 1 "\.: utils.vram.ACTIVE_DISPLAY_NEXT must be 0 or 1"
    .endif

    .ifdef utils.vram.ACTIVE_DISPLAY_NEXT
        ; If override given, return that value then reset it
        .redefine \..returnValue utils.vram.ACTIVE_DISPLAY_NEXT
        .undefine utils.vram.ACTIVE_DISPLAY_NEXT
    .elif utils.vram.ACTIVE_DISPLAY == 1
        .redefine \..returnValue 1
    .else
        .redefine \..returnValue 0
    .endif
.endm

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
; Writes one or more blocks of 256-bytes to VRAM, staying within active display
; speed limits
;
; @in   a       the number of 256-byte blocks to write (should be 1-64)
; @in   c       the data port to write to (usually utils.vram.DATA_PORT)
; @in   hl      source data address
; @in   VRAM    address and write command set
;====
.section "utils.vram._write256ByteBlocksActiveDisplay" free
    utils.vram._write256ByteBlocksActiveDisplay:
        ; Write 256 bytes
        ld b, 0     ; will wrap to 255 when decremented after first byte
        -:
            outi    ; 16 cycles
        jp nz, -    ; +10 (26 cycles)

        ; Dec 256 block counter
        dec a
        jp nz, -    ; continue if more blocks to write; B will be 0
        ret
.ends

;====
; Writes bytes to VRAM, delaying by at least 26 cycles between each to stay
; within active display speed limits
;
; @in   c       the data port to write to (usually utils.vram.DATA_PORT)
; @in   hl      source data address
; @in   VRAM    address and write command set
; @in   bytes|b number of bytes to write. If using B, 0 = 256
;
; @out  VRAM    start address + bytes
;====
.macro "utils.vram.writeBytesActiveDisplay" isolated args bytes
    .ifndef bytes
        ; Bytes arguement not given, so use B register
        utils.clobbers "af" "bc" "hl"
            ; Output B number of bytes (0 = 256)
            -:
                outi    ; 16 cycles
            jp nz, -    ; +10 (26 cycles)
        utils.clobbers.end
    .else
        utils.assert.range bytes 1 16384 "\.: Invalid bytes argument"

        utils.clobbers "af" "bc" "hl"
            .if bytes >= 256
                ld a, (bytes / 256) + 1; 256-byte blocks = floor(bytes/256) + 1
                call utils.vram._write256ByteBlocksActiveDisplay
            .endif

            ; Write remaining bytes (if any)
            .if (bytes # 256) > 0
                -:
                    outi    ; 16 cycles
                jp nz, -    ; +10 (26 cycles)
            .endif
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
    utils.vram.isActiveDisplay

    .if utils.vram.isActiveDisplay.returnValue == 1
        utils.vram.writeBytesActiveDisplay bytes
    .else
        utils.outiBlock.write bytes
    .endif
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
    utils.vram.isActiveDisplay

    .if utils.vram.isActiveDisplay.returnValue == 1
        utils.vram.writeBytesActiveDisplay
    .else
        utils.outiBlock.writeUpTo128Bytes
    .endif
.endm

;====
; Write a variable number of bytes between 1-128 bytes (inclusive) then
; returns
;
; @in   b       the number of bytes to write. Must be > 0 and <= 128
; @in   c       the port to output the data to
; @in   hl      the address of the source data
; @in   vram    the VRAM address to write to, with write command set
; @out  vram    the VRAM address after writing the bytes
;====
.macro "utils.vram.writeUpTo128BytesThenReturn"
    utils.vram.isActiveDisplay

    .if utils.vram.isActiveDisplay.returnValue == 1
        utils.vram.writeBytesActiveDisplay
        ret
    .else
        utils.outiBlock.writeUpTo128BytesThenReturn
    .endif
.endm

;====
; Writes elements from an array of data to VRAM
;
; @in   c           the output port
; @in   dataAddress the address of the data to transfer
; @in   elementSize the size of each array element in bytes
; @in   count       the number of elements to transfer (1-based)
; @in   offset      the first item in the array to copy (0-based)
;====
.macro "utils.vram.writeSlice" args dataAddress elementSize count offset
    utils.vram.isActiveDisplay

    .if utils.vram.isActiveDisplay.returnValue == 1
        utils.clobbers "hl"
            ld hl, dataAddress + (offset * elementSize)
            utils.vram.writeBytesActiveDisplay (count * elementSize)
        utils.clobbers.end
    .else
        utils.outiBlock.writeSlice dataAddress, elementSize, count, offset
    .endif
.endm

;====
; Zeroes the VRAM. Safe to call during active display
;
; @in   vram    address and command set
; @in   bc      number of bytes to clear
;====
.section "utils.vram._writeZeroes" free
    utils.vram._writeZeroes:
        -:
            xor a       ; + 4 (27/28 cycles)
            out (utils.vram.DATA_PORT), a   ; output + increment VRAM address
            dec bc      ; + 6 ( 6 cycles)
            ld a, b     ; + 4 (10 cycles)
            or c        ; + 4 (14 cycles)
        jp nz, -        ; +10 (24 cycles)
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

    ; Consume ACTIVE_DISPLAY_NEXT if set, but return value not needed
    utils.vram.isActiveDisplay

    utils.clobbers "bc"
        ld bc, bytes
        call utils.vram._writeZeroes
    utils.clobbers.end
.endm
