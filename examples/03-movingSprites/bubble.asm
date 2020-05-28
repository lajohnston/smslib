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
        ; Read the port 1 into register b
        input.setRegister "c"
        input.readPort1

        ; Update xVec
        xor a                       ; xVec = 0
        input.if input.LEFT, +
            ld a, -1                ; xVec = -1
        +:
        input.if input.RIGHT, +
            ld a, 1                 ; xVec = 1
        +:
        ld (ix + Bubble.xVec), a    ; store xVec

        ; Update yVec
        xor a                       ; yVec = 0
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
        ld a, (ix + Bubble.xPos)    ; load xPos
        add a, (ix + Bubble.xVec)   ; add xVec to xPos
        ld (ix + Bubble.xPos), a    ; store in xPos

        ; yPos = yPos + yVec
        ld a, (ix + Bubble.yPos)    ; load yPos
        add a, (ix + Bubble.yVec)   ; add yVec to yPos
        ld (ix + Bubble.yPos), a    ; store in yPos
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
        .db $00 $11 $22 $32 $36 $3F

    bubble.patterns:
        ; Tile index $000
        .db $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00
        ; Tile index $001
        .db $08 $07 $00 $00 $04 $1C $03 $00 $10 $30 $0F $00 $20 $60 $1F $00 $80 $40 $3F $00 $40 $C0 $3F $00 $00 $80 $7F $00 $00 $80 $7F $00
        ; Tile index $002
        .db $10 $E0 $00 $00 $20 $38 $C0 $00 $08 $0C $F0 $00 $64 $06 $F8 $00 $11 $02 $FC $00 $0A $03 $FC $00 $08 $01 $FE $00 $00 $01 $FE $00
        ; Tile index $003
        .db $00 $80 $7F $00 $00 $80 $7F $00 $40 $C0 $3F $00 $80 $40 $3F $00 $20 $60 $1F $00 $10 $30 $0F $00 $04 $1C $03 $00 $08 $07 $00 $00
        ; Tile index $004
        .db $00 $01 $FE $00 $00 $01 $FE $00 $02 $03 $FC $00 $01 $02 $FC $00 $04 $06 $F8 $00 $08 $0C $F0 $00 $20 $38 $C0 $00 $10 $E0 $00 $00
        ; Tile index $005
        .db $42 $3C $00 $00 $81 $42 $3C $00 $08 $81 $7E $00 $04 $81 $7E $00 $00 $81 $7E $00 $00 $81 $7E $00 $81 $42 $3C $00 $42 $3C $00 $00

    bubble.spriteGroup:
        ; pattern, relativeX, relativeY
        sprites.sprite 1, 0, 0  ; top left      (x0, y0)
        sprites.sprite 2, 8, 0  ; top right     (x+8, y0)
        sprites.sprite 3, 0, 8  ; bottom left   (x0, y+8)
        sprites.sprite 4, 8, 8  ; bottom right  (x+8, y+8)
        sprites.endGroup
.ends