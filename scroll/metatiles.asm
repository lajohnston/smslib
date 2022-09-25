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

; Map size modes (value = left shifts required on a row number to point to that row)
.define scroll.metatiles.WIDTH_32   5   ; 32 metatiles
.define scroll.metatiles.WIDTH_64   6   ; 64 metatiles
.define scroll.metatiles.WIDTH_128  7   ; 128 metatiles
.define scroll.metatiles.WIDTH_256  8   ; 256 metatiles

;====
; METATILE_COLS_MODULO: AND mask to modulo a number by COLS_PER_METATILE
; METATILE_ROW_LSHIFTS: number of times to left shift a subrow number to point
;                       to that row within a metatileDef
;====
.if scroll.metatiles.COLS_PER_METATILE == 2
    .define scroll.metatiles.METATILE_COLS_MODULO %00000001
    .define scroll.metatiles.METATILE_ROW_LSHIFTS 2
.elif scroll.metatiles.COLS_PER_METATILE == 4
    .define scroll.metatiles.METATILE_COLS_MODULO %00000011
    .define scroll.metatiles.METATILE_ROW_LSHIFTS 3
.elif scroll.metatiles.COLS_PER_METATILE == 8
    .define scroll.metatiles.METATILE_COLS_MODULO %00000111
    .define scroll.metatiles.METATILE_ROW_LSHIFTS 4
.elif scroll.metatiles.COLS_PER_METATILE == 16
    .define scroll.metatiles.METATILE_COLS_MODULO %00001111
    .define scroll.metatiles.METATILE_ROW_LSHIFTS 5
.endif

;====
; METATILE_ROWS_MODULO:     AND mask to modulo a number by ROWS_PER_METATILE
; SUBROW_TO_ROW_RSHIFTS:    Number of times to right shift a subrow offset to
;                           get the metatile row
; SUBROW_TO_ROW_MASK:       AND mask to apply after using SUBROW_TO_ROW_RSHIFTS
;====
.if scroll.metatiles.ROWS_PER_METATILE == 2
    .define scroll.metatiles.METATILE_ROWS_MODULO %00000001
    .define scroll.metatiles.SUBROW_TO_ROW_RSHIFTS 1
    .define scroll.metatiles.SUBROW_TO_ROW_MASK %01111111
.elif scroll.metatiles.ROWS_PER_METATILE == 4
    .define scroll.metatiles.METATILE_ROWS_MODULO %00000011
    .define scroll.metatiles.SUBROW_TO_ROW_RSHIFTS 2
    .define scroll.metatiles.SUBROW_TO_ROW_MASK %00111111
.elif scroll.metatiles.ROWS_PER_METATILE == 8
    .define scroll.metatiles.METATILE_ROWS_MODULO %00000111
    .define scroll.metatiles.SUBROW_TO_ROW_RSHIFTS 3
    .define scroll.metatiles.SUBROW_TO_ROW_MASK %00011111
.elif scroll.metatiles.ROWS_PER_METATILE == 16
    .define scroll.metatiles.METATILE_ROWS_MODULO %00001111
    .define scroll.metatiles.SUBROW_TO_ROW_RSHIFTS 4
    .define scroll.metatiles.SUBROW_TO_ROW_MASK %00001111
.endif

; Number of times to left shift a metatileRef to get the metatileDef offset
.if scroll.metatiles.TILE_COUNT == 4
    .define scroll.metatiles.LOOKUP_LSHIFT 3
.elif scroll.metatiles.TILE_COUNT == 8
    .define scroll.metatiles.LOOKUP_LSHIFT 4
.elif scroll.metatiles.TILE_COUNT == 16
    .define scroll.metatiles.LOOKUP_LSHIFT 5
.elif scroll.metatiles.TILE_COUNT == 32
    .define scroll.metatiles.LOOKUP_LSHIFT 6
.elif scroll.metatiles.TILE_COUNT == 64
    .define scroll.metatiles.LOOKUP_LSHIFT 7
.elif scroll.metatiles.TILE_COUNT == 128
    .define scroll.metatiles.LOOKUP_LSHIFT 8
.elif scroll.metatiles.TILE_COUNT == 256
    .define scroll.metatiles.LOOKUP_LSHIFT 9
.endif

; Number of full metatile columns on the screen at a time
.define scroll.metatiles.VISIBLE_METATILE_COLS tilemap.COLS / scroll.metatiles.COLS_PER_METATILE

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
    scroll.metatiles.ram.topMetatileRow:    db  ; 1-based (1 = col 0)
    scroll.metatiles.ram.leftMetatileCol:   db  ; 1-based (1 = row 0)

    ; Pointer to the metatile definitions
    scroll.metatiles.ram.defsAddress: dw

    ; How many metatile columns there are in the map (0-based; 0=1, 255=256)
    scroll.metatiles.ram.metatileColumns: db

    ; The width of the current map, the value of which is one of the
    ; scroll.metatiles.WIDTH_* constants. The value is the number of times to
    ; left shift a row number to point to its first column in the metatilemap
    scroll.metatiles.ram.widthMode: db

    ; The number of bytes per map row (also the number of metatiles per row)
    scroll.metatiles.ram.bytesPerRow: db

    ; Grid of 1-byte metatile refs
    scroll.metatiles.ram.map: dsb scroll.metatiles.MAX_MAP_BYTES
.ends

;====
; Alias to call scroll.metatiles.init
;
; @in   a           the map's width mode (should be one of the
;                   scroll.metatiles.WIDTH_xxx values)
; @in   colOffset|d (optional) the left-most metatile column to draw
; @in   rowOffset|e (optional) the top-most metatile row to draw
;====
.macro "scroll.metatiles.init" args colOffset rowOffset
    .ifdef colOffset
        .ifdef rowOffset
            ; Both colOffset and rowOffset set
            ld de, rowOffset + (colOffset * 256)
        .else
            ; Only colOffset set
            ld d, colOffset
        .endif
    .endif

    call scroll.metatiles.init
.endm

;====
; Sets the initial position of the map and draws a full screen of tiles. This
; should be called when the display is off.
;
; @in   a   the map's width mode (should be one of the
;           scroll.metatiles.WIDTH_xxx values)
; @in   d   the column offset in metatiles
; @in   e   the row offset in metatiles
;====
.section "scroll.metatiles.init" free
    scroll.metatiles.init:
        ; Store width mode
        ld (scroll.metatiles.ram.widthMode), a  ; set width mode

        ; Calculate and store metatiles per row
        ld b, a ; set B to width mode
        ld a, 1 ; set A to 1
        -:
            ; Left-shift A until it equals metatiles per row
            rlca ; A = A * 2
        djnz -

        ; Store metatiles per row
        ld (scroll.metatiles.ram.bytesPerRow), a

        ; Set topMetatileRow to E and leftMetatileCol to D
        inc d   ; make leftMetatileCol 1-based
        inc e   ; make topMetatileRow 1-based
        ld (scroll.metatiles.ram.topMetatileRow), de
        dec d   ; restore leftMetatileCol
        dec e   ; restore topMetatileRow

        ; Set H to rowsRemaining and L to colsRemaining (both to max, as there
        ; is no subtile offset)
        ld hl, scroll.metatiles.ROWS_PER_METATILE * 256 + scroll.metatiles.COLS_PER_METATILE

        ; Store colsRemaining (L) and rowsRemaining (H)
        ld (scroll.metatiles.ram.topLeftTile.colsRemaining), hl

        ;===
        ; Set metatileAddress
        ; (metatileRowOffset * mapWidthCols) + metatileColOffset + baseAddress
        ;===

        ; Calculate row address
        ld b, a ; set B to width mode (the number of left shifts needed)
        ld h, 0
        ld l, e ; set HL to rows to offset
        -:
            ; Multiply row offset by columns in the map
            add hl, hl  ; HL = HL * 2 (left shift)
        djnz -

        ; Add metatile column offset to HL
        ld b, 0
        ld c, d     ; set BC to column offset
        add hl, bc  ; add column offset to address

        ; Add base map address to HL
        ld bc, scroll.metatiles.ram.map
        add hl, bc

        ; Store resulting metaTileAddress
        ld (scroll.metatiles.ram.topLeftTile.metatileAddress), hl

        ; Draw a full screen of tiles (which then returns)
        jp scroll.metatiles._drawFullScreen
.ends

;====
; Draw a full screen of tiles. This should only be called when the display is off
;====
.section "scroll.metatiles._drawFullScreen" free
    scroll.metatiles._drawFullScreen:
        ; Reset tilemap and set write address
        tilemap.reset                       ; initialise scroll values
        tilemap.setColRow 0, 0              ; set VRAM write address (x0, y0)

        ;===
        ; Calculate number of metatiles to add to pointer after each row
        ;===

        ; Load bytes/metatiles per map row
        ld a, (scroll.metatiles.ram.bytesPerRow)

        ; Subtract metatiles we'll have already output.
        ; Minus 1 as pointer isn't incremented for last one
        sub scroll.metatiles.VISIBLE_METATILE_COLS - 1
        ld i, a                                     ; store result in I

        ; Prep tile output
        ld b, tilemap.ROW_SIZE_BYTES                ; bytes to output (1 row)
        ld de, (scroll.metatiles.ram.defsAddress)   ; base definition address
        ld ix, (scroll.metatiles.ram.topLeftTile.metatileAddress) ; map pointer
        ld iyh, tilemap.MAX_VISIBLE_ROWS            ; set IYH to rows to output

        ; Set IYL to subrows left in current row of metatiles
        ld a, (scroll.metatiles.ram.topLeftTile.rowsRemaining)
        ld iyl, a

        jp _outputMetatile

        _nextSubRow:
            dec iyh ; decrement tilemap rows remaining
            ret z   ; return if no rows left to output

            ld b, tilemap.ROW_SIZE_BYTES    ; bytes to output (1 row)

            ; Decrement subrows remaining in current metatile row
            dec iyl
            jr z, +
                ; There are still some subrows left in current metatile row

                ; Point IX back to first metatile column (minus 1 as the pointer
                ; isn't incremented for the last one)
                utils.math.subIX scroll.metatiles.VISIBLE_METATILE_COLS - 1

                ; Add a subrow to the definition offset in DE
                ld hl, scroll.metatiles.COLS_PER_METATILE * tilemap.TILE_SIZE_BYTES
                add hl, de  ; add a row
                ex hl, de   ; store result in DE
                jp _outputMetatile
            +:

            ; No sub rows left - point IX to next metatile row
            ld a, i             ; bytes to add (stored in I)
            utils.math.addIXA   ; point IX to next metatile row

            ; Reset offset in DE so we point to first row in metatiles
            ld de, (scroll.metatiles.ram.defsAddress)

            ; Reset rows per metatile
            ld iyl, scroll.metatiles.ROWS_PER_METATILE

            ; ...output next metatile

        _outputMetatile:
            ; Get metatileRef
            ld a, (ix + 0)  ; load metatileRef into A
            ld h, 0
            ld l, a         ; set HL to metatileRef

            ; Lookup metatileDef offset
            utils.math.leftShiftHL scroll.metatiles.LOOKUP_LSHIFT
            add hl, de      ; add offset (base address + subrow offset)

            ; Output tiles
            .repeat scroll.metatiles.COLS_PER_METATILE
                outi
                outi

                .if scroll.metatiles.COLS_PER_METATILE > 8
                    jp z, _nextSubRow  ; no more tiles to output in this row
                .else
                    jr z, _nextSubRow  ; no more tiles to output in this row
                .endif
            .endr

            ; Keep outputting metatiles along the row
            inc ix
            jp _outputMetatile
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
