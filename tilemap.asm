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
.define tilemap.SCREEN_TILE_WIDTH 32
.define tilemap.SLOT_SIZE 2
.define tilemap.VISIBLE_ROWS 25
.define tilemap.ROW_SIZE_BYTES tilemap.SCREEN_TILE_WIDTH * tilemap.SLOT_SIZE

; Bit locations of flags within tilemap.ram.flags
.define tilemap.SCROLL_UP_PENDING_BIT       0
.define tilemap.SCROLL_DOWN_PENDING_BIT     1
.define tilemap.SCROLL_LEFT_PENDING_BIT     2
.define tilemap.SCROLL_RIGHT_PENDING_BIT    3

.define tilemap.X_SCROLL_RESET_MASK %11110011

;====
; RAM
;====
.ramsection "tilemap.ram" slot utils.ram.SLOT
    tilemap.ram.xScrollBuffer:  db  ; VDP x-axis scroll register buffer
    tilemap.ram.flags:          db  ; see constants for flag definitions
.ends

;====
; Reset the RAM buffers and scroll values to 0
;====
.macro "tilemap.reset"
    ; Zero values
    xor a   ; set A to 0
    ld (tilemap.ram.xScrollBuffer), a
    ld (tilemap.ram.flags), a

    ; Zero scroll registers
    tilemap.updateScrollRegisters
.endm

;====
; Set the tile slot ready to write to
;
; @in   slotNumber  0 is top left tile
;====
.macro "tilemap.setSlot" args slotNumber
    utils.vdp.prepWrite (tilemap.vramAddress + (slotNumber * tilemap.SLOT_SIZE))
.endm

;====
; Set the tile slot ready to write to
;
; @in   col     column number (x)
; @in   row     row number (y)
;====
.macro "tilemap.setColRow" args colX rowY
    tilemap.setSlot ((rowY * tilemap.SCREEN_TILE_WIDTH) + colX)
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
.macro "tilemap.loadRawRow"
    ; Output 1 row of data
    utils.outiBlock.send tilemap.ROW_SIZE_BYTES
.endm

;====
; Load tile data from an uncompressed map. Each tile is 2-bytes - the first is
; the tileRef and the second is the tile's attributes.
;
; @in   a   the amount to increment the pointer by each row i.e. the number of
;           columns in the full map * 2 (as each tile is 2-bytes)
; @in   b   number of rows to load
; @in   hl  pointer to the first tile to load
;====
.section "tilemap.loadRawRows"
    _nextRow:
        ld ixh, a               ; preserve A
            utils.math.addHLA   ; add 1 row to full tilemap pointer
        ld a, ixh               ; restore A

    tilemap.loadRawRows:
        push hl                 ; preserve HL
        ld ixl, b               ; preserve B
            tilemap.loadRawRow  ; load a row of data
        ld b, ixl               ; restore B
        pop hl                  ; restore HL

        djnz _nextRow
        ret
.ends

;====
; Alias for tilemap.loadRawRows
;====
.macro "tilemap.loadRawRows"
    call tilemap.loadRawRows
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
        and %11111000           ; zero lower bits (we only care about upper bits)
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
            inc hl              ; point to flags
            bit 7, b            ; check sign bit of (negated) xAdjust in B
            jp z, +
                ; xAdjust was positive - scroll right
                set tilemap.SCROLL_RIGHT_PENDING_BIT, (hl)
                ret
            +:

            ; xAdjust was negative - scroll left
            set tilemap.SCROLL_LEFT_PENDING_BIT, (hl)
            ret
.ends

;====
; Adjusts the buffered tilemap scroll value by a given number of pixels. If this
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
; Jumps to the relevant labels if a column scroll is needed after a call to
; tilemap.adjustXPixels
;
; @in   left    jump to this label if the left column needs loading
; @in   right   jump to this label if the right column needs loading
; @in   else    jump to this label if no columns need loading
;====
.macro "tilemap.ifColScroll" args left, right, else
    ld a, (tilemap.ram.flags)
    and tilemap.X_SCROLL_RESET_MASK ~ $ff   ; remove other flags (negate reset mask)
    jp z, else                              ; no column to scroll

    bit tilemap.SCROLL_RIGHT_PENDING_BIT, a
    jp nz, right                            ; scroll right
    jp left                                 ; otherwise scroll left
.endm

;====
; Sends the buffered scroll register values to the VDP. This should be called
; when the display is off or during a V or H interrupt
;====
.macro "tilemap.updateScrollRegisters"
    ld a, (tilemap.ram.xScrollBuffer)
    utils.vdp.setRegister utils.vdp.SCROLL_X_REGISTER
.endm
