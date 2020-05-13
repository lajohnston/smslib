;====
; Sprite Buffer
; Manages a sprite table buffer in RAM and transfers it to VRAM
;====
.define sprites.ENABLED 1

;====
; Settings
;
; Define these before including this file if you wish to override the defaults
;====

; The maximum screen y coordinate a sprite can be. Defaults to 192
.ifndef sprites.maxYPos
    .define sprites.maxYPos 192
.endif

; The sprite table's address in VRAM. Defaults to $3f00
.ifndef sprites.vramAddress
    .define sprites.vramAddress $3f00
.endif

;====
; Constants
;====
.define sprites.GROUP_TERMINATOR 255  ; terminates list of sprites.Sprite instances
.define sprites.Y_TERMINATOR $D0

;====
; Sprite buffer
;
; An instance should be placed in RAM at a $xx40 offset and named
; 'sprite.buffer'
;====
.struct "sprites.Buffer"
    yPos:           DSB 64  ; screen yPos for each of the 64 sprites
    xPosAndPattern: DSB 128 ; { 1 byte xPos, 1 byte pattern } * 64 sprites
.endst

;====
; Represents a single sprite. If using sprites.addGroup, more than one can be
; defined in a list terminated with a sprites.GROUP_TERMINATOR byte
;====
.struct "sprites.Sprite"
    relativeX:  db
    relativeY:  db
    pattern:    db
.endst

;====
; Define data for a sprite.Sprite instance
;
; @in   pattern     the pattern number
; @in   relativeX   the relativeX position
; @in   relativeY   the relativeY position
;====
.macro "sprites.sprite" args pattern, relX, relY
    .db relX relY pattern
.endm

;====
; Marks the end of a group of sprites
;====
.macro "sprites.endGroup"
    .db sprites.GROUP_TERMINATOR
.endm

;====
; Adds a sprite to the buffer
;
; @in  de pointer to next available y slot in sprite buffer
; @in  a  screen yPos
; @in  b  screen xPos
; @in  c  pattern number
;
; @clobs af
;====
.section "sprites.add" free
    sprites.add:
        ; Set ypos
        ld (de), a

        ; xPos
        rlc e   ; Switch to xPos (e = e * 2; works because of $xx40 offset)
        ld a, b
        ld (de), a

        ; Pattern
        inc de
        ld a, c
        ld (de), a

        ; Restore de to point back to yPos
        rr e    ; (e - 1) / 2
        inc de  ; point to next free slot
        ret
.ends

;====
; Macro alias for sprites.add
;====
.macro "sprites.add"
    call sprites.add
.endm

;====
; Sets the sprite slot in the buffer ready to add sprites to
;====
.macro "sprites.setSlot" args slot
    ld de, sprites.buffer + slot
.endm

;====
; Marks the end of sprite table so remaining sprites are not processed
;
; @in     de  pointer to next free y position in the buffer
;====
.macro "sprites.end"
    ld a, sprites.Y_TERMINATOR
    ld (de), a
.endm

;====
; Initialises a sprite buffer in RAM
;====
.macro "sprites.init"
    sprites.setSlot 0
    sprites.end ; just set sprite terminator at position 0
.endm

;====
; Copies the sprites.Buffer instance from RAM to VRAM
;====
.macro "sprites.copyToVram"
    ; Copy y positions
    smslib.prepVdpWrite sprites.vramAddress
    ld hl, sprites.buffer
    smslib.callOutiBlock 64

    ; Copy x position and patterns
    smslib.prepVdpWrite (sprites.vramAddress + 128) ; skip y and sprite table hole
    ld hl, sprites.buffer + sprites.Buffer.xPosAndPattern
    smslib.callOutiBlock 128
.endm

;====
; Adds a group of sprites relative to a base position. Sprites within the group
; that are off-screen are not added.
;
; @in   b   base x position (left-most)
; @in   c   base y position (top-most)
; @in   de  pointer to next free sprite slot
; @in   hl  pointer to sprites.Sprite instances terminated by
;           sprites.GROUP_TERMINATOR
;
; @out  de  next free sprite slot
;====
.section "sprites.addGroup"
    _xOffScreen:
        inc hl  ; point to relY
    _yOffScreen:
        inc hl  ; point to pattern
    _nextSprite:
        inc hl  ; point to next item

    sprites.addGroup:
        ld a, (hl)          ; load relX
        cp sprites.GROUP_TERMINATOR
        ret z               ; end of group

        ; Add relative x
        add a, b            ; relX + baseX
        jp c, _xOffScreen   ; off screen; next sprite
        ld ixh, a           ; store result x for later

        ; Add relative y
        inc hl              ; point to relY
        ld a, (hl)          ; load relY
        add a, c            ; relY + baseY
        cp sprites.maxYPos  ; compare with max y allowed
        jp nc, _yOffScreen  ; off screen; next sprite

        ; Output sprite to sprite buffer
        ld (de), a          ; set sprite y in buffer
        rlc e               ; point to sprite x; works because of $xx40 offset
        ld a, ixh           ; restore x
        ld (de), a          ; set sprite x in buffer
        inc hl              ; point to pattern number in group
        inc de              ; point to pattern number in buffer
        ld a, (hl)          ; load pattern number
        ld (de), a          ; set pattern number in buffer
        rr e                ; return to y in buffer
        inc de              ; point to next sprite slot in buffer
        jp _nextSprite
.ends

;====
; Macro alias for sprites.addGroup
;====
.macro "sprites.addGroup"
    call sprites.addGroup
.endm