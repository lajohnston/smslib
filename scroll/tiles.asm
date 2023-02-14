;====
; Builds on the API provided by tilemap.asm to provide a scrollable map of
; uncompressed tile data
;====

;====
; Dependencies
;====
.ifndef tilemap.ENABLED
    .print "\nscroll/tiles.asm requires tilemap.asm to have been .included first\n\n"
    .fail
.endif

.ifndef utils.math
    .include "utils/math.asm"
.endif

.include "utils/ramSlot.asm"

;====
; RAM variables
;====
.ramsection "scroll.tiles.ram" slot utils.ramSlot
    ; Pointer to the current top left visible tile
    scroll.tiles.ram.topLeft:       dw

    ; Col and row counters, to help with bounds checking
    scroll.tiles.ram.leftCol:       db  ; 1-based; 0 means out of bounds
    scroll.tiles.ram.topRow:        db  ; 1-based; 0 means out of bounds

    ; The max value topRow should be before the bottom row is out of bounds
    scroll.tiles.ram.maxTopRow:     db

    ; Number of bytes per row (column count * 2)
    ; Used when inc/decrementing rows and for column bounds checking
    scroll.tiles.ram.bytesPerRow:    db

    ; Number of bytes to add to topLeft in order to point to left-most column
    ; of the bottom row
    scroll.tiles.ram.screenHeightBytes: dw
.ends

;====
; Initialises the map in RAM and draws the initial screen of tiles. Should be
; called when the display is off
;
; @in   topLeftPointer|hl   pointer to the topLeft visible tile
;
; @in   mapCols|a           the number of columns in the full map (max 127).
;                           If using A, multiply by 2
;
; @in   mapRows|b           the number of rows in the full map (max 255)
;
; @in   colOffset|d         the number of columns right the initial view is
;                           offset by. If using D the value should be 1-based
;                           and you should also offset topLeftPointer accordingly
;
; @in   rowOffset|e         the number of rows down the initial view is
;                           offset by. If using E the value should be 1-based
;                           and you should also offset topLeftPointer accordingly
;====
.macro "scroll.tiles.init" args topLeftPointer mapCols mapRows colOffset rowOffset
    .if NARGS > 0
        .define \.\@topLeft topLeftPointer

        .ifdef mapCols
            ; Set bytes per row (number of columns * 2 bytes per tile)
            ld a, mapCols * tilemap.TILE_SIZE_BYTES
        .endif

        .ifdef mapRows
            ; Set number of rows in the map
            ld b, mapRows
        .endif

        .ifdef colOffset
            ; Set column offset (add 1 to make it 1-based)
            ld d, colOffset + 1

            ; Add column  offset to topLeftPointer
            .redefine \.\@topLeft (\.\@topLeft) + (colOffset * tilemap.TILE_SIZE_BYTES)
        .endif

        .ifdef rowOffset
            ; Set row offset (add 1 to make it 1-based)
            ld e, rowOffset + 1

            ; Add row offset to topLeftPointer
            .redefine \.\@topLeft (\.\@topLeft) + (rowOffset * (mapCols * tilemap.TILE_SIZE_BYTES))
        .endif

        ; Set pointer to initial top left tile in the tilemap
        ld hl, \.\@topLeft
    .endif

    call scroll.tiles.init
.endm

;====
; Initialises the map in RAM and draws the initial screen of tiles. Should be
; called when the display is off
;
; @in   a   the number of bytes per row in the full tilemap (columns * 2)
; @in   b   the number of rows in the full tilemap
; @in   hl  pointer to the tilemap data (top left corner of map)
;====
.section "scroll.tiles.init"
    scroll.tiles.init:
        ; Store topLeft and bytesPerRow
        ld (scroll.tiles.ram.topLeft), hl
        ld (scroll.tiles.ram.bytesPerRow), a

        ; Calculate the maximum value scroll.tiles.ram.topRow should be
        ld c, a                             ; preserve bytesPerRow in C
        ld a, b                             ; set A to rows in tilemap
        sub tilemap.MIN_VISIBLE_ROWS - 1    ; subtract rows on the screen
                                            ; (minus 1 as topRow is 1-based)
        ld (scroll.tiles.ram.maxTopRow), a  ; store maxTopRow

        ; Set HL to bytesPerRow
        ld h, 0                             ; set H to 0
        ld l, c                             ; set L to bytesPerRow

        ; Multiply bytesPerRow by rows
        utils.math.multiplyHL tilemap.MIN_VISIBLE_ROWS
        ld (scroll.tiles.ram.screenHeightBytes), hl

        ; Set topRow
        ld a, e
        ld (scroll.tiles.ram.topRow), a

        ; Set leftCol
        ld a, d
        ld (scroll.tiles.ram.leftCol), a

        ;====
        ; Draw initial screen
        ;====

        ; Initialise tilemap
        tilemap.reset                       ; initialise scroll values
        tilemap.setColRow 0, 0              ; set vram write address (x0, y0)

        ; Draw the screen
        ld hl, (scroll.tiles.ram.topLeft)   ; point HL to topLeft pointer
        ld d, tilemap.MAX_VISIBLE_ROWS      ; number of rows to output

        ; Set E to bytesPerRow
        ld a, (scroll.tiles.ram.bytesPerRow); load bytesPerRow
        ld e, a                             ; set E to bytesPerRow

        ; Load rows of tiles into VRAM
        jp tilemap.writeRows                ; jp to writeRows, which returns
.ends

;====
; Adjusts the X pixel position of the tilemap. Negative values move left,
; positive move right. After adjusting both axis, call scroll.tiles.update
; to apply the changes
;
; @in   a   the pixel adjustment (must be in the range of -8 to +8 inclusive)
;====
.macro "scroll.tiles.adjustXPixels"
    tilemap.adjustXPixels
.endm

;====
; Adjusts the Y pixel position of the tilemap. Negative values move up,
; positive move down. After adjusting both axis, call scroll.tiles.update
; to apply the changes
;
; @in   a   the pixel adjustment (must be in the range of -8 to +8 inclusive)
;====
.macro "scroll.tiles.adjustYPixels"
    tilemap.adjustYPixels
.endm

;====
; Alias to call scroll.tiles.update
;====
.macro "scroll.tiles.update"
    call scroll.tiles.update
.endm

;====
; Updates the RAM buffers. This should be called after calling
; scroll.tiles.adjustXPixels and scroll.tiles.adjustYPixels
;====
.section "scroll.tiles.update" free
    scroll.tiles.update:
        ; Adjust the worldmap row position if required
        tilemap.ifRowScroll, _moveUp, _moveDown, +
            _moveUp:
                ; Try moving up one row and check bounds
                ld a, (scroll.tiles.ram.topRow)         ; load current topRow
                dec a                                   ; dec topRow (move up)
                jr z, ++                                ; jp if 0 (out of bounds)
                    ; Value is in bounds
                    ld (scroll.tiles.ram.topRow), a     ; save updated topRow
                    ld hl, (scroll.tiles.ram.topLeft)   ; load current topLeft

                    ; Move topLeft up one row (subtract bytesPerRow)
                    ld a, (scroll.tiles.ram.bytesPerRow); load bytesPerRow
                    neg                                 ; negate bytesPerRow
                    ld d, $ff                           ; negative high byte
                    ld e, a                             ; set E to negated bytesPerRow
                    add hl, de                          ; add (subtract) row
                    ld (scroll.tiles.ram.topLeft), hl   ; store updated topLeft pointer
                    jp +
                ++:

                ; Out of bounds
                tilemap.stopUpRowScroll
                jp +

            _moveDown:
                ; Load maxTopRow into B
                ld a, (scroll.tiles.ram.maxTopRow)      ; load maxTopRow
                ld b, a                                 ; store maxTopRow in B

                ; Increment topRow in A
                ld a, (scroll.tiles.ram.topRow)         ; load topRow
                inc a                                   ; inc topRow (move down)
                cp b                                    ; compare with maxTopRow
                jr nc, ++                               ; jp if topRow > maxTopRow
                    ; Value is in bounds
                    ld (scroll.tiles.ram.topRow), a     ; save updated topRow
                    ld hl, (scroll.tiles.ram.topLeft)   ; load current topLeft

                    ; Add bytesPerRow to topLeft pointer to move down one row
                    ld a, (scroll.tiles.ram.bytesPerRow); load bytes per row
                    utils.math.addHLA                   ; add bytesPerRow to pointer
                    ld (scroll.tiles.ram.topLeft), hl   ; store new topLeft
                    jp +
                ++:

                ; Out of bounds
                tilemap.stopDownRowScroll
        +:

        ; Adjust the worldmap column position if required
        tilemap.ifColScroll, _moveLeft, _moveRight, +
            _moveLeft:
                ; Try moving left one column and check bounds
                ld a, (scroll.tiles.ram.leftCol)        ; load leftCol
                dec a                                   ; dec col (move left)
                jr z, ++                                ; jp if 0 (out of bounds)
                    ; Value is in bounds
                    ld (scroll.tiles.ram.leftCol), a    ; store updated leftCol
                    ld hl, (scroll.tiles.ram.topLeft)   ; load top left pointer

                    ; Subtract 1 tile to move left
                    .repeat tilemap.TILE_SIZE_BYTES
                        dec hl
                    .endr

                    ld (scroll.tiles.ram.topLeft), hl   ; store new topLeft
                    jp +
                ++:

                ; Out of bounds
                tilemap.stopLeftColScroll
                jp +

            _moveRight:
                ; Get the maximum value leftCol should be
                ld a, (scroll.tiles.ram.bytesPerRow)
                rrca            ; divide by 2 to get columns
                and %01111111   ; clean value
                sub 31 - 1      ; get left-most column of screen
                ld b, a         ; store max left column in B

                ; Increment column and check with maximum value
                ld a, (scroll.tiles.ram.leftCol)    ; load value
                inc a                               ; inc column (move right)
                cp b                                ; compare with max value
                jr nc, ++                           ; jp if leftCol > max left col
                    ; Value is in bounds
                    ld (scroll.tiles.ram.leftCol), a    ; store updated leftCol
                    ld hl, (scroll.tiles.ram.topLeft)   ; load topLeft pointer

                    ; Add 1 tile to topLeft pointer to move right
                    .repeat tilemap.TILE_SIZE_BYTES
                        inc hl
                    .endr

                    ld (scroll.tiles.ram.topLeft), hl
                    jp +
                ++:

                ; Out of bounds
                tilemap.stopRightColScroll
        +:

        ; Update tilemap scroll changes
        tilemap.calculateScroll

        ; Update row buffer
        call scroll.tiles._updateRowBuffer

        ; Update col buffer, then return
        jp scroll.tiles._updateColBuffer    ; _updateColBuffer returns
.ends

;====
; Writes the row/column RAM buffers to VRAM and adjusts the scroll registers.
; This should be called during VBlank
;====
.macro "scroll.tiles.render"
    ; Write the tilemap scroll buffers
    tilemap.writeScrollBuffers
.endm

;====
; Updates the row buffer in RAM if required
;====
.section "scroll.tiles._updateRowBuffer" free
    scroll.tiles._updateRowBuffer:
        ; Return if not scroll needed, otherwise jump to relevant label
        tilemap.ifRowScrollElseRet, _updateUpBuffer, _updateDownBuffer
            ; Update row at the top of the screen
            _updateUpBuffer:
                ld hl, (scroll.tiles.ram.topLeft)   ; load topLeft pointer
                jp _loadRowBuffer

            ; Load the row at the bottom of the screen
            _updateDownBuffer:
                ld hl, (scroll.tiles.ram.topLeft)   ; point to top left tile
                ex de, hl                           ; preserve top left pointer in DE
                ld hl, (scroll.tiles.ram.screenHeightBytes) ; load screenHeightBytes into HL
                add hl, de                          ; add screen height to topLeft pointer
                ; continue to _loadRowBuffer

        ; Load the tiles into the row buffer
        _loadRowBuffer:
            tilemap.loadDERowBuffer ; point DE to row buffer
            tilemap.loadBCRowBytes  ; set BC to bytes to write
            ldir    ; copy data from HL (tilemap) to DE (buffer)
            ret
.ends

;====
; Updates the column buffer in RAM if required
;====
.section "scroll.tiles._updateColBuffer" free
    scroll.tiles._updateColBuffer:
        ; Check for column scrolling
        tilemap.ifColScrollElseRet _left, _right
            _left:
                ld hl, (scroll.tiles.ram.topLeft)   ; point to top left tile
                jp _loadColBuffer

            _right:
                ; Point to right of screen by adding 31 tiles
                ld hl, (scroll.tiles.ram.topLeft)   ; point to top left tile
                ld a, 31 * tilemap.TILE_SIZE_BYTES
                utils.math.addHLA                   ; add A to HL
                ; continue to _loadColBuffer

        ; Load the tiles into the column buffer
        _loadColBuffer:
            ; Populate the column buffer with the tiles we wish to draw
            tilemap.loadDEColBuffer ; point DE to the column buffer
            tilemap.loadBCColBytes  ; set BC to number of bytes to write

            ; Get bytes to add to point to the next row (bytes per row minus
            ; the 2 bytes we'll have just outputted)
            ld a, (scroll.tiles.ram.bytesPerRow)
            sub tilemap.TILE_SIZE_BYTES ; sub 2 bytes we'll have just outputted
            ld ixl, a                   ; preserve in ixl

            ; For each row in the column
            .repeat tilemap.MAX_VISIBLE_ROWS index row
                ; Copy tile from the tilemap to the buffer
                .repeat tilemap.TILE_SIZE_BYTES
                    ldi ; send byte to the buffer
                .endr

                ; Return, or go to next row
                .ifeq row tilemap.MAX_VISIBLE_ROWS - 1
                    ; Max rows reached - return
                    ret
                .else
                    ; Return if BC = 0 (P/V is reset)
                    ret po

                    ; Go to next row in full tilemap
                    ld a, ixl   ; bytes to add to point to next row
                    utils.math.addHLA
                .endif
            .endr
.ends
