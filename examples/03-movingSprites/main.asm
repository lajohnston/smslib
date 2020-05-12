;====
; SMSLib Static sprites example
;
; Moves sprites on the screen using a VBlank handler
;====
.sdsctag 1.10, "smslib sprites", "smslib static sprite tutorial", "lajohnston"

;====
; Import smslib
;====
.incdir "../../"            ; back to smslib directory
.include "smslib.asm"       ; base library
.include "mapper/basic.asm" ; memory mapper
.include "palette.asm"      ; handles colors
.include "patterns.asm"     ; handles patterns (tile images)
.include "pause.asm"        ; handles pause button
.include "sprites.asm"      ; handles a sprite buffer in RAM
.include "vdpreg.asm"       ; handles vdp settings

; Handle frame interrupts
.define interrupts.handleVBlank 1
.include "interrupts.asm"

;====
; Boot sequence at ROM address 0
;====
.bank 0 slot 0
.orga 0
.section "main" force
    smslib.init init ; initialise then jump to init
.ends

;====
; Place an instance of sprite.Buffer somewhere in RAM with an offset of $40
; This offset is used by smslib to perform optimisations
;====
.ramsection "ram" bank 0 slot mapper.RAM_SLOT orga $C040 force
    sprites.buffer: instanceof sprites.Buffer
.ends

;====
; Define a Bubble struct containing xy position and movement vectors
;====
.struct "Bubble"
    xVec:   db
    xPos:   db
    yVec:   db
    yPos:   db
.endst

;====
; Reserve a place in RAM for a Bubble instance
;====
.ramsection "bubble" slot mapper.RAM_SLOT
    bubble: instanceof Bubble
.ends

;====
; Initialise program
;====
.section "code" free
    init:
        ; Load sprite palette
        palette.setSlot palette.SPRITE_PALETTE
        palette.load paletteData, 6

        ; Load pattern data into slots 256+ (used by sprites, by default)
        patterns.setSlot 256
        patterns.load patternData, 6

        ; Initialise bubble
        ld ix, bubble
        ld (ix + Bubble.xVec), 0
        ld (ix + Bubble.yVec), -1
        ld (ix + Bubble.xPos), 100
        ld (ix + Bubble.yPos), 80

        ; Enable the display and interrupts
        vdpreg.setRegister1 vdpreg.ENABLE_DISPLAY|vdpreg.ENABLE_VBLANKS
        interrupts.enable

    mainLoop:
        ; Wait for VBlank to finish before continuing
        interrupts.waitForVBlank

        ; If paused, keep restarting loop until unpaused
        pause.jpIfPaused mainLoop

        ; Add bubble movement vector to position
        ld ix, bubble

        ; Add xVec to xPos
        ld a, (ix + Bubble.xPos)    ; load xPos
        add a, (ix + Bubble.xVec)   ; add xVec to xPos
        ld (ix + Bubble.xPos), a    ; store in xPos

        ; Add yVec to yPos
        ld a, (ix + Bubble.yPos)    ; load yPos
        add a, (ix + Bubble.yVec)   ; add yVec to yPos
        ld (ix + Bubble.yPos), a    ; store in yPos

        ; Add sprite group to sprite buffer
        sprites.setSlot 0
        ld hl, spriteGroup
        ld b, (ix + Bubble.xPos)    ; base x pos
        ld c, (ix + Bubble.yPos)    ; base y pos
        sprites.addGroup

        sprites.end                 ; no more sprites

        ; Next loop
        jp mainLoop

    ; VBlank routine, called after each frame is rendered
    interrupts.onVBlank:
        push bc
        push hl
            sprites.copyToVram  ; copy buffer to VRAM
        pop hl
        pop bc

        interrupts.endVBlank
.ends

;====
; Assets
;====
.section "assets" free
    paletteData:
        .db $00 $11 $22 $32 $36 $3F

    patternData:
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

    spriteGroup:
        ; pattern, relativeX, relativeY
        sprites.sprite 1, 0, 0  ; top left      (x0, y0)
        sprites.sprite 2, 8, 0  ; top right     (x+8, y0)
        sprites.sprite 3, 0, 8  ; bottom left   (x0, y+8)
        sprites.sprite 4, 8, 8  ; bottom right  (x+8, y+8)
        sprites.endGroup
.ends
