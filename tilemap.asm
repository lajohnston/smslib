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
.ifndef tilemap.vramAddress
    .define tilemap.vramAddress $3800
.endif

;====
; Dependencies
;====
.ifndef utils.math
    .include "utils/math.asm"
.endif

.ifndef utils.outiBlock
    .include "utils/outiBlock.asm"
.endif

.include "./utils/ramSlot.asm"

.ifndef utils.vdp
    .include "utils/vdp.asm"
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
.define tilemap.VDP_DATA_PORT $be
.define tilemap.ROWS 28
.define tilemap.COLS 32

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
.ramsection "tilemap.ram" slot utils.ramSlot
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
.ramsection "tilemap.ram.colBuffer" slot utils.ramSlot
    tilemap.ram.colBuffer:      dsb tilemap.COL_SIZE_BYTES
.ends

;===
; Buffer of raw row tiles
; Align to 256 so low byte starts at 0 and can be set to the offset
;===
.ramsection "tilemap.ram.rowBuffer" slot utils.ramSlot align 256
    tilemap.ram.rowBuffer:      dsb tilemap.ROW_SIZE_BYTES
.ends

;====
; Public functions
;====

;====
; Set the tile slot ready to write to
;
; @in   slotNumber  0 is top left tile
;====
.macro "tilemap.setSlot" args slotNumber
    utils.vdp.prepWrite (tilemap.vramAddress + (slotNumber * tilemap.TILE_SIZE_BYTES))
.endm

;====
; Set the tile slot ready to write to
;
; @in   col     column number (x)
; @in   row     row number (y)
;====
.macro "tilemap.setColRow" args colX rowY
    tilemap.setSlot ((rowY * tilemap.COLS) + colX)
.endm

;====
; Define tile data
;
; @in   patternSlot the pattern slot (0-511)
; @in   attributes  (optional) the tile attributes (see Tile attributes section).
;                   Note, if patternRef is greater than 255, tilemap.HIGH_BIT
;                   is set automatically
;====
.macro "tilemap.tile" args patternSlot attributes
    .ifndef attributes
        .define attributes $00
    .endif

    .ifgr patternSlot 255
        .redefine attributes attributes | tilemap.HIGH_BIT
    .endif

    .db <(patternSlot)  ; low byte of patternSlot
    .db attributes
.endm

;====
; Reads pattern ref bytes and sends to the tilemap until a terminator byte is
; reached.
;
; @in   hl  address of the data to send
; @in   b   tile attributes to use for all the tiles
; @in   c   the data port to send to
; @in   d   the terminator byte value
;====
.section "tilemap.loadBytesUntil" free
    tilemap.loadBytesUntil:
        ld a, (hl)                      ; read byte
        cp d                            ; compare value with terminator
        ret z                           ; return if terminator byte found
        out (tilemap.VDP_DATA_PORT), a  ; output pattern ref
        ld a, b                         ; load attributes
        out (tilemap.VDP_DATA_PORT), a  ; output attributes
        inc hl                          ; next char
        jp tilemap.loadBytesUntil       ; repeat
.ends

;====
; Reads pattern ref bytes and sends to the tilemap until a terminator byte is
; reached
;
; @in   terminator  value that signifies the end of the data
; @in   dataAddr    address of the first byte of ASCII data
; @in   [attributes] tile attributes to use for all the tiles (see tile
;                    attribute options at top)
;====
.macro "tilemap.loadBytesUntil" args terminator dataAddr attributes
    ld d, terminator
    ld hl, dataAddr

    .ifdef attributes
        ld b, attributes
    .else
        ld b, 0
    .endif

    call tilemap.loadBytesUntil
.endm

;====
; Loads bytes of data representing tile pattern refs
;
; @in   hl  the address of the data to load
; @in   b   the number of bytes to load
; @in   c   tile attributes to use for all the tiles (see tile
;           attribute options at top)
;====
.section "tilemap.loadBytes" free
    _nextByte:
        inc hl                          ; next byte

    tilemap.loadBytes:
        ld a, (hl)                      ; read byte
        out (tilemap.VDP_DATA_PORT), a  ; output pattern ref
        ld a, c                         ; load attributes
        out (tilemap.VDP_DATA_PORT), a  ; output attributes
        djnz _nextByte                  ; repeat until b = 0
        ret
.ends

;====
; Loads bytes of data representing tile pattern refs
;
; @in   address         the address of the data to load
; @in   count           the number of bytes to load
; @in   [attributes]    the attributes to use for each tile
;                       See tile attribute options at top
;====
.macro "tilemap.loadBytes" args address count attributes
    ld hl, address
    ld b,  count

    .ifdef attributes
        ld c, attributes
    .else
        ld c, 0
    .endif

    call tilemap.loadBytes
.endm

;====
; Load a row (32-tiles) of uncompressed data. Each tile is 2-bytes - the
; first is the patternRef and the second is the tile's attributes.
;
; @in   hl  pointer to the raw data
;====
.macro "tilemap.loadRow"
    ; Output 1 row of data
    utils.outiBlock.send tilemap.ROW_SIZE_BYTES
.endm

;====
; Alias for tilemap.loadRows
;====
.macro "tilemap.loadRows"
    call tilemap.loadRows
.endm

;====
; Load tile data from an uncompressed map. Each tile is 2-bytes - the first is
; the tileRef and the second is the tile's attributes.
;
; @in   d   number of rows to load
; @in   e   the amount to increment the pointer by each row i.e. the number of
;           columns in the full map * 2 (as each tile is 2-bytes)
; @in   hl  pointer to the first tile to load
;====
.section "tilemap.loadRows"
    _nextRow:
        ld a, e                 ; load row width into A
        utils.math.addHLA       ; add 1 row to full tilemap pointer

    tilemap.loadRows:
        push hl                 ; preserve HL
            tilemap.loadRow     ; load a row of data
        pop hl                  ; restore HL

        dec d
        jp nz, _nextRow
        ret
.ends

;====
; Alias to call tilemap.reset
;====
.macro "tilemap.reset"
    call tilemap.reset
.endm

;====
; Initialise the RAM buffers and scroll values to their starting state
;====
.section "tilemap.reset" free
    tilemap.reset:
        xor a   ; set A to 0
        ld (tilemap.ram.flags), a
        ld (tilemap.ram.yScrollBuffer), a

        ld (tilemap.ram.vramRowWrite), a
        ld (tilemap.ram.vramRowWrite + 1), a

        ld (tilemap.ram.colWriteCall), a
        ld (tilemap.ram.colWriteCall + 1), a

        ; Set the VDP SCROLL_Y_REGISTER to 0
        utils.vdp.setRegister utils.vdp.SCROLL_Y_REGISTER

        ; Set the xScrollBuffer to the starting X_OFFSET value
        ld a, tilemap.X_OFFSET
        ld (tilemap.ram.xScrollBuffer), a

        ; Write xScrollBuffer to the VDP SCROLL_X_REGISTER (needs to be negated)
        ld a, -tilemap.X_OFFSET
        utils.vdp.setRegister utils.vdp.SCROLL_X_REGISTER

        ret
.ends

;====
; Adjusts the buffered tilemap xScroll value by a given number of pixels. If this
; results in a new column needing to be drawn it sets flags in RAM indicating
; whether the left or right column needs reloading. You can interpret these flags
; using tilemap.ifColScroll.
;
; The scroll value won't apply until you call tilemap.writeScrollRegisters
;
; @in   a   the number of x pixels to adjust. Positive values scroll right in
;           the game world (shifting the tiles left). Negative values scroll
;           left (shifting the tiles right)
;====
.macro "tilemap.adjustXPixels"
    call tilemap._adjustXPixels
.endm

;====
; Adjusts the buffered tilemap yScroll value by a given number of pixels. If this
; results in a new row needing to be drawn it sets flags in RAM indicating
; whether the top or bottom rows need reloading. You can interpret these flags
; using tilemap.ifRowScroll.
;
; The scroll value won't apply until you call tilemap.writeScrollRegisters
;
; @in   a   the number of y pixels to adjust. Positive values scroll down in
;           the game world (shifting the tiles up). Negative values scroll
;           up (shifting the tiles down)
;====
.macro "tilemap.adjustYPixels"
    call tilemap._adjustYPixels
.endm

;====
; When tilemap.ifRowScroll indicates an up scroll, but you detect this new row
; will be out of bounds of the tilemap, call this to cap the y pixel scrolling
; to the top of the current in-bounds row. Further calls to tilemap.ifRowScroll
; will indicate that no row scroll is required and thus prevent rendering an
; invalid row.
;
; Note: This should be called before calling tilemap.calculateScroll
;====
.section "tilemap.stopUpRowScroll" free
    tilemap.stopUpRowScroll:
        ; Reset UP scroll flag
        ld a, (tilemap.ram.flags)           ; load flags
        and tilemap.SCROLL_Y_RESET_MASK     ; reset Y scroll flags
        ld (tilemap.ram.flags), a           ; store updated flags

        ; Round yScrollBuffer to top of previous row
        ld a, (tilemap.ram.yScrollBuffer)   ; load current value
        add 8                               ; add 8px to go back down one row

        ; Ensure value hasn't gone out of 0-223 range
        cp tilemap.Y_PIXELS
        jp c, +
            ; Sub screen height to bring back into range (i.e. 224 becomes 0)
            sub tilemap.Y_PIXELS
        +:

        and %11111000                       ; round to top pixel of that row
        ld (tilemap.ram.yScrollBuffer), a   ; update yScrollBuffer

        ret
.ends

;====
; Alias to call tilemap.stopUpRowScroll
;====
.macro "tilemap.stopUpRowScroll"
    call tilemap.stopUpRowScroll
.endm

;====
; When tilemap.ifRowScroll indicates a down scroll, but you detect this new row
; will be out of bounds of the tilemap, call this to cap the y pixel scrolling
; to the top of the current in-bounds row. Further calls to tilemap.ifRowScroll
; will indicate that no row scroll is required and thus prevent rendering an
; invalid row.
;
; Note: This should be called before calling tilemap.calculateScroll
;====
.section "tilemap.stopDownRowScroll" free
    tilemap.stopDownRowScroll:
        ; Reset Y scroll flags
        ld a, (tilemap.ram.flags)           ; load flags
        and tilemap.SCROLL_Y_RESET_MASK     ; reset Y scroll flags
        ld (tilemap.ram.flags), a           ; store updated flags

        ; Adjust yScrollBuffer to point to bottom pixel of previous row
        ld a, (tilemap.ram.yScrollBuffer)   ; load current value
        sub 8                               ; sub 8px to go back up one row

        ; Ensure value hasn't gone out of 0-223 range
        jp nc, +
            ; Value dropped below 0 - bring back into range
            add tilemap.Y_PIXELS            ; -1 becomes 223
        +:

        ; Round yScrollBuffer to bottom pixel of the row
        or %00000111                        ; set bits 0-2
        ld (tilemap.ram.yScrollBuffer), a   ; store result

        ret
.ends

;====
; Alias to call tilemap.stopDownRowScroll
;====
.macro "tilemap.stopDownRowScroll"
    call tilemap.stopDownRowScroll
.endm

;====
; When tilemap.ifColScroll indicates a left scroll, but you detect this new row
; will be out of bounds of the tilemap, call this to cap the x pixel scrolling
; to the left edge of the current in-bounds column. Further calls to
; tilemap.ifColScroll will indicate that no column scroll is required and thus
; prevent rendering an invalid column.
;
; Note: This should be called before calling tilemap.calculateScroll
;====
.section "tilemap.stopLeftColScroll" free
    tilemap.stopLeftColScroll:
        ; Reset column scroll flags
        ld a, (tilemap.ram.flags)           ; load flags
        and tilemap.SCROLL_X_RESET_MASK     ; reset x scroll flags
        ld (tilemap.ram.flags), a           ; store updated flags

        ; Round xScrollBuffer to left of previous column
        ld a, (tilemap.ram.xScrollBuffer)   ; load current scroll value
        add 8                               ; go right one column
        and %11111000                       ; set to left-most pixel of the col
        ld (tilemap.ram.xScrollBuffer), a   ; update xScrollBuffer

        ret
.ends

;====
; Alias to call tilemap.stopLeftColScroll
;====
.macro "tilemap.stopLeftColScroll"
    call tilemap.stopLeftColScroll
.endm

;====
; When tilemap.ifColScroll indicates a right scroll, but you detect this new row
; will be out of bounds of the tilemap, call this to cap the x pixel scrolling
; to the right edge of the current in-bounds column. Further calls to
; tilemap.ifColScroll will indicate that no column scroll is required and thus
; prevent rendering an invalid column.
;
; Note: This should be called before calling tilemap.calculateScroll
;====
.section "tilemap.stopRightColScroll" free
    tilemap.stopRightColScroll:
        ; Reset column scroll flags
        ld a, (tilemap.ram.flags)           ; load flags
        and tilemap.SCROLL_X_RESET_MASK     ; reset x scroll flags
        ld (tilemap.ram.flags), a           ; store updated flags

        ; Round xScrollBuffer to right of previous column
        ld a, (tilemap.ram.xScrollBuffer)   ; load current scroll value
        sub 8                               ; go left one column
        or %00000111                        ; set to right-most pixel of the col
        ld (tilemap.ram.xScrollBuffer), a   ; update xScrollBuffer

        ret
.ends

;====
; Alias to call tilemap.stopRightColScroll
;====
.macro "tilemap.stopRightColScroll"
    call tilemap.stopRightColScroll
.endm

;====
; Calculates the adjustments made with tilemap.adjustXPixels/adjustYPixels
; and applies them to the RAM variables
;====
.macro "tilemap.calculateScroll"
    call tilemap._calculateScroll
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

;====
; Jumps to the relevant label if a column scroll is needed after a call to
; tilemap.adjustXPixels. Must be called with either 3 arguments (left, right, else)
; or just else alone
;
; @in   left    (optional) continue to this label if left column needs loading
; @in   right   (optional) jump to this label if the right column needs loading
; @in   else    jump to this label if no columns need loading
;====
.macro "tilemap.ifColScroll" args left, right, else
    .if NARGS == 1
        ; Only one argument passed ('else' label)
        ld a, (tilemap.ram.flags)   ; load flags
        rlca                        ; set C to 7th bit
        jp nc, \1                   ; jp to else if no col to scroll
        ; ...otherwise continue
    .elif NARGS == 3
        ; 3 arguments passed (left, right, else)
        ld a, (tilemap.ram.flags)   ; load flags
        rlca                        ; set C to 7th bit
        jp nc, else                 ; jp to else if no col to scroll (bit 7 was 0)

        ; Check right scroll flag
        rlca                        ; set C to what was 6th bit
        jp nc, right                ; jp if scrolling right (bit 6 was 0)
        ; ...otherwise continue to left label
    .else
        .print "\ntilemap.ifColScroll requires 1 or 3 arguments (left/right/else, or just else alone)\n\n"
        .fail
    .endif
.endm

;====
; Returns if no column scroll is needed, otherwise jumps to the relevant
; 'left' or 'right' label depending on the column scroll direction
;
; @in   left    if scrolling left, will continue to this label
; @in   right   if scrolling right, will jump to this label
;====
.macro "tilemap.ifColScrollElseRet" args left, right
    .if NARGS != 2
        .print "\ntilemap.ifColScrollElseRet requires 2 arguments (left and right)\n\n"
        .fail
    .endif

    ld a, (tilemap.ram.flags)   ; load flags
    rlca                        ; set C to 7th bit
    ret nc                      ; return if no column to scroll (bit 7 was 0)

    ; Check right scroll flag
    rlca                        ; set C to what was 6th bit
    jp nc, right                ; jp if scrolling right (bit 6 was 0)
    ; ...otherwise continue to 'left' label
.endm

;====
; Jumps to the relevant label if a row scroll is needed after a call to
; tilemap.adjustYPixels. Must be called with either 3 arguments (up, down, else)
; or just else alone
;
; @in   up      (optional) continue to this label if top row needs loading
; @in   down    (optional) jump to this label if the bottom row needs loading
; @in   else    jump to this label if no columns need loading
;====
.macro "tilemap.ifRowScroll" args up, down, else
    .if NARGS == 1
        ; Only one argument passed ('else' label)
        ld a, (tilemap.ram.flags)   ; load flags
        rrca                        ; set C to bit 0
        jp nc, \1                   ; jp to else if no row scroll (bit 0 was 0)
        ; ...otherwise continue
    .elif NARGS == 3
        ld a, (tilemap.ram.flags)   ; load flags
        rrca                        ; set C to bit 0
        jp nc, else                 ; no row to scroll (bit 0 was 0)

        ; Check down scroll flag
        rrca                        ; set C to what was bit 1
        jp c, down                  ; jp if scrolling down (bit 1 was set)
        ; ...otherwise continue to 'up' label
    .else
        .print "\ntilemap.ifRowScroll requires 1 or 3 arguments (up/down/else, or just else alone)\n\n"
        .fail
    .endif
.endm

;====
; Returns if no row scroll is needed, otherwise jumps to the relevant
; 'up' or 'down' label depending on the row scroll direction
;
; @in   up      if scrolling up, will continue to this label
; @in   down    if scrolling down, will jump to this label
;====
.macro "tilemap.ifRowScrollElseRet" args up, down
    .if NARGS != 2
        .print "\ntilemap.ifRowScrollElseRet requires 2 arguments (up and down)\n\n"
        .fail
    .endif

    ld a, (tilemap.ram.flags)               ; load flags
    rrca                                    ; set C to bit 0
    ret nc                                  ; return if no row to scroll

    ; Check down scroll flag
    rrca                                    ; set C to what was bit 1
    jp c, down                              ; jp if down scroll (bit 1 was set)
    ; ...otherwise continue to 'up' label
.endm

;====
; Sends the buffered scroll register values to the VDP. This should be called
; when the display is off or during a V or H interrupt
;====
.macro "tilemap.writeScrollRegisters"
    ld a, (tilemap.ram.xScrollBuffer)
    neg
    utils.vdp.setRegister utils.vdp.SCROLL_X_REGISTER

    ld a, (tilemap.ram.yScrollBuffer)
    utils.vdp.setRegister utils.vdp.SCROLL_Y_REGISTER
.endm

;====
; Sets the VRAM write address to the row that requires updating. If no row needs
; scrolling, the write address will be set to the last row scrolled
;
; @out  VRAM write address  write address for the row (column 0)
; @out  c                   VDP data port
;====
.macro "tilemap.setRowScrollSlot"
    ld hl, (tilemap.ram.vramRowWrite)
    utils.vdp.prepWriteHL
.endm

;====
; Write tile data to the scrolling column in VRAM, if required. The data should
; be a sequential list of tiles starting with top of the column visible on screen
;
; @in   dataAddr    (optional) pointer to the sequential tile data (top of the
;                   column). Defaults to the internal column buffer
;====
.macro "tilemap._writeScrollCol" isolated args dataAddr
    ; Calculate the column bits for the write address
    ; If no col scroll needed, skip to _continue
    tilemap.ifColScroll, _left, _right, _continue
        _left:
            ld a, (tilemap.ram.xScrollBuffer)   ; load X scroll
            add 8                               ; go right 1 column to correct
            and %11111000                       ; floor value to nearest 8
            rrca                                ; divide by 2
            rrca                                ; divide by 2 again (4)
            ; We would need to divide by 2 again (8 total) then multiply by 2
            ; as there are 2 bytes per tile, but these operations cancel each
            ; other out and so aren't required
            jp +
        _right:
            ld a, (tilemap.ram.xScrollBuffer)   ; load X scroll
            and %11111000                       ; floor value to nearest 8
            rrca                                ; divide by 2
            rrca                                ; divide by 2 again (4)
            ; We would need to divide by 2 again (8 total) then multiply by 2
            ; as there are 2 bytes per tile, but these operations cancel each
            ; other out and so aren't required
    +:

    ;===
    ; Prep the call to the address stored in tilemap.ram.colWriteCall, which
    ; points to an iteration of tilemap._loadColumn
    ;===

    ; Set E to column address bits
    ld e, a

    ; Set D to column bits ORed with 128, as required by tilemap._loadColumn
    or 128  ; OR A by 128 to combine bits
    ld d, a ; set D to value

    ; Set B to bytes to write (tilemap.COL_SIZE_BYTES), and C to tilemap.VDP_DATA_PORT
    ld bc, (tilemap.COL_SIZE_BYTES * 256) + tilemap.VDP_DATA_PORT

    ; Set HL to the tile data to write
    .ifdef dataAddr
        ld hl, dataAddr
    .else
        ld hl, tilemap.ram.colBuffer
    .endif

    ; Call (tilemap.ram.colWriteCall); This points to an iteration of
    ; tilemap._loadColumn
    ld iy, (tilemap.ram.colWriteCall)
    call tilemap._callIY

    _continue:
.endm

;====
; Update the scroll registers and send the necessary col/row data to VRAM. This
; should be called when the display is off or during VBlank
;====
.macro "tilemap.writeScrollBuffers"
    call tilemap.writeScrollBuffers
.endm

;====
; See tilemap.writeScrollBuffers macro alias
;====
.section "tilemap.writeScrollBuffers" free
    tilemap.writeScrollBuffers:
        ; Set scroll registers
        tilemap.writeScrollRegisters

        ; Write column tiles from buffer to VRAM if required
        tilemap._writeScrollCol

        ; Detect whether the row buffer should be flushed
        tilemap.ifRowScroll +
            ; Set VRAM address to the scrolling row
            ; Set C to the VDP output port
            tilemap.setRowScrollSlot

            ;===
            ; First write
            ; Set B to bytes to write minus floor(xScroll / 4)
            ; Set HL to end of the buffer minus bytes to write
            ;===
            _firstWrite:
                ld h, >tilemap.ram.rowBuffer    ; set H to high byte of rowBuffer
                ld a, (tilemap.ram.xScrollBuffer)
                sub tilemap.X_OFFSET    ; cancel X offset
                rrca                    ; divide by 2
                rrca                    ; divide by 2 (4 total)
                and %00111110           ; clean value; now equals col * 2 bytes
                ld e, a                 ; preserve result in E
                jp z, _secondWrite      ; skip if the are no bytes in first write
                ld b, a                 ; set B to bytes to write

                ; Set A to the last byte of the buffer
                ld a, <(tilemap.ram.rowBuffer + tilemap.ROW_SIZE_BYTES)

                ; Subtract bytes we need to write
                sub b

                ; Point HL to end of buffer minus bytes
                ld l, a

                ; Copy bytes from buffer to VDP
                call utils.outiBlock.sendUpTo128Bytes

            ;===
            ; Second write
            ; Set B to ROW_SIZE_BYTES minus bytes outputted in first write
            ; Set HL to start of rowBuffer
            ;===
            _secondWrite:
                ; Set HL to start of rowBuffer; No need to update H as the data
                ; is aligned
                ld l, <(tilemap.ram.rowBuffer)  ; set L to low byte of rowBuffer

                ; Bytes to write
                ld a, tilemap.ROW_SIZE_BYTES
                sub e       ; subtract bytes written in first write

                ; Write bytes then return to caller
                ld b, a     ; set B to bytes to write
                jp utils.outiBlock.sendUpTo128Bytes
        +:

        ret
.ends

;====
; Private/internal functions
;====

;====
; See tilemap.adjustXPixels
;
; @in   a   the number of x pixels to adjust. Positive values scroll right in
;           the game world (shifting the tiles left). Negative values scroll
;           left (shifting the tiles right)
;====
.section "tilemap._adjustXPixels" free
    tilemap._adjustXPixels:
        or a                                ; analyse A
        jp z, _noColumnScroll               ; if adjust is zero, no scroll needed
        ld hl, tilemap.ram.xScrollBuffer    ; point to xScrollBuffer
        ld b, (hl)                          ; load current xScrollBuffer into B
        jp p, _movingRight                  ; jump if xAdjust is positive

        _movingLeft:
            ; Adjust xScrollBuffer
            add a, b                        ; add xAdjust to xScrollBuffer
            ld (hl), a                      ; store new xScrollBuffer

            ; Detect if left column needs updating (if upper 5 bits change)
            xor b                           ; compare bits with old value in B
            and %11111000                   ; zero all but upper 5 bits
            jp z, _noColumnScroll           ; jp if zero (upper 5 bits were the same)

            ; Left column needs scrolling
            inc hl                          ; point to flags
            ld a, (hl)                      ; load flags into A
            or tilemap.SCROLL_LEFT_SET_MASK ; set left scroll flags
            ld (hl), a                      ; store flags
            ret

        _movingRight:
            ; Adjust xScrollBuffer
            add a, b                        ; add xAdjust to xScrollBuffer
            ld (hl), a                      ; store new xScrollBuffer

            ; Detect if right column needs updating (if upper 5 bits change)
            xor b                           ; compare bits with old value in B
            and %11111000                   ; zero all but upper 5 bits
            jp z, _noColumnScroll           ; jp if zero (upper 5 bits were the same)

            ; Right column needs scrolling
            inc hl                          ; point to flags
            ld a, (hl)                      ; load flags into A
            and tilemap.SCROLL_X_RESET_MASK ; reset previous x scroll flags
            or tilemap.SCROLL_RIGHT_SET_MASK; set right scroll flag
            ld (hl), a                      ; store flags
            ret

    ; No scroll needed
    _noColumnScroll:
        ld hl, tilemap.ram.flags
        ld a, tilemap.SCROLL_X_RESET_MASK
        and (hl)            ; reset X scroll flags with mask
        ld (hl), a          ; update flags
        ret
.ends

;====
; See tilemap.adjustYPixels macro
;
; - Updates tilemap.ram.flags with relevant up/down scroll flags
;
; @in   a   the number of y pixels to adjust. Positive values scroll down in
;           the game world (shifting the tiles up). Negative values scroll
;           up (shifting the tiles down)
;====
.section "tilemap._adjustYPixels" free
    tilemap._adjustYPixels:
        or a                    ; analyse yAdjust
        jp z, _noRowScroll      ; jump if nothing to adjust

        ld hl, tilemap.ram.yScrollBuffer    ; point to yScrollBuffer
        ld c, (hl)              ; load current yScrollBuffer into C
        jp p, _movingDown       ; jump to _movingDown if yAdjust is positive

    _movingUp:
        add a, c                ; add yAdjust to yScrollBuffer
        cp tilemap.Y_PIXELS     ; check if value has gone out of range
        jp c, +
            ; Value is out of range
            sub 256 - tilemap.Y_PIXELS  ; bring into range (i.e. -1/255 becomes 223)
            ld (hl), a                  ; store new yScrollBuffer

            ; Check if scroll needed
            xor c                   ; compare yScrollBuffer against old value in C
            and %11111000           ; zero lower bits (we only care about upper 5)
            jp z, _noRowScroll      ; scroll if not zero (upper 5 bits are different)

            ; Update scroll flags
            ld hl, tilemap.ram.flags        ; point to flags
            ld a, (hl)                      ; load flags into A
            and tilemap.SCROLL_Y_RESET_MASK ; reset previous y scroll flags
            or tilemap.SCROLL_UP_SET_MASK   ; set new scroll flag
            ld (hl), a                      ; store result
            ret
        +:

        ; Value is in range
        ld (hl), a                          ; store new yScrollBuffer

        ; If upper 5 bits change, row scroll needed
        xor c                   ; compare yScrollBuffer against old value in C
        and %11111000           ; zero lower bits (we only care about upper 5)
        jp z, _noRowScroll      ; jump if zero (if upper 5 bits are the same)

        ; Update scroll flags
        dec hl                          ; point to flags
        ld a, (hl)                      ; load flags into A
        and tilemap.SCROLL_Y_RESET_MASK ; reset previous y scroll flags
        or tilemap.SCROLL_UP_SET_MASK   ; set new scroll flag
        ld (hl), a                      ; store result
        ret

    _movingDown:
        add a, c                    ; add yAdjust to yScrollBuffer
        cp tilemap.Y_PIXELS         ; check if value has gone out of range
        jp c, +
            ; Value is out of range
            sub tilemap.Y_PIXELS    ; bring back into range (i.e. 224 becomes 0)
            ld (hl), a              ; store new yScrollBuffer

            ; If upper 5 bits change, row scroll needed
            xor c                   ; compare yScrollBuffer against old value in C
            and %11111000           ; zero lower bits (we only care about upper 5)
            jp z, _noRowScroll      ; scroll if not zero (upper 5 bits are different)

            ; Update scroll flags
            ld hl, tilemap.ram.flags        ; point to flags
            ld a, (hl)                      ; load flags into A
            or tilemap.SCROLL_DOWN_SET_MASK ; update scroll flag
            ld (hl), a                      ; store result
            ret
        +:

        ; Value is in range
        ld (hl), a              ; store new yScrollBuffer

        ; If upper 5 bits change, row scroll needed
        xor c                   ; compare yScrollBuffer against old value in C
        and %11111000           ; zero lower bits (we only care about upper 5)
        jp z, _noRowScroll      ; scroll if not zero (upper 5 bits are different)

        ; Update scroll flags
        dec hl                          ; point to flags
        ld a, (hl)                      ; load flags into A
        or tilemap.SCROLL_DOWN_SET_MASK ; update scroll flag
        ld (hl), a                      ; store result
        ret

    _noRowScroll:
        ld hl, tilemap.ram.flags
        ld a, tilemap.SCROLL_Y_RESET_MASK
        and (hl)            ; reset Y scroll flags with mask
        ld (hl), a          ; update flags
        ret
.ends

;====
; Calculates the adjustments made with tilemap.adjustXPixels/adjustYPixels
; and applies them to the RAM variables.
;
; Sets tilemap.ram.vramRowWrite to the VRAM write address if up/down scroll
; flags are set, otherwise it's left unchanged
;====
.section "tilemap._calculateScroll" free
    tilemap._calculateScroll:
        ld a, (tilemap.ram.flags)   ; load scroll flags in A
        ld c, a                     ; preserve flags in C

    _updateRowScroll:
        ; Check Y scroll flag
        rrca                        ; set C to bit 0
        jp nc, _updateColScroll     ; bit 0 was 0; no rows to scroll

        ; Check down scroll
        rrca                        ; set C to what was bit 1
        jp c, _scrollingDown        ; jp if bit 1 was 1 (scrolling down)

        _scrollingUp:
            ; Set row to vramRow; Set col to 0
            ld a, (tilemap.ram.yScrollBuffer)   ; load scroll value

            ; Divide by 8 (3x rrca) and rotate right twice (2x rrca)
            ; 3x rlca (left rotate) is equivalent to 5x rrca (right rotate)
            rlca
            rlca
            rlca                    ; value is now y1y0---y4y3y2

            ld b, a                 ; preserve in B
            and %00000111           ; mask y4,y3,y2
            or %01000000 | >tilemap.vramAddress    ; set base address + write command
            ld h, a                 ; store in H
            ld a, b                 ; restore rotated Y (y1y0---y4y3y2)
            and %11000000           ; mask y1y0
            ld l, a                 ; store in L
            ld (tilemap.ram.vramRowWrite), hl   ; set vramRowWrite
            jp _updateColScroll

        _scrollingDown:
            ; Set col to 0; Set row to (vramRow + 24) mod total rows;
            ld a, (tilemap.ram.yScrollBuffer)
            rrca                    ; divide by 2
            rrca                    ; ...divide by 4
            rrca                    ; ...divide by 8 - lower 5 bits is now row number
            and %00011111           ; floor result

            ; Calculate bottom visible row
            add tilemap.MIN_VISIBLE_ROWS
            cp tilemap.ROWS         ; compare against number of rows
            jp c, ++
                ; Row number has overflowed max value - wrap value
                sub tilemap.ROWS
            ++:

            rrca                    ; rotate row/y right
            rrca                    ; rotate right again (y1y0---y4y3y2)
            ld b, a                 ; preserve in B
            and %00000111           ; mask y4,y3,y2
            or %01000000 | >tilemap.vramAddress ; add base address + write command
            ld h, a                 ; store in H
            ld a, b                 ; restore rotated Y (y1y0---y4y3y2) into A
            and %11000000           ; mask y1y0
            ld l, a                 ; store in L
            ld (tilemap.ram.vramRowWrite), hl   ; set vramRowWrite
            ; ... continue to _updateColScroll
        +:

    ;===
    ; @in   c   scroll flags
    ;===
    _updateColScroll:
        ; Check left or right scroll
        ld a, c         ; load flags into A
        rlca            ; set C to bit 7
        ret nc          ; if bit 7 was 0, no column scroll needed

        ; Get top row (yScroll / 8), multiplied by 2 bytes per lookup item
        ld a, (tilemap.ram.yScrollBuffer)
        rrca            ; divide by 2
        rrca            ; divide by 2 again. Bits 1-5 now equal row * 2
        and %00111110   ; clean value

        ; Point HL to item in lookup table
        ld hl, tilemap._loadColumnLookup
        add l           ; add L to row offset in A
        ld l, a         ; store result in L

        ; Set HL to (HL)
        ld a, (hl)      ; load low byte into A
        inc l           ; point to high byte
        ld h, (hl)      ; load high byte into H
        ld l, a         ; load low byte into L

        ; Save colWriteCall
        ld (tilemap.ram.colWriteCall), hl
        ret
.ends

;====
; Unrolled loop of column tile writes. Call one of the addresses stored in the
; tilemap._loadColumnLookup lookup table to start from a given row. The loop
; will wrap back to 0 after the 28th tile is written and continue until all
; bytes are written
;
; @in   hl  pointer to sequential tile data
; @in   b   bytes to write (number of rows * 2)
; @in   d   column number * 2 ORed with 128
; @in   e   column number * 2
;====
.section "tilemap._loadColumn" free
    tilemap._loadColumn:
        .repeat tilemap.ROWS index rowNumber
            ; Calculate write address for column 0
            .redefine tilemap._loadColumn_writeAddress ($4000 | tilemap.vramAddress) + (rowNumber * tilemap.COLS * tilemap.TILE_SIZE_BYTES)
            .redefine tilemap._loadColumn_writeAddressHigh >tilemap._loadColumn_writeAddress
            .redefine tilemap._loadColumn_writeAddressLow <tilemap._loadColumn_writeAddress

            ; Calculate VRAM low byte write address (0, 64, 128, 192)
            .if tilemap._loadColumn_writeAddressLow == 0
                ; Row address low byte is 0; Just set A to column address
                ld a, e ; set A to column address
            .elif tilemap._loadColumn_writeAddressLow == 128
                ; Row address low byte is 128; This value (and col address) is cached in D
                ld a, d
            .else
                ; Set A to low address
                ld a, tilemap._loadColumn_writeAddressLow

                ; Set column address bits
                or e
            .endif

            ; Set VRAM low byte write address
            out (utils.vdp.VDP_COMMAND_PORT), a

            ; Set VRAM high byte write address
            ld a,  tilemap._loadColumn_writeAddressHigh ; set A to high address
            out (utils.vdp.VDP_COMMAND_PORT), a         ; send to VDP

            ; Output tile
            outi    ; pattern ref
            outi    ; tile attributes
            ret z   ; return if no more tiles to output (B = 0)
        .endr

        jp tilemap._loadColumn ; continue from row 0
.ends

;====
; Lookup table for the loop iterations in tilemap._loadColumn
; Usage: load HL with tilemap._loadColumnLookup then add row * 2 to L; HL will
; then point to the address to call in the loop
;=====
.section "tilemap._loadColumnLookup" free bitwindow 8
    tilemap._loadColumnLookup:
        ; The offset to the current tilemap._loadColumn iteration
        .redefine tilemap._loadColumnLookup_currentOffset 0

        ; Iterate over each potential row, starting from 0
        .repeat tilemap.ROWS index rowNumber
            ; Set address of the row iteration in tilemap._loadColumn
            .dw tilemap._loadColumn + tilemap._loadColumnLookup_currentOffset

            ; Update offset to next iteration
            .if rowNumber # 2 == 0
                ; Every second iteration uses additional optimisations, so we
                ; only need to increase the offset by 12 bytes
                .redefine tilemap._loadColumnLookup_currentOffset tilemap._loadColumnLookup_currentOffset + 12
            .else
                ; Increase offset by 14 bytes
                .redefine tilemap._loadColumnLookup_currentOffset tilemap._loadColumnLookup_currentOffset + 14
            .endif
        .endr
.ends

;====
; Calls the address stored in IY
;
; @in   iy  the address to call
;====
.section "tilemap._callIY" free
    tilemap._callIY:
        jp (iy)
.ends
