;====
; SMSLib moving sprites example
;
; Create a sprite the can be controller with the directional input of joypad 1.
; Demonstrates VBlank handling using interrupts.asm
;====
.sdsctag 1.10, "smslib sprites", "smslib static sprite tutorial", "lajohnston"

;====
; Import smslib
;====
.incdir "../../"            ; back to smslib directory
.include "smslib.asm"       ; base library
.include "mapper/basic.asm" ; memory mapper
.include "input.asm"        ; handles input
.include "palette.asm"      ; handles colors
.include "patterns.asm"     ; handles patterns (tile images)
.include "pause.asm"        ; handles pause button
.include "sprites.asm"      ; handles a sprite buffer in RAM
.include "vdpreg.asm"       ; handles vdp settings

;====
; Handle frame (VBlank) interrupts. This will call the interrupts.vBlank label
; below each time a frame has finished being drawn. This occurs 50 times a
; second for PAL and 60 times per second for NTSC and can be used to regulate
; the logic speed
;====
.define interrupts.handleVBlank 1
.include "interrupts.asm"

; Import bubble entity
.incdir "."
.include "bubble.asm"

;====
; Boot sequence at ROM address 0
;====
.bank 0 slot 0
.orga 0
.section "main" force
    smslib.init init ; initialise then jump to init
.ends

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
        ; Load sprite palette
        palette.setSlot palette.SPRITE_PALETTE
        palette.load bubble.palette, 6

        ; Load pattern data to draw sprites. Sprites use slots 256+ by default
        patterns.setSlot 256
        patterns.load bubble.patterns, 6

        ; Initialise bubble with default values
        ld ix, bubbleInstance
        bubble.init

        ; Enable the display and interrupts
        vdpreg.startBatch
            vdpreg.enableDisplay
            vdpreg.enableVBlank
            vdpreg.hideLeftColumn
        vdpreg.endBatch

        ; Begin
        interrupts.enable
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
        call bubble.updateSprite
        sprites.end ; no more sprites

        ; Next loop
        jp mainLoop
.ends

;====
; VBlank routine called by interrupts.asm after each frame is drawn.
;
; This is a good time to send data to the VDP before it starts drawing the next
; frame.
;
; When this has finished, the mainLoop will continue. The
; interrupts.waitForVBlank will be satisfied and the rest of the loop will
; proceed.
;====
.section "vBlankHandler" free
    ; This is called by interrupts.asm
    interrupts.onVBlank:
        push bc
        push hl
            sprites.copyToVram  ; copy buffer to VRAM
        pop hl
        pop bc

        ; End vBlank handler
        interrupts.endVBlank
.ends
