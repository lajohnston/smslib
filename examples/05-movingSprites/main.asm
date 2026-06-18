;====
; SMSLib moving sprites example
;
; Create a sprite that can be controlled with the directional input of joypad 1.
; Demonstrates VBlank handling using interrupts.asm
;====
.sdsctag 1.10, "smslib sprites", "smslib moving sprites tutorial", "lajohnston"

; Import smslib
.incdir "../../src"         ; back to smslib directory
.include "smslib.asm"       ; base library
.incdir "."                 ; return to current directory

; Import bubble entity
.include "bubble.asm"

;====
; Reserve a place in RAM for a Bubble instance
;====
.ramsection "bubble" slot mapper.RAM_SLOT
    bubbleInstance: instanceof Bubble
.ends

;====
; Initialise the example
;====
.section "init" free
    init:
        ; Set background colour
        palette.setIndex 0
        palette.writeRgb 0, 0, 0    ; black

        ; Load sprite palette
        palette.setIndex palette.SPRITE
        palette.writeBytes bubble.palette, bubble.paletteSize

        ; Load pattern data to draw sprites. Sprites use indices 256+ by default
        patterns.setIndex 256
        patterns.writeBytes bubble.patterns, bubble.patternsSize

        ; Initialise bubble with default values
        ld ix, bubbleInstance
        bubble.init

        ;====
        ; Enable the display
        ; When changing multiple vdp settings it's usually more efficient
        ; (but optional) to specify changes within a 'batch'
        ;====
        vdp.startBatch
            vdp.enableDisplay

            ; hide the left-most column - allows sprites to scroll more smoothly
            ; off the left side of the screen
            vdp.hideLeftColumn
        vdp.endBatch

        ; Begin
        jp mainLoop
.ends

;====
; Update bubble each frame
;====
.section "mainLoop" free
    mainLoop:
        ; Update bubble instance
        ld ix, bubbleInstance
        call bubble.updateInput
        call bubble.updateMovement

        ; Add sprites
        sprites.reset               ; reset buffer
        call bubble.updateSprite    ; add sprites

        ; Wait for VBlank before continuing
        interrupts.waitForVBlank

        ; Copy the sprite buffer to VRAM
        sprites.copyToVram

        ; Next loop
        jp mainLoop
.ends
