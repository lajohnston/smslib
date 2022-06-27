;====
; Tilemap
;
; Each tile in the tilemap consists of 2-bytes which describe which pattern to
; use and which modifier attributes to apply to it, such as flipping, layer and
; color palette
;====

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

.include "./utils/ram.asm"

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
.define tilemap.VISIBLE_ROWS 24
.define tilemap.VISIBLE_COLS 32 ; note: includes the hidden left-most column
.define tilemap.Y_PIXELS tilemap.ROWS * 8

.define tilemap.TILE_SIZE_BYTES 2
.define tilemap.COL_SIZE_BYTES tilemap.VISIBLE_ROWS * tilemap.TILE_SIZE_BYTES
.define tilemap.ROW_SIZE_BYTES tilemap.COLS * 2

; Bit locations of flags within tilemap.ram.flags
.define tilemap.SCROLL_UP_PENDING_BIT       0
.define tilemap.SCROLL_DOWN_PENDING_BIT     1
.define tilemap.SCROLL_LEFT_PENDING_BIT     2
.define tilemap.SCROLL_RIGHT_PENDING_BIT    3

; AND masks to reset the scroll flags for a given axis
.define tilemap.X_SCROLL_RESET_MASK %11110011
.define tilemap.Y_SCROLL_RESET_MASK %11111100

; OR masks to set the scroll flags
.define tilemap.SCROLL_UP_SET_MASK      %00000001
.define tilemap.SCROLL_DOWN_SET_MASK    %00000010
.define tilemap.SCROLL_LEFT_SET_MASK    %00000100
.define tilemap.SCROLL_RIGHT_SET_MASK   %00001000

;====
; RAM
;====
.ramsection "tilemap.ram" slot utils.ram.SLOT
    tilemap.ram.xScrollBuffer:  db  ; VDP x-axis scroll register buffer
    tilemap.ram.flags:          db  ; see constants for flag definitions
    tilemap.ram.yScrollBuffer:  db  ; VDP y-axis scroll register buffer

    ; VRAM write command/address for row scrolling
    tilemap.ram.vramRowWrite:   dw
.ends

;====
; Reset the RAM buffers and scroll values to 0
;====
.macro "tilemap.reset"
    ; Zero values
    xor a   ; set A to 0
    ld (tilemap.ram.xScrollBuffer), a
    ld (tilemap.ram.flags), a
    ld (tilemap.ram.yScrollBuffer), a

    ld (tilemap.ram.vramRowWrite), a
    ld (tilemap.ram.vramRowWrite + 1), a

    ; Zero scroll registers
    tilemap.updateScrollRegisters
.endm

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
; Alias for tilemap.loadRows
;====
.macro "tilemap.loadRows"
    call tilemap.loadRows
.endm

;====
; See tilemap.adjustXPixels
;
; @in   a   the number of x pixels to adjust. Positive values scroll right in
;           the game world (shifting the tiles left). Negative values scroll
;           left (shifting the tiles right)
;====
.section "tilemap._adjustXPixels" free
    tilemap._adjustXPixels:
        neg                     ; negate A so positive values scroll right
        jp z, _noColumnScroll   ; if adjust is zero, no scroll needed

        ; Add xAdjust to current xScrollBuffer
        ld hl, tilemap.ram.xScrollBuffer
        ld b, a                 ; preserve xAdjust in B
        ld c, (hl)              ; load xScrollBuffer in C
        add a, c                ; add xAdjust to xScrollBuffer
        ld (hl), a              ; store result

        ; Check if col scroll needed (if upper 5-bits change; every 8 pixels)
        xor c                   ; compare xScrollBuffer against old value in C
        and %11111000           ; zero lower bits (we only care about upper 5)
        jp nz, _columnScroll    ; scroll if not zero (upper 5 bits are different)

        ; No scroll needed
        _noColumnScroll:
            ld hl, tilemap.ram.flags
            ld a, tilemap.X_SCROLL_RESET_MASK
            and (hl)            ; reset X scroll flags with mask
            ld (hl), a          ; update flags
            ret

        ; Set left or right column scroll flag
        _columnScroll:
            inc hl                          ; point to flags
            ld a, (hl)                      ; load flags into A
            and tilemap.X_SCROLL_RESET_MASK ; reset previous x scroll flags

            bit 7, b            ; check sign bit of (negated) xAdjust in B
            jp z, +
                ; xAdjust was positive - scroll right
                or tilemap.SCROLL_RIGHT_SET_MASK
                ld (hl), a
                ret
            +:

            ; xAdjust was negative - scroll left
            or tilemap.SCROLL_LEFT_SET_MASK
            ld (hl), a
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
            sub 255 - tilemap.Y_PIXELS  ; bring into range (i.e. -1/255 becomes 223)
            ld (hl), a                  ; store new yScrollBuffer

            ; Check if scroll needed
            xor c                   ; compare yScrollBuffer against old value in C
            and %11111000           ; zero lower bits (we only care about upper 5)
            jp z, _noRowScroll      ; scroll if not zero (upper 5 bits are different)

            ; Update scroll flags
            ld hl, tilemap.ram.flags        ; point to flags
            ld a, (hl)                      ; load flags into A
            and tilemap.Y_SCROLL_RESET_MASK ; reset previous y scroll flags
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
        and tilemap.Y_SCROLL_RESET_MASK ; reset previous y scroll flags
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

            ; Check if row scroll needed. Offset by 1 to bring into 0-7 range
            ; If upper 5 bits change, row scroll needed
            dec a                   ; offset a
            dec c                   ; offset c
            xor c                   ; compare yScrollBuffer against old value in C
            and %11111000           ; zero lower bits (we only care about upper 5)
            jp z, _noRowScroll      ; scroll if not zero (upper 5 bits are different)

            ; Update scroll flags
            ld hl, tilemap.ram.flags        ; point to flags
            ld a, (hl)                      ; load flags into A
            and tilemap.Y_SCROLL_RESET_MASK ; reset previous y scroll flags
            or tilemap.SCROLL_DOWN_SET_MASK ; set new scroll flag
            ld (hl), a                      ; store result
            ret
        +:

        ; Value is in range
        ld (hl), a              ; store new yScrollBuffer

        ; Check if row scroll needed. Offset by 1 to bring into 0-7 range
        ; If upper 5 bits change, row scroll needed
        dec a                   ; offset a
        dec c                   ; offset c
        xor c                   ; compare yScrollBuffer against old value in C
        and %11111000           ; zero lower bits (we only care about upper 5)
        jp z, _noRowScroll      ; scroll if not zero (upper 5 bits are different)

        ; Update scroll flags
        dec hl                  ; point to flags
        ld a, (hl)                      ; load flags into A
        and tilemap.Y_SCROLL_RESET_MASK ; reset previous y scroll flags
        or tilemap.SCROLL_DOWN_SET_MASK ; set new scroll flag
        ld (hl), a                      ; store result
        ret

    _noRowScroll:
        ld hl, tilemap.ram.flags
        ld a, tilemap.Y_SCROLL_RESET_MASK
        and (hl)            ; reset Y scroll flags with mask
        ld (hl), a          ; update flags
        ret
.ends

;====
; Adjusts the buffered tilemap xScroll value by a given number of pixels. If this
; results in a new column needing to be drawn it sets flags in RAM indicating
; whether the left or right column needs reloading. You can interpret these flags
; using tilemap.ifColScroll.
;
; The scroll value won't apply until you call tilemap.updateScrollRegisters
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
; The scroll value won't apply until you call tilemap.updateScrollRegisters
;
; @in   a   the number of y pixels to adjust. Positive values scroll down in
;           the game world (shifting the tiles up). Negative values scroll
;           up (shifting the tiles down)
;====
.macro "tilemap.adjustYPixels"
    call tilemap._adjustYPixels
.endm

;====
; Calculates the adjustments made with tilemap.adjustXPixels/adjustYPixels
; and applies them to the RAM variables.
;
; Sets tilemap.ram.vramRowWrite to the VRAM write address if up/down scroll
; flags are set, otherwise it's left unchanged
;====
.section "tilemap._prepScroll" free
    tilemap._prepScroll:
        ld a, (tilemap.ram.flags)   ; load scroll flags in A
        ld c, a                     ; preserve flags in C

    _updateRowScroll:
        ; Check UP scroll
        bit tilemap.SCROLL_UP_PENDING_BIT, c
        jp z, +
            ; Scrolling up - set row to vramRow, and col to 0
            ld a, (tilemap.ram.yScrollBuffer)   ; load scroll value

            ; Divide by 8 (3x rrca) and rotate right twice (2x rrca)
            ; 5x rrca is equivalent to 3x rlca
            rlca
            rlca
            rlca                    ; value is now y1y0---y4y3y2

            ld b, a                 ; preserve in B
            and %00000111           ; mask y4,y3,y2
            or %01000000 | >tilemap.vramAddress    ; add base address + write command
            ld h, a                 ; store in H
            ld a, b                 ; restore rotated Y (y1y0---y4y3y2)
            and %11000000           ; mask y1y0
            ld l, a                 ; store in L
            ld (tilemap.ram.vramRowWrite), hl   ; set vramRowWrite
            ret
        +:

        ; Check down scroll
        bit tilemap.SCROLL_DOWN_PENDING_BIT, c
        jp z, +
            ; Scrolling down
            ; Set col to 0; Set row to (vramRow + 24) mod total rows;
            ld a, (tilemap.ram.yScrollBuffer)
            rrca                    ; divide by 2
            rrca                    ; ...divide by 4
            rrca                    ; ...divide by 8 - lower 5 bits is now row number
            and %00011111           ; floor result
            add tilemap.VISIBLE_ROWS; add screen height to point to bottom row
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
        +:

        ret
.ends

;====
; Calculates the adjustments made with tilemap.adjustXPixels/adjustYPixels
; and applies them to the RAM variables
;====
.macro "tilemap.prepScroll"
    call tilemap._prepScroll
.endm

;====
; Jumps to the relevant label if a column scroll is needed after a call to
; tilemap.adjustXPixels. Must be called with either 3 arguments (left, right, else)
; or just else alone
;
; Example usage:
;
; tilemap.ifColScroll +
;     ; Column is scrolling (left or right)
; +:
;
; tilemap.ifColScroll left, right, +
;     left:
;         ; Handle left scroll
;         jp + ; skip right label
;     right:
;         ; Handle right scroll
; +:
;
; @in   left    (optional) continue to this label if left column needs loading
; @in   right   (optional) jump to this label if the right column needs loading
; @in   else    jump to this label if no columns need loading
;====
.macro "tilemap.ifColScroll" args left, right, else
    .if NARGS == 1
        ; Only one argument passed ('else' label)
        ld a, (tilemap.ram.flags)               ; load flags
        and tilemap.X_SCROLL_RESET_MASK ~ $ff   ; remove other flags (negate reset mask)
        jp z, \1                                ; jp to else label if no column to scroll
        ; ...otherwise continue
    .elif NARGS == 3
        ; 3 arguments passed (left, right, else)
        ld a, (tilemap.ram.flags)               ; load flags
        and tilemap.X_SCROLL_RESET_MASK ~ $ff   ; remove other flags (negate reset mask)
        jp z, else                              ; no column to scroll

        bit tilemap.SCROLL_RIGHT_PENDING_BIT, a ; check right scroll flag
        jp nz, right                            ; jp if scrolling right
        ; ...otherwise continue to left label
    .else
        .print "\ntilemap.ifColScroll requires 1 or 3 arguments (left/right/else, or just else alone)\n\n"
        .fail
    .endif
.endm

;====
; Jumps to the relevant label if a row scroll is needed after a call to
; tilemap.adjustXPixels. Must be called with either 3 arguments (up, down, else)
; or just else alone
;
; Example usage:
;
; tilemap.ifRowScroll +
;     ; Row is scrolling (up or down)
; +:
;
; tilemap.ifRowScroll up, down, +
;     up:
;         ; Handle up scroll
;         jp + ; skip down label
;     down:
;         ; Handle down scroll
; +:
;
; @in   up      (optional) continue to this label if top row needs loading
; @in   down    (optional) jump to this label if the bottom row needs loading
; @in   else    jump to this label if no columns need loading
;====
.macro "tilemap.ifRowScroll" args up, down, else
    .if NARGS == 1
        ; Only one argument passed ('else' label)
        ld a, (tilemap.ram.flags)               ; load flags
        and tilemap.Y_SCROLL_RESET_MASK ~ $ff   ; remove other flags (negate reset mask)
        jp z, \1                                ; jp to else label if no row to scroll
        ; ...otherwise continue
    .elif NARGS == 3
        ld a, (tilemap.ram.flags)
        and tilemap.Y_SCROLL_RESET_MASK ~ $ff   ; remove other flags (negate reset mask)
        jp z, else                              ; no row to scroll

        bit tilemap.SCROLL_DOWN_PENDING_BIT, a
        jp nz, down                             ; scroll down
        ; ...otherwise continue to 'up' label
    .else
        .print "\ntilemap.ifRowScroll requires 1 or 3 arguments (up/down/else, or just else alone)\n\n"
        .fail
    .endif
.endm

;====
; Sends the buffered scroll register values to the VDP. This should be called
; when the display is off or during a V or H interrupt
;====
.macro "tilemap.updateScrollRegisters"
    ld a, (tilemap.ram.xScrollBuffer)
    utils.vdp.setRegister utils.vdp.SCROLL_X_REGISTER

    ld a, (tilemap.ram.yScrollBuffer)
    utils.vdp.setRegister utils.vdp.SCROLL_Y_REGISTER
.endm

;====
; Sets the VRAM write address to the row that needs scrolling. If no row needs
; scrolling will just set the address to the last row scrolled
;
; @out  VRAM write address  write address for the row (column 0)
; @out  c                   VDP data port
;====
.macro "tilemap.setRowScrollSlot"
    ld hl, (tilemap.ram.vramRowWrite)
    utils.vdp.prepWriteHL
.endm
