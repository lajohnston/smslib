;====
; Tilemap
;
; Each tile in the tilemap consists of 2-bytes which describe which pattern to
; use and which modifier attributes to apply to it, such as flipping, layer and
; color palette
;====
.define tilemap.ENABLED 1

;====
; Settings
;
; Define these before including this file if you wish to override the defaults
;====

; The tilemap address in VRAM (default $3800)
.ifndef tilemap.VRAM_ADDRESS
    .define tilemap.VRAM_ADDRESS $3800
.endif

;====
; Dependencies
;====
.ifndef utils.assert
    .include "utils/assert.asm"
.endif

.ifndef utils.clobbers
    .include "utils/clobbers.asm"
.endif

.ifndef utils.math
    .include "utils/math.asm"
.endif

.ifndef utils.ram
    .include "utils/ram.asm"
    utils.ram.assertRamSlot
.endif

.ifndef utils.registers
    .include "utils/registers.asm"
.endif

.ifndef utils.vdpCommand
    .include "utils/vdpCommand.asm"
.endif

.ifndef utils.vram
    .include "utils/vram.asm"
.endif

;====
; Tile attributes
; Combine using OR (|), i.e. (tilemap.HIGH_BIT | tilemap.FLIP_X)
;====
.define tilemap.HIGH_BIT        %00000001   ; 9th bit for the pattern ref, allows refs 256+
.define tilemap.FLIP_X          %00000010   ; Flip horizontally
.define tilemap.FLIP_Y          %00000100   ; Flip vertically
.define tilemap.FLIP_XY         %00000110   ; Flip horizontally and vertically
.define tilemap.SPRITE_PALETTE  %00001000   ; Use palette 2 (sprite palette)

; Place in front of sprites. Color 0 acts as transparent
.define tilemap.PRIORITY        %00010000

; Spare bits - unused by VDP but some games use them to hold custom attributes
; such as whether the tile is a hazard that costs the player health
.define tilemap.CUSTOM_1        %00100000
.define tilemap.CUSTOM_2        %01000000
.define tilemap.CUSTOM_3        %10000000

;====
; Constants
;====
.define tilemap.ROWS 28
.define tilemap.COLS 32
.define tilemap.TILES tilemap.ROWS * tilemap.COLS
.define tilemap.MAX_PATTERN_INDEX 511

.define tilemap.SCROLL_X_REGISTER 8
.define tilemap.SCROLL_Y_REGISTER 9

; Min and max number of rows visible on screen. If the Y scroll offset is a
; multiple of 8 it's the minimum, otherwise there is an extra row (the bottom
; of the top row is still visible, as well as the top of the bottom row)
.define tilemap.MIN_VISIBLE_ROWS 24
.define tilemap.MAX_VISIBLE_ROWS tilemap.MIN_VISIBLE_ROWS + 1
.define tilemap.Y_PIXELS tilemap.ROWS * 8

; Number of pixels the X scroll is shifted by on initialisation. -8 means
; column 0 is visible on screen and populated by the left-most column, while
; column 31 is hidden and populated by the next column on the right
.define tilemap.X_OFFSET -8

.define tilemap.TILE_SIZE_BYTES 2
.define tilemap.COL_SIZE_BYTES tilemap.MAX_VISIBLE_ROWS * tilemap.TILE_SIZE_BYTES
.define tilemap.ROW_SIZE_BYTES tilemap.COLS * 2

; Masks to set/reset the Y scroll flags (00 = no scroll, 01 = up, 11 = down)
.define tilemap.SCROLL_Y_RESET_MASK     %11111100   ; AND mask
.define tilemap.SCROLL_UP_SET_MASK      %00000001   ; OR mask
.define tilemap.SCROLL_DOWN_SET_MASK    %00000011   ; OR mask

; Masks to set/reset the X scroll flags (00 = no scroll, 10 = right, 11 = left)
.define tilemap.SCROLL_X_RESET_MASK     %00111111   ; AND mask
.define tilemap.SCROLL_LEFT_SET_MASK    %11000000   ; OR mask
.define tilemap.SCROLL_RIGHT_SET_MASK   %10000000   ; OR mask

;====
; RAM
;====
.ramsection "tilemap.ram" slot utils.ram.SLOT
    ; VDP x-axis scroll register buffer
    tilemap.ram.xScrollBuffer:  db  ; negate before writing to the VDP

    ; Scroll flags
    tilemap.ram.flags:          db  ; see constants for flag definitions

    ; VDP y-axis scroll register buffer
    tilemap.ram.yScrollBuffer:  db

    ; VRAM write command/address for row scrolling
    tilemap.ram.vramRowWrite:   dw

    ; Address to call when writing the scrolling column
    tilemap.ram.colWriteCall:   dw
.ends

; Buffer of raw column tiles
.ramsection "tilemap.ram.colBuffer" slot utils.ram.SLOT
    tilemap.ram.colBuffer:      dsb tilemap.COL_SIZE_BYTES
.ends

;===
; Buffer of raw row tiles
; Align to 256 so low byte starts at 0 and can be set to the offset
;===
.ramsection "tilemap.ram.rowBuffer" slot utils.ram.SLOT align 256
    tilemap.ram.rowBuffer:      dsb tilemap.ROW_SIZE_BYTES
.ends

;====
; Submodules
;====
.include "tilemap/reset.asm"

.include "tilemap/ifColScroll.asm"
.include "tilemap/ifColScrollElseRet.asm"
.include "tilemap/ifRowScroll.asm"
.include "tilemap/ifRowScrollElseRet.asm"

.include "tilemap/adjustXPixels.asm"
.include "tilemap/adjustYPixels.asm"
.include "tilemap/calculateScroll.asm"
.include "tilemap/writeScrollBuffers.asm"

.include "tilemap/stopUpScroll.asm"
.include "tilemap/stopDownScroll.asm"
.include "tilemap/stopLeftScroll.asm"
.include "tilemap/stopRightScroll.asm"

.include "tilemap/writeBytes.asm"
.include "tilemap/writeBytesUntil.asm"
.include "tilemap/writeRow.asm"
.include "tilemap/writeRows.asm"

;====
; Set the tile index ready to write to
;
; @in   index   0 is top left tile
;====
.macro "tilemap.setIndex" args index
    utils.assert.range index 0, 895, "\.: Index should be between 0 and 895"

    utils.vdpCommand.setVramWriteAddress (tilemap.VRAM_ADDRESS + (index * tilemap.TILE_SIZE_BYTES))
    ld c, utils.vdpCommand.DATA_PORT
.endm

;====
; Set the tile index ready to write to
;
; @in   col     column number (x)
; @in   row     row number (y)
;====
.macro "tilemap.setColRow" args colX rowY
    utils.assert.range colX, 0, 31, "\.: colX should be between 0 and 31"
    utils.assert.range rowY, 0, 27, "\.: rowY should be between 0 and 27"

    tilemap.setIndex ((rowY * tilemap.COLS) + colX)
.endm

;====
; Set HL to the write address for the given row and column
;
; @in   hl  row * 32 + column (i.e. ------yy yyyxxxxx)
;
; @out  hl  the VRAM address with write command set
; @out  c   the port to output data to (using out, outi etc)
;====
.macro "tilemap.loadHLWriteAddress"
    utils.clobbers "af"
        ; Multiply by 2 (2 bytes per tile)
        add hl, hl

        ; Low byte of base address is 0, so we just need to manipulate high byte
        ; Set A to high byte of base address with the write command set
        ld a, >tilemap.VRAM_ADDRESS | utils.vdpCommand.WRITE_VRAM
        or h        ; combine bits with high byte of relative address
        ld h, a     ; set HL to the full address
    utils.clobbers.end
.endm

;====
; Define tile data
;
; @in   patternIndex    the pattern index (0-511)
; @in   attributes      (optional) the tile attributes (see Tile attributes section).
;                       Note, if patternRef is greater than 255, tilemap.HIGH_BIT
;                       is set automatically
;====
.macro "tilemap.tile" args patternIndex attributes
    utils.assert.range NARGS, 1, 2, "\.: Invalid number of arguments"
    utils.assert.range patternIndex, 0, tilemap.MAX_PATTERN_INDEX, "tilemap.asm \.: Invalid patternIndex argument"

    .ifndef attributes
        .define attributes $00
    .endif

    ; Set high bit attribute if pattern index is above 255
    .ifgr patternIndex 255
        .redefine attributes attributes | tilemap.HIGH_BIT
    .endif

    .db <(patternIndex) ; low byte of patternIndex
    .db attributes
.endm

;====
; Write a tile to the current position in the tilemap
;
; @in   patternIndex    the pattern index (0-511)
; @in   attributes      (optional) the tile attributes (see Tile attributes section).
;                       Note, if patternRef is greater than 255, tilemap.HIGH_BIT
;                       is set automatically
;
; @in   c               VDP data port
;====
.macro "tilemap.writeTile" args patternIndex attributes
    utils.assert.range patternIndex, 0, tilemap.MAX_PATTERN_INDEX, "\.: Invalid patternIndex argument"

    .ifndef attributes
        .define attributes $00
    .else
        utils.assert.range attributes, 0, 255, "\.: Invalid attributes argument"
    .endif

    ; Set high bit attribute if pattern index is above 255
    .ifgr patternIndex 255
        .redefine attributes attributes | tilemap.HIGH_BIT
    .endif

    utils.clobbers "af"
        ; Load A with low-byte of pattern index
        utils.registers.loadA <patternIndex

        out (utils.vdpCommand.DATA_PORT), a    ; write pattern index

        ; Load A with attribute byte (skip if value happens to be the same
        ; as patternIndex)
        .if attributes != <patternIndex
            utils.registers.loadA attributes
        .endif

        out (utils.vdpCommand.DATA_PORT), a    ; write tile attributes
    utils.clobbers.end
.endm

;====
; Outputs the given number of tiles to the current position in the tilemap
;
; @in   hl      pointer to the tile data
; @in   number  the number of tiles to write
; @in   VRAM    pointer to destination address with write command
;====
.macro "tilemap.writeTiles" args number
    utils.assert.range number, 1, tilemap.TILES, "\.: Invalid number argument"

    utils.vram.writeBytes tilemap.TILE_SIZE_BYTES * number
.endm

;====
; Load DE with a pointer to the column buffer
;
; @out  de  pointer to the column buffer
;====
.macro "tilemap.loadDEColBuffer"
    ld de, tilemap.ram.colBuffer
.endm

;====
; Load B with the number of bytes to write for the scrolling column
;
; @out  b   the number of bytes to write
;====
.macro "tilemap.loadBColBytes"
    ld b, tilemap.COL_SIZE_BYTES    ; number of bytes to write
.endm

;====
; Load BC with the number of bytes to write for the scrolling column. Note,
; this will always be a value <= 50 so only needs 8-bits, but this macro is
; provided for convenience for routines that use ldi and require a 16-bit
; counter in BC
;
; @out  bc  the number of bytes to write
;====
.macro "tilemap.loadBCColBytes"
    ld bc, tilemap.COL_SIZE_BYTES   ; number of bytes to write
.endm

;====
; Load DE with a pointer to the row buffer
;
; @out  de  pointer to the row buffer
;====
.macro "tilemap.loadDERowBuffer"
    ld de, tilemap.ram.rowBuffer
.endm

;====
; Load B with the number of bytes to write for the scrolling row
;
; @out  b   the number of bytes to write
;====
.macro "tilemap.loadBRowBytes"
    ld b, tilemap.ROW_SIZE_BYTES
.endm

;====
; Load BC with the number of bytes to write for the scrolling row. Note,
; this will always be a value <= 50 so only needs 8-bits, but this macro is
; provided for convenience for routines that use ldi and require a 16-bit
; counter in BC
;
; @out  bc  the number of bytes to write
;====
.macro "tilemap.loadBCRowBytes"
    ld bc, tilemap.ROW_SIZE_BYTES
.endm
