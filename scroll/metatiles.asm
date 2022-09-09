;====
; Builds on the API provided by tilemap.asm to provide a scrollable map of
; metatiles. Metatiles save considerable memory and thus allow large maps to be
; decompressed to RAM.
;
; Each ref in the tilemap is 1-byte and refers to one of 256 metatileDefs.
; Each metatileDef contains multiple subtiles, each 2-bytes. A 2x2 metatile
; containing 4 subtiles (8-bytes) is therefore reduced in bytes by 8x. Larger
; metatiles save more memory at the cost of potential variety of graphics.
;====

;====
; Dependencies
;====
.ifndef tilemap.ENABLED
    .print "\nscroll/metatiles.asm requires tilemap.asm to have been .included first\n\n"
    .fail
.endif

.ifndef utils.math
    .include "utils/math.asm"
.endif

.ifndef utils.ram
    .include "utils/ram.asm"
.endif

;===
; Settings
;===

; The number of tile columns (width) in each metatile
; Value should be 2, 4, 8 or 16. Defaults to 2
.ifndef scroll.metatiles.COLS_PER_METATILE
    .define scroll.metatiles.COLS_PER_METATILE 2
.endif

; The number of tile rows (height) in each metatile
; Value should be 2, 4, 8 or 16. Defaults to 2
.ifndef scroll.metatiles.ROWS_PER_METATILE
    .define scroll.metatiles.ROWS_PER_METATILE 2
.endif

; The maximum bytes a map can utilise in RAM. Divide by a map's width in
; metatiles to determine its maximum height
; (i.e. 4096 bytes / 256 width = 16 metatile max height). Defaults to 4096.
.ifndef scroll.metatiles.MAX_MAP_BYTES
    .define scroll.metatiles.MAX_MAP_BYTES 4096
.endif

;====
; Validate settings
;====

; Ensure scroll.metatiles.COLS_PER_METATILE is 2, 4, 8 or 16
.if scroll.metatiles.COLS_PER_METATILE != 2
    .if scroll.metatiles.COLS_PER_METATILE != 4
        .if scroll.metatiles.COLS_PER_METATILE != 8
            .if scroll.metatiles.COLS_PER_METATILE != 16
                .print "\nscroll.metatiles.COLS_PER_METATILE should be set to 2, 4, 8 or 16\n\n"
                .fail
            .endif
        .endif
    .endif
.endif

; Ensure scroll.metatiles.ROWS_PER_METATILE is 2, 4, 8 or 16
.if scroll.metatiles.ROWS_PER_METATILE != 2
    .if scroll.metatiles.ROWS_PER_METATILE != 4
        .if scroll.metatiles.ROWS_PER_METATILE != 8
            .if scroll.metatiles.ROWS_PER_METATILE != 16
                .print "\nscroll.metatiles.ROWS_PER_METATILE should be set to 2, 4, 8 or 16\n\n"
                .fail
            .endif
        .endif
    .endif
.endif

;====
; Constants
;====

; Number of subtiles in every metatile
.define scroll.metatiles.TILE_COUNT scroll.metatiles.COLS_PER_METATILE * scroll.metatiles.ROWS_PER_METATILE

;====
; Structs
;====

;====
; A pointer to an individual tile
;====
.struct "scroll.metatiles.TilePointer"
    metatileAddress:    dw  ; address of the metatileRef in RAM

    colsRemaining:      db  ; when drawing from left to right, the number of
                            ; sub columns remaining in the current metatile
    rowsRemaining:      db  ; when drawing from top to bottom, the number of
                            ; sub rows remaining in the current metatile
.endst

;====
; RAM
;====
.ramsection "scroll.metatiles.ram" slot utils.ram.SLOT
    ; Pointer to the top left tile of the on screen map
    scroll.metatiles.ram.topLeftTile:   instanceof scroll.metatiles.TilePointer

    ; Col and row counters, to help with bounds checking
    scroll.metatiles.ram.topRow:    db  ; TODO - 1-based?; 0 means out of bounds
    scroll.metatiles.ram.leftCol:   db  ; TODO - 1-based?; 0 means out of bounds

    ; Pointer to the metatile definitions
    scroll.metatiles.ram.defsAddress: dw

    ; How many metatile columns there are in the map (0-based; 0=1, 255=256)
    scroll.metatiles.ram.metatileColumns: db

    ; Number of times to left shift a row number to point to its first column
    ; Should be set to one of the scroll.metatiles.WIDTH_x constants
    scroll.metatiles.ram.rowLeftShift: db

    ; Grid of 1-byte metatile refs
    scroll.metatiles.ram.map: dsb scroll.metatiles.MAX_MAP_BYTES
.ends

;====
; Set DE to the map pointer (ready to write the data to)
;
; @out de   pointer to the map data
;====
.macro "scroll.metatiles.loadDEMap"
    ld de, scroll.metatiles.ram.map
.endm

;====
; Set the location of the metatile definitions
;
; @in hl    address of the metatile definitions
;====
.macro "scroll.metatiles.setDefs"
    ld (scroll.metatiles.ram.defsAddress), hl
.endm

;====
; Adjusts the X pixel position of the tilemap. Negative values move left,
; positive move right. After adjusting both axis, call scroll.tiles.update
; to apply the changes
;
; @in   a   the pixel adjustment (must be in the range of -8 to +8 inclusive)
;====
.macro "scroll.metatiles.adjustXPixels"
    tilemap.adjustXPixels
.endm

;====
; Adjusts the Y pixel position of the tilemap. Negative values move up,
; positive move down. After adjusting both axis, call scroll.tiles.update
; to apply the changes
;
; @in   a   the pixel adjustment (must be in the range of -8 to +8 inclusive)
;====
.macro "scroll.metatiles.adjustYPixels"
    tilemap.adjustYPixels
.endm

;====
; Writes the row/column RAM buffers to VRAM and adjusts the scroll registers.
; This should be called during VBlank
;====
.macro "scroll.metatiles.render"
    ; Write the tilemap scroll buffers
    ; tilemap.writeScrollBuffers
.endm
