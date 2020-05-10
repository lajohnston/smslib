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
; Tile attributes
; Combine using OR (|), i.e. tilemap.HIGH_BIT | tilemap.FLIPX
;====

.define tilemap.HIGH_BIT    %00000001   ; 9th bit for the pattern ref, allows refs 256+
.define tilemap.FLIPX       %00000010   ; Flip horizontally
.define tilemap.FLIPY       %00000100   ; Flip vertically
.define tilemap.PALETTE2    %00001000   ; Use palette 2 (sprite palette)

; Place in front of sprites. Color 0 acts as transparent
.define tilemap.PRIORITY    %00010000

; Spare bits - unused by VDP but some games use them to hold custom attributes
.define tilemap.CUSTOM1     %00100000
.define tilemap.CUSTOM2     %01000000
.define tilemap.CUSTOM3     %10000000

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
    smslib.prepVdpWrite (tilemap.vramAddress + (col * 64) + (row * 2))
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
; @in   attributes  (optional) tile attributes to use for all the tiles.
;                   See tile attribute options at top
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
