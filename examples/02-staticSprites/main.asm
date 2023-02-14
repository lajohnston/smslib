;====
; SMSLib Static sprites example
;
; Renders static sprites on the screen
;====
.sdsctag 1.10, "smslib sprites", "smslib static sprite tutorial", "lajohnston"

;====
; Import smslib
;====
.incdir "../../"            ; back to smslib directory
.include "smslib.asm"       ; base library
.incdir "."                 ; back to current directory

;====
; Assets we'll refer to in the code
;====
.section "assets" free
    bubblePatterns:
        .incbin "../assets/bubble/patterns.bin" fsize bubblePatternsSize

    bubblePalette:
        .incbin "../assets/bubble/palette.bin" fsize bubblePaletteSize

    spriteGroup:
        sprites.startGroup
            ; pattern, relativeX, relativeY
            sprites.sprite 1, 0, 0  ; top left      (x0, y0)
            sprites.sprite 2, 8, 0  ; top right     (x+8, y0)
            sprites.sprite 3, 0, 8  ; bottom left   (x0, y+8)
            sprites.sprite 4, 8, 8  ; bottom right  (x+8, y+8)
        sprites.endGroup
.ends

;====
; Initialise program
;
; SMSLib will jump to 'init' label after initialising the system
;====
.section "init" free
    init:
        ; Set background colour
        palette.setIndex 0
        palette.writeRgb 0, 0, 0    ; black

        ; Load sprite palette
        palette.setIndex palette.SPRITE_PALETTE
        palette.writeSlice bubblePalette, 6

        ; Load pattern data into indices 256+ (used for sprites, by default)
        patterns.setIndex 256
        patterns.writeBytes bubblePatterns, bubblePatternsSize

        ; It's more efficient (but optional) to add multiple sprites within a
        ; batch, so start a new batch
        sprites.startBatch

        ; Add a sprite to the buffer. See sprites.add documentation in sprite.asm
        ; for details about which parameters it expects in which registers
        ld a, 100   ; y position
        ld b, 80    ; x position
        ld c, 5     ; pattern number
        sprites.add ; add sprite

        ; Add a sprite group - multiple sprites relative to a position
        ld hl, spriteGroup  ; point to group (see assets below)
        ld b, 140           ; base x pos
        ld c, 50            ; base y pos
        sprites.addGroup    ; add group to buffer

        ; Another group - same group, different position
        ld hl, spriteGroup  ; point to group
        ld b, 170           ; base x pos
        ld c, 120           ; base y pos
        sprites.addGroup    ; add group to buffer

        ; End the sprite batch
        sprites.endBatch

        ; Copy buffer to VRAM
        sprites.copyToVram

        ; Enable the display then stop
        vdp.enableDisplay
        -: jr -
.ends
