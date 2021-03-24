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

;====
; Set the tile slot ready to write to
;
; @in   col     column number (x)
; @in   row     row number (y)
;====
.macro "tilemap.setSlot" args col row
    utils.vdp.prepWrite (tilemap.vramAddress + (col * 64) + (row * 2))
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
