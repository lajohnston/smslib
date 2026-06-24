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
; (Private) Sets a utils.vram._isActiveDisplay.returnValue variable to 1 if
; utils.vram.ACTIVE_DISPLAY or utils.vram.ACTIVE_DISPLAY_NEXT is set.
; If utils.vram.ACTIVE_DISPLAY_NEXT is set it will be reset to 0
;====
.macro "utils.vram._isActiveDisplay"
    utils.assert.oneOf utils.vram.ACTIVE_DISPLAY 0 1 "\.: utils.vram.ACTIVE_DISPLAY must be 0 or 1"

    .ifdef utils.vram.ACTIVE_DISPLAY_NEXT
        utils.assert.oneOf utils.vram.ACTIVE_DISPLAY_NEXT, 0, 1 "\.: utils.vram.ACTIVE_DISPLAY_NEXT must be -1 (off), 0 or 1"
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
; (Private) Writes bytes to VRAM, delaying by at least 26 cycles between each
; to stay within active display constraints.
;
; 26 works for all known Master Systems. 27 might be needed for Game Gear support
;====
.section "utils.vram._writeBytesActiveDisplay" free
    utils.vram._write256BytesActiveDisplay:
        ; Call was at least 17 cycles (more with push bc)
        ld b, 0         ; +7 (24 cycles)

    utils.vram._writeBytesActiveDisplay:
        ; Delay by at least 26 cycles between writes
        ; ld b + call took at least 24 cycles (more with push bc)
        -:
            nop         ; + 4 cycles (=28 cycles for first byte, =26 for subsequent)
            outi        ; output byte; inc hl; dec b

            ; Delay by at least 26 cycles before next write
            ret z       ; ret if b == 0 (=5 cycles if not returning)
            jr z, -     ; + 7 (=12 cycles) - never jumps
        jp -            ; + 10 (=22 cycles)
.ends

;====
; Writes bytes to VRAM, delaying by at least 26 cycles between each to stay
; within active display speed limits
;
; @in   bytes   number of bytes to write
; @in   c       the data port to write to (usually utils.vram.DATA_PORT)
; @in   hl      source data address
; @in   VRAM    address and write command set
;
; @out  VRAM    start address + bytes
; @out  hl      source data address + number of bytes written
;====
.macro "utils.vram.writeBytesActiveDisplay" isolated args bytes
    utils.assert.range bytes 1 16384 "\.: Invalid bytes argument"

    utils.clobbers "af" "bc" "hl"
        ; 256-byte chunks
        .rept bytes / 256
            call utils.vram._write256BytesActiveDisplay
        .endr

        ; Remaining bytes (if any)
        .if (bytes # 256) > 0
            ld b, bytes # 256 ; modulo
            call utils.vram._writeBytesActiveDisplay
        .endif
    utils.clobbers.end
.endm

;====
; Writes a fixed number of bytes to VRAM
;
; @in   bytes   the number of bytes to write
; @in   c       the output port
; @in   hl      the source data address
;====
.macro "utils.vram.writeBytes" args bytes
    utils.vram._isActiveDisplay

    .if utils.vram._isActiveDisplay.returnValue == 1
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
    utils.vram._isActiveDisplay

    .if utils.vram._isActiveDisplay.returnValue == 1
        call utils.vram._writeBytesActiveDisplay
    .else
        utils.outiBlock.writeUpTo128Bytes
    .endif
.endm

;====
; Like utils.vram.writeUpTo128Bytes but 'jp's to the routine, which will
; return to the original caller
;====
.macro "utils.vram.writeUpTo128BytesThenReturn"
    utils.vram._isActiveDisplay

    .if utils.vram._isActiveDisplay.returnValue == 1
        jp utils.vram._writeBytesActiveDisplay
    .else
        utils.outiBlock.writeUpTo128Bytes
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
    utils.vram._isActiveDisplay

    .if utils.vram._isActiveDisplay.returnValue == 1
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
    utils.vram._isActiveDisplay

    utils.clobbers "bc"
        ld bc, bytes
        call utils.vram._writeZeroes
    utils.clobbers.end
.endm
