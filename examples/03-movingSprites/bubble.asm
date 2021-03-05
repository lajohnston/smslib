;====
; A 'bubble' entity that can be controlled with the joypad direction buttons
;====

;====
; Define Bubble struct
;====
.struct "Bubble"
    xPos:   db  ; the current x position
    yPos:   db  ; the current y position
    xVec:   db  ; the number of x pixels to move per frame
    yVec:   db  ; the number of y pixels to move per frame
.endst

;====
; Initialises a bubble instance in RAM
;
; @in   ix  pointer to bubble
;====
.macro "bubble.init"
    ld (ix + Bubble.xVec), 0
    ld (ix + Bubble.yVec), 0
    ld (ix + Bubble.xPos), 100
    ld (ix + Bubble.yPos), 80
.endm

;====
; Updates the bubble's movement vector based on the joypad input
;
; @in   ix  pointer to bubble
;====
.section "bubble.updateInput" free
    bubble.updateInput:
        input.readPort1

        ; Update xVec
        xor a                       ; xVec = 0 (default)

        input.if input.LEFT, +
            ld a, -1                ; xVec = -1
        +:

        input.if input.RIGHT, +
            ld a, 1                 ; xVec = 1
        +:

        ld (ix + Bubble.xVec), a    ; store xVec

        ; Update yVec
        xor a                       ; yVec = 0 (default)

        input.if input.UP, +
            ld a, -1                ; yVec = -1
        +:

        input.if input.DOWN, +
            ld a, 1                 ; yVec = 1
        +:

        ld (ix + Bubble.yVec), a    ; store yVec
        ret
.ends

;====
; Updates the bubble's position based on its movement vector
;
; @in   ix  pointer to bubble
;====
.section "bubble.updateMovement" free
    bubble.updateMovement:
        ; xPos = xPos + yVec
        ld a, (ix + Bubble.xPos)    ; load xPos into a
        add a, (ix + Bubble.xVec)   ; add xVec to xPos
        ld (ix + Bubble.xPos), a    ; store updated xPos

        ; yPos = yPos + yVec
        ld a, (ix + Bubble.yPos)    ; load yPos into a
        add a, (ix + Bubble.yVec)   ; add yVec to yPos
        ld (ix + Bubble.yPos), a    ; store updated yPos
        ret
.ends

;====
; Adds the bubble's sprites to the sprite buffer
;
; @in   ix  pointer to bubble
;====
.section "bubble.updateSprite"
    bubble.updateSprite:
        ; Add sprite group to sprite buffer
        ld hl, bubble.spriteGroup
        ld b, (ix + Bubble.xPos)    ; base x pos
        ld c, (ix + Bubble.yPos)    ; base y pos
        sprites.addGroup            ; add group
        ret
.ends

;====
; Assets
;====
.section "bubble assets" free
    bubble.palette:
        .incbin "../assets/bubble/palette.bin" fsize bubble.paletteSize

    bubble.patterns:
        .incbin "../assets/bubble/patterns.bin" fsize bubble.patternsSize

    bubble.spriteGroup:
        ; pattern, relativeX, relativeY
        sprites.sprite 1, 0, 0  ; top left      (x0, y0)
        sprites.sprite 2, 8, 0  ; top right     (x+8, y0)
        sprites.sprite 3, 0, 8  ; bottom left   (x0, y+8)
        sprites.sprite 4, 8, 8  ; bottom right  (x+8, y+8)
        sprites.endGroup
.ends