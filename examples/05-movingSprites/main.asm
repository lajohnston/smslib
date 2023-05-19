;====
; SMSLib moving sprites example
;
; Create a sprite that can be controlled with the directional input of joypad 1.
; Demonstrates VBlank handling using interrupts.asm
;====
.sdsctag 1.10, "smslib sprites", "smslib moving sprites tutorial", "lajohnston"

;====
; Tell smslib interrupts module to handle frame (VBlank) interrupts. This will
; call the interrupts.onVBlank label each time a frame has finished being drawn.
; This occurs 50 times a second for PAL and 60 times per second for NTSC and can
; be used to regulate the logic speed
;====
.define interrupts.HANDLE_VBLANK 1

; Import smslib
.incdir "../../"            ; back to smslib directory
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
        palette.setIndex palette.SPRITE_PALETTE
        palette.writeBytes bubble.palette, bubble.paletteSize

        ; Load pattern data to draw sprites. Sprites use indices 256+ by default
        patterns.setIndex 256
        patterns.writeBytes bubble.patterns, bubble.patternsSize

        ; Initialise bubble with default values
        ld ix, bubbleInstance
        bubble.init

        ;====
        ; Enable the display and interrupts
        ; When changing multiple vdp settings it's more efficient (but optional)
        ; to specify changes within a 'batch'
        ;====
        vdp.startBatch
            vdp.enableDisplay
            vdp.enableVBlank

            ; hide the left-most column - allows sprites to scroll more smoothly
            ; off the left side of the screen
            vdp.hideLeftColumn
        vdp.endBatch

        ; Now we've finished initialising, enable interrupts
        interrupts.enable

        ; Begin
        jp mainLoop
.ends

;====
; Update bubble each frame
;====
.section "mainLoop" free
    mainLoop:
        ; Wait for frame interrupt handler to finish before continuing
        interrupts.waitForVBlank

        ; Update bubble instance
        ld ix, bubbleInstance
        call bubble.updateInput
        call bubble.updateMovement

        ; Add sprites
        sprites.reset               ; reset buffer
        call bubble.updateSprite    ; add sprites

        ; Next loop
        jp mainLoop
.ends

;====
; VBlank routine called by interrupts.asm after each frame is drawn.
;
; This is a good time to write data to VRAM before it starts drawing the
; next frame.
;
; When this has finished, interrupts.waitForVBlank in the main loop will be
; satisfied and the rest of the loop will continue
;====
.section "vBlankHandler" free
    ; This is called by interrupts.asm
    interrupts.onVBlank:
        ; Copy buffer to VRAM
        sprites.copyToVram

        ; End vBlank handler
        interrupts.endVBlank
.ends
