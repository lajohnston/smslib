;================================================================
; Sprite Buffer
; Manages a sprite table buffer in RAM and transfers it to VRAM
;================================================================

;====
; How to use
;
; 1. Create an instance of sprites.buffer in RAM with a $xx40 offset (64-bytes)
; 2. In the game loop, use sprites.push or sprites.pushGroup to add sprites to
;       the buffer
; 3. During vblank, call sprites.copyToVram to transfer the buffer to VRAM
;====

;====
; Settings
;====

; The y position to set sprites to hide them offscreen
.ifndef sprites.HIDE_Y_POSITION
    .define sprites.HIDE_Y_POSITION $F0
.endif

; The sprite y position that hides the current and all following sprites
.ifndef sprites.Y_TERMINATOR
    .define sprites.Y_TERMINATOR $D0
.endif

; The maximum screen y coordinate a sprite can be. Defaults to 192.
.ifndef sprites.MAX_SCREEN_Y
    .define sprites.MAX_SCREEN_Y 192
.endif

; The sprite table's address in VRAM. Defaults to $3f00
.ifndef sprites.vramAddress
    .define sprites.vramAddress $3f00
.endif

;====
; Constants
;====
; Terminates a list of sprites.sprite instances
.define sprites.SPRITE_LIST_TERMINATOR 0-128

; VDP ports
.define sprites.VDP_COMMAND_PORT $bf
.define sprites.VDP_DATA_PORT $be

;====
; Sprite buffer
;
; An instance should be placed in RAM at a $xx40 offset
;====
.struct "sprites.buffer"
    yPos:           DSB 64  ; screen yPos for each of the 64 sprites
    xPosAndPattern: DSB 128 ; 1 byte xPos, 1 byte pattern * 64 sprites
.endst

;====
; Represents a single sprite. If using sprites.pushGroup, more than one can be
; defined in a list terminated with a sprites.SPRITE_LIST_TERMINATOR byte
;====
.struct "sprites.sprite"
    relativeY:  db  ; two's compliment (-127 to 127) (-128 signifies the end of a sprite list)
    relativeX:  db  ; two's compliment (-128 to 127)
    pattern:    db
.endst

; Defines a single sprite
.macro "sprites.sprite.define" args pattern relativeX relativeY
    .db relativeY relativeX pattern
.endm

;====
; Adds a sprite to the buffer
;
; @in  de address of the y position in the buffer
; @in  a  yPos
; @in  b  xPos
; @in  c  pattern
;
; @clobs af
;====
.section "sprites.push" free
    sprites.push:
        ; yPos
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
        ret
.ends

;====
; Clears all sprites in the sprite table buffer
;
; @in  de address of the table buffer in RAM
;
; @clobs af, b, de
;====
.section "sprites.clear" free
    sprites.clear:
        ; Set all y positions to the hidden position
        ld a, sprites.HIDE_Y_POSITION
        ld b, 64
        -:
            ld (de), a
            inc de
        djnz -

        ; Zero x and patterns
        xor a   ; a = 0
        ld b, 128
        -:
            ld (de), a
            inc de
        djnz -

        ret
.ends

;====
; Marks the end of sprite table so remaining sprites are not processed
;
; @in     de  address of the next free y position in the buffer
; @clobs a
;====
.macro "sprites.end"
    ld a, sprites.Y_TERMINATOR
    ld (de), a
.endm

;====
; Copies a sprites.buffer instance from RAM to VRAM
;
; @in     hl    the address of the sprites.buffer instance in RAM
; @clobs af, bc, hl
;====
.macro "sprites.copyToVram" args sourceAddress
    ld hl, sourceAddress
    smslib.fastVramWrite sprites.vramAddress 64

    ld hl, sourceAddress + 64
    smslib.fastVramWrite (sprites.vramAddress + 128) 128
.endm

;====
; Pushes one or more sprites to a buffer, as defined by a list of
; sprites.sprite instances. Each sprite position is relative to the
; previous sprite. The list of sprites must be terminated by a
; byte containing the sprites.SPRITE_LIST_TERMINATOR value
;
; @in     hl  pointer to the spriteGroup
; @in     de  pointer to the next free
; @in     ix  pointer to the entity's x position (relative to the camera)
; @in     iy  pointer to the entity's y position (relative to the camera)
;
; @out  de  address of the next free sprite in the buffer
;
; @clobs af, bc, hl, ix, iy
;====
.section "sprites.pushGroup"
    ; @in  hl pointer to 'pattern' byte of previous sprite
    _nextSprite:
        inc hl  ; point to next sprite

    sprites.pushGroup:
        ; if yPos == terminator, return
        ld a, (hl)
        cp sprites.SPRITE_LIST_TERMINATOR
        ret z

        ; add y offset to yPos
        _addYOffset:
            or a                ; analyse yOffset in register a
            jp z, _addXOffset   ; no offset to add
            ld b, 0
            jp p, +     ; if offset is negative:
                dec b   ; set high-byte to $FF, for 2's complement addition
            +:

            ld c, a     ; load offset into register c
            add iy, bc

        ; add x offset to xPos
        _addXOffset:
            inc hl      ; point to x offset
            ld a, (hl)  ; load xOffset
            or a        ; analyse xOffset in register a
            jp z, _checkOnScreen    ; no offset to add

            ld b, 0
            jp p, +     ; if offset is negative:
                dec b   ; set high-byte to $FF, for 2's complement addition
            +:

            ld c, a     ; load offset into register c
            add ix, bc

        _checkOnScreen:
            inc hl      ; point to pattern number

            ; if high-bytes of xPos or yPos are not zero, skip sprite
            xor a       ; a = 0
            cp iyh
            jp nz, _nextSprite  ; jp if sprite is offscreen
            cp ixh
            jp nz, _nextSprite  ; jp if sprite is offscreen

            ; if yPos >= max y position, skip
            ld a, iyl
            cp sprites.MAX_SCREEN_Y + 1 ; +1 to make comparison <=
            jp nc, _nextSprite  ; jp if sprite is offscreen

        ;; add sprite to buffer
        ; store yPos in buffer
        ld a, iyl
        ld (de), a

        ; store xPos in buffer
        ld a, ixl
        rlc e       ; switch to xPos (e = e * 2; works because of $xx40 offset)
        ld (de), a

        ; store pattern in buffer
        inc de
        ld a, (hl)
        ld (de), a

        ; Restore de to point back to yPos in buffer
        rr e    ; (e - 1) / 2
        inc de  ; point to next slot
        jp _nextSprite
.ends
