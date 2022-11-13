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

; Number of subtiles in every metatile definition
.define scroll.metatiles.TILE_COUNT scroll.metatiles.COLS_PER_METATILE * scroll.metatiles.ROWS_PER_METATILE

; Map size modes (value = left shifts required on a row number to point to that row)
.define scroll.metatiles.WIDTH_32   5   ; 32 metatiles
.define scroll.metatiles.WIDTH_64   6   ; 64 metatiles
.define scroll.metatiles.WIDTH_128  7   ; 128 metatiles
.define scroll.metatiles.WIDTH_256  8   ; 256 metatiles

; Number of bytes per metatile definition
.define scroll.metatiles.DEF_SIZE_BYTES scroll.metatiles.TILE_COUNT * tilemap.TILE_SIZE_BYTES

; The ALIGN needed for an array of metatile definitions
.define scroll.metatiles.DEFS_ALIGN scroll.metatiles.DEF_SIZE_BYTES

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

    ; Base address + an offset to the current row or col being output
    scroll.metatiles.ram.defsWithOffset: dw

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
        ld (scroll.metatiles.ram.widthMode), a
        ld iyl, a   ; preserve width mode in IYL

        ; Calculate and store metatiles per row
        ld b, a     ; set B to width mode
        ld a, 1     ; set A to 1
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

        ; Calculate row offset
        ld b, iyl   ; set B to width mode (the number of left shifts needed)
        ld h, 0
        ld l, e     ; set HL to rows to offset
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

        jp _outputMetatileAlongRow

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
                jp _outputMetatileAlongRow
            +:

            ; No sub rows left - point IX to next metatile row
            ld a, i             ; bytes to add (stored in I)
            utils.math.addIXA   ; point IX to next metatile row

            ; Reset offset in DE so we point to first row in metatiles
            ld de, (scroll.metatiles.ram.defsAddress)

            ; Reset rows per metatile
            ld iyl, scroll.metatiles.ROWS_PER_METATILE

            ; ...output next metatile

        ;===
        ; Output a metatile along a row and return if there are no more bytes
        ; to output in the row
        ;
        ; @in   bc  bytes remaining to output in the row
        ; @in   de  defsAddress + subrow offset
        ; @in   ix  pointer to metatileRef in map
        ;===
        _outputMetatileAlongRow:
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
            jp _outputMetatileAlongRow
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
; Alias to call scroll.metatiles.update
;====
.macro "scroll.metatiles.update"
    call scroll.metatiles.update
.endm

;====
; Lookup a metatileRef and point to its metatile definition
;
; @in   l   the metatile reference
; @out  hl  address of the metatile definition relative to the base address.
;           The base address and any row/col offset will need to be added
;           separately
;====
.macro "scroll.metatiles._lookupL"
    ld h, 0
    .repeat scroll.metatiles.LOOKUP_LSHIFT
        add hl, hl
    .endr
.endm

;====
; Update the scroll buffers
;====
.section "scroll.metatiles.update" free
    scroll.metatiles.update:
        ;===
        ; Update the topLeftTile if a row scroll is required
        ;===
        tilemap.ifRowScroll, _moveUp, _moveDown, +
            ;===
            ; When moving 1 tile (subrow) up
            ;===
            _moveUp:
                ;===
                ; If rowsRemaining == ROWS_PER_METATILE we need to point to
                ; previous metatile row (rowsRemaining works in a downward
                ; direction)
                ;===
                ld a, (scroll.metatiles.ram.topLeftTile.rowsRemaining)
                cp scroll.metatiles.ROWS_PER_METATILE
                jr z, ++
                    ;===
                    ; There are subrows left in current metatile.
                    ; rowsRemaining works in a downward direction so when moving
                    ; up a subrow there is now 1 more row to render for current
                    ; metatile
                    ;===
                    inc a   ; inc rowsRemaining
                    ld (scroll.metatiles.ram.topLeftTile.rowsRemaining), a
                    jp +    ; escape tilemap.ifRowScroll
                ++:

                ;===
                ; Update topLeftTile to point to previous metatile row
                ;===

                ; Set rowsRemaining to 1 to refer to the bottom subrow of
                ; the previous metatile row (i.e. 1 row left to render when
                ; drawing from top to bottom)
                ld a, 1
                ld (scroll.metatiles.ram.topLeftTile.rowsRemaining), a

                ; Subtract 1 row from metatileAddress
                ld a, (scroll.metatiles.ram.bytesPerRow)
                neg         ; negate bytes
                ld d, $ff   ; negative high byte
                ld e, a     ; set E to negated low byte
                ld hl, (scroll.metatiles.ram.topLeftTile.metatileAddress)
                add hl, de  ; subtract DE from HL

                ; Store updated metatileAddress
                ld (scroll.metatiles.ram.topLeftTile.metatileAddress), hl

                jp +    ; escape tilemap.ifRowScroll

            ;===
            ; When moving 1 tile (subrow) down
            ;===
            _moveDown:
                ; Check if there are any subrows remaining in current metatile
                ld a, (scroll.metatiles.ram.topLeftTile.rowsRemaining)
                cp 1    ; compare with 1 (rowsRemaining is 1-based)
                jr z, ++
                    ; There are still subrows left in current metatile
                    dec a   ; dec rowsRemaining

                    ; Store result
                    ld (scroll.metatiles.ram.topLeftTile.rowsRemaining), a
                    jp +
                ++:

                ; Current metatile was on its last subrow - we'll need to
                ; point to next metatile row

                ; We'll now be pointing to the first subrow of the next
                ; metatile, so set rowsRemaining to max
                ld a, scroll.metatiles.ROWS_PER_METATILE
                ld (scroll.metatiles.ram.topLeftTile.rowsRemaining), a

                ; Add 1 row to metatileAddress
                ld a, (scroll.metatiles.ram.bytesPerRow)
                ld d, 0
                ld e, a ; set DE to bytesPerRow
                ld hl, (scroll.metatiles.ram.topLeftTile.metatileAddress)
                add hl, de  ; add one row to HL

                ; Store updated metatileAddress
                ld (scroll.metatiles.ram.topLeftTile.metatileAddress), hl
        +:

        ;===
        ; Update the topLeftTile if a col scroll is required
        ;===
        tilemap.ifColScroll, _moveLeft, _moveRight, +
            ;===
            ; When moving left 1 tile (subcol)
            ;===
            _moveLeft:
                ;===
                ; If colsRemaining == COLS_PER_METATILE we need to point to
                ; previous metatile row (colsRemaining works in a downward
                ; direction)
                ;===
                ld a, (scroll.metatiles.ram.topLeftTile.colsRemaining)
                cp scroll.metatiles.COLS_PER_METATILE
                jr z, ++
                    ;===
                    ; There are subcols left in current metatile.
                    ; colsRemaining works in a rightward direction. When moving
                    ; left there is now 1 more row to render for it when rendering
                    ; from left to right, so inc colsRemaining and store result
                    ;===
                    inc a   ; inc colsRemaining
                    ld (scroll.metatiles.ram.topLeftTile.colsRemaining), a
                    jp +
                ++:

                ;===
                ; Update topLeftTile to point to previous metatile col
                ;===

                ; Set colsRemaining to 1 to refer to the right subcol of
                ; the previous metatile row (i.e. 1 col left to render when
                ; drawing from left to right)
                ld a, 1
                ld (scroll.metatiles.ram.topLeftTile.colsRemaining), a

                ; Subtract 1 col from metatileAddress (just decrement)
                ld hl, (scroll.metatiles.ram.topLeftTile.metatileAddress)
                dec hl
                ld (scroll.metatiles.ram.topLeftTile.metatileAddress), hl

                jp +

            ;===
            ; When moving right 1 tile (subcol)
            ;===
            _moveRight:
                ; Check if there are any subcols remaining in current metatile
                ld a, (scroll.metatiles.ram.topLeftTile.colsRemaining)
                cp 1     ; compare with 1 (colsRemaining is 1-based)
                jr z, ++
                    ; There are still subcols left in current metatile
                    dec a   ; dec colsRemaining
                    ld (scroll.metatiles.ram.topLeftTile.colsRemaining), a
                    jp +
                ++:

                ; We need to point to the next metatile column

                ; Set cols remaining to max
                ld a, scroll.metatiles.COLS_PER_METATILE
                ld (scroll.metatiles.ram.topLeftTile.colsRemaining), a

                ; Update metatileAddress to next column (just increment)
                ld hl, (scroll.metatiles.ram.topLeftTile.metatileAddress)
                inc hl
                ld (scroll.metatiles.ram.topLeftTile.metatileAddress), hl
        +:

        ; Update tilemap scroll changes
        tilemap.calculateScroll

        ;===
        ; Update column scroll buffer if necessary
        ;===
        tilemap.ifColScrollElseRet, _updateLeftCol, _updateRightCol
            _updateLeftCol:
                ; Point IX to left visible metatile column
                ld ix, (scroll.metatiles.ram.topLeftTile.metatileAddress)

                ; Load colsRemaining into C and rowsRemaining into B
                ld bc, (scroll.metatiles.ram.topLeftTile.colsRemaining)

                ; Populate the column buffer (routine then returns to caller)
                jp scroll.metatiles._populateColBuffer

            _updateRightCol:
                ; Point IX to left visible metatile column
                ld ix, (scroll.metatiles.ram.topLeftTile.metatileAddress)

                ; Load colsRemaining into C and rowsRemaining into B
                ld bc, (scroll.metatiles.ram.topLeftTile.colsRemaining)

                ; Point to topRight metatile
                ld a, scroll.metatiles.COLS_PER_METATILE
                cp c    ; compare colsRemaining with COLS_PER_METATILE

                ; Calculate tiles to add
                ld a, ceil(tilemap.COLS / scroll.metatiles.COLS_PER_METATILE)
                jp nz, +
                    ; colsRemaining == COLS_PER_METATILE; there are no
                    ; partial tiles on screen and we need to add one less
                    dec a
                +:

                utils.math.addIXA   ; add columns to map pointer

                ;===
                ; Calculate colsRemaining for topRight metatile based on the
                ; colsRemaining for the topLeft metatile (increment it and wrap
                ; back to 1 if it goes over COLS_PER_METATILE)
                ;===
                inc c   ; increment colsRemaining

                ; Check colsRemaining hasn't overflowed
                ld a, scroll.metatiles.COLS_PER_METATILE
                cp c
                jp nc, +
                    ; colsRemaining is greater than COLS_PER_METATILE
                    ld c, 1 ; wrap colsRemaining back to 1
                +:

                ; Populate the column buffer (routine then returns to caller)
                jp scroll.metatiles._populateColBuffer
.ends

;====
; Populates the column buffer with the column being scrolled onto the screen
;
; @in   b   rowsRemaining in the top-most metatile of the column
; @in   c   colsRemaining in the top-most metatile of the column
; @in   ix  pointer to the top-most metatileRef to output
;====
.section "scroll.metatiles._populateColBuffer" free
    scroll.metatiles._populateColBuffer:
        ; Get current subcol offset in bytes
        ld a, scroll.metatiles.COLS_PER_METATILE
        sub c               ; set A to current col (cols - colsRemaining)
        rlca                ; multiply by 2 (2 bytes per tile)

        ; Calculate defsWithOffset (defsAddress + subcol offset)
        ld de, (scroll.metatiles.ram.defsAddress)
        utils.math.addDEA   ; add to the defsAddress to get defsWithOffset
        ld (scroll.metatiles.ram.defsWithOffset), de

        ; Load bytesPerRow and store in IYH
        ld a, (scroll.metatiles.ram.bytesPerRow)
        ld iyh, a

        ;===
        ; The top metatile may be partly off the top of the screen, so we'll
        ; need skip to the first visible subrow and draw from there. We also
        ; need to keep track of how many subrows to output before moving to the
        ; next metatile.
        ;
        ; @in   b   rowsRemaining in the top metatile
        ; @in   c   colsRemaining in the top metatile
        ; @in   de  address of the definitions + offset to the subcol
        ; @in   ix  pointer to the top metatileRef in the column
        ;===
        _outputTopMetatile:
            ;===
            ; Add subrow offset
            ;===
            ; Get current subrow
            ld a, scroll.metatiles.ROWS_PER_METATILE
            sub b       ; subtract rowsRemaining to get current subrow

            ; Get subrow offset in bytes
            .repeat scroll.metatiles.METATILE_ROW_LSHIFTS
                rlca    ; left-shift
            .endr

            utils.math.addDEA           ; add row offset to defsWithOffset

            ;===
            ; Lookup metatileRef
            ;===
            ld a, (ix + 0)              ; load metatileRef
            ld l, a                     ; set L to metatileRef
            scroll.metatiles._lookupL   ; lookup relative metatileDef address
            add hl, de                  ; add defsWithOffset

            ; Prepare to write to column buffer
            ld iyl, b                   ; move rowsRemaining to iyl
            tilemap.loadDEColBuffer     ; set DE to the column buffer
            tilemap.loadBCColBytes      ; set BC to bytes to write

            ;===
            ; Output each potential subrow in the metatile
            ; Jump to _nextMetatileRow when iyl reaches 0
            ;===
            .repeat scroll.metatiles.ROWS_PER_METATILE index row
                ; Output one tile
                ldi     ; output pattern number
                ldi     ; output tile attributes

                ; Increment subrow (unless this is the last possible one)
                .if row < scroll.metatiles.ROWS_PER_METATILE - 1
                    dec iyl                 ; dec rowsRemaining
                    jp z, _nextMetatileRow  ; jump if no rows left in this metatile

                    ; Skip remaining columns in metatile (total minus the one
                    ; we've just output, multiplied by bytes)
                    ld a, tilemap.TILE_SIZE_BYTES * (scroll.metatiles.COLS_PER_METATILE - 1)
                    add l   ; add L to column bytes
                    ld l, a ; set HL to result
                .endif
            .endr

        ; Point to the next metatile row in the column
        _nextMetatileRow:
            ld a, iyh           ; set A to bytesPerRow (stored in IYH)
            utils.math.addIXA   ; add bytesPerRow to map pointer
                                ; continue to _outputMetatileColumn

        ;===
        ; Copy a metatile column to the buffer, starting from the top subrow.
        ; Continues outputting metatiles until bytes remaining is 0.
        ;
        ; @in   c   bytes left to output in this column
        ; @in   de  pointer to column buffer
        ; @in   ix  pointer to metatileRef in the map
        ;===
        _outputMetatileColumn:
            ld a, (ix + 0)              ; load metatileRef
            ld l, a                     ; set L to metatileRef
            scroll.metatiles._lookupL   ; lookup relative metatileDef address

            ; Add defsWithOffset to metatileDef pointer
            ld iyl, c   ; preserve bytes remaining in IYL
            ld bc, (scroll.metatiles.ram.defsWithOffset)
            add hl, bc  ; add offset to definition pointer

            ; Restore BC to bytes remaining
            ld b, 0     ; high byte is always 0
            ld c, iyl   ; BC is now bytes remaining

            ; Each potential row in the metatile
            .repeat scroll.metatiles.ROWS_PER_METATILE index row
                ; Output one tile
                ldi     ; output pattern number
                ldi     ; output tile attributes
                ret po  ; return if no more bytes to output (BC == 0)

                ; Increment subrow (unless this is the last possible one)
                .if row < scroll.metatiles.ROWS_PER_METATILE - 1
                    ; Skip remaining columns in metatile (total minus the one
                    ; we've just output, multiplied by bytes)
                    ld a, tilemap.TILE_SIZE_BYTES * (scroll.metatiles.COLS_PER_METATILE - 1)
                    add l   ; set A to current tile + bytes to skip
                    ld l, a ; set HL to result
                .endif
            .endr

            jp _nextMetatileRow
.ends

;====
; Writes the row/column RAM buffers to VRAM and adjusts the scroll registers.
; This should be called during VBlank
;====
.macro "scroll.metatiles.render"
    ; Write the tilemap scroll buffers
    tilemap.writeScrollBuffers
.endm
