;====
; SMSLib VBlank example
;
; This demo changes the background color every second or so using a VBlank handler.

; Each time the VDP has finished drawing a complete image on the TV it will
; raise an 'interrupt' to interrupt the Z80 from whatever it's working on and
; jump to a section of code we'll call the VBlank handler. After the handler
; has finished we can then return to the interrupted code so it can continue
; where it left off.
;
; Sending data to the VDP while it is actively drawing a frame can result in
; graphical corruption. The VBlank therefore provides us a small time window
; between frames where we can send data to the VDP without restriction.
;
; In addition, as the interrupt occurs every 50 or 60 times a second for
; PAL/NTSC respectively, we can use this frequency to regulate the speed our
; logic runs at.
;====
.sdsctag 1.10, "smslib vblank", "smslib vblank tutorial", "lajohnston"

; Import smslib
.define interrupts.handleVBlank 1   ; enable VBlank handling in interrupts.asm
.incdir "../../"                    ; back to smslib directory
.include "smslib.asm"               ; base library
.incdir "."                         ; return to current directory

;====
; Store variables in RAM. See mapper documentation for details about
; mapper.RAM_SLOT
;====
.ramsection "ram" slot mapper.RAM_SLOT
    ; We'll increment this value each frame
    ram.counter:    db ; 1-byte

    ; When the counter hits a certain value, we'll increment this value
    ram.color:      db ; 1-byte
.ends

;====
; Initialise the example
;====
.section "init" free
    init:
        ; Initialise variables in RAM
        xor a               ; set a to 0
        ld (ram.counter), a ; set counter to 0
        ld (ram.color), a   ; set color to 0 (black)

        ;====
        ; Enable the display and interrupts
        ; When changing multiple vdp settings it's more efficient (but optional)
        ; to specify changes within a 'batch'
        ;====
        vdp.startBatch
            vdp.enableDisplay
            vdp.enableVBlank
        vdp.endBatch

        ; Now we've finished initialising, enable interrupts on the Z80
        interrupts.enable

        ; Begin
        jp update
.ends

;====
; The VBlank interrupt is triggered after the VDP has finished drawing a frame.
; Any data we want to send to the VDP should be done here (or while the display
; is disabled) as sending this data while the VDP is actively rendering a frame
; can lead to graphical corruption and visual artefacts.
;====
.section "render" free
    ; interrupts.onVBlank is called by interrupts.asm 50/60x a second (PAL/NTSC)
    interrupts.onVBlank:
        ; Load ram.color into palette index 0
        palette.setIndex 0
        palette.load ram.color 1

        ; End VBlank handler
        ; Will return to the code that was interrupted
        interrupts.endVBlank
.ends

;====
; Update each frame. Most of our logic will go here
;====
.section "update" free
    update:
        ; Wait for frame interrupt handler to finish before continuing.
        ; This lets us regulate the speed of the update loop to running at 50
        ; or 60 times a second (PAL, NTSC respectively)
        interrupts.waitForVBlank

        ; Increment counter
        ld hl, ram.counter  ; point to counter
        inc (hl)            ; increment counter

        ; If counter has reached 50...
        ld a, (hl)          ; load counter
        cp 50               ; compare it to 50
        jp nz, +            ; jump to + if it's not 50
            ; Reset counter
            ld (hl), 0      ; set ram.counter to 0

            ; Next color
            ld hl, ram.color    ; point to ram.color
            ld a, (hl)          ; load color into a
            inc a               ; increment color value

            ; Colors are 6-bit. If we've overflowed into 7th bit, go back to 0
            cp %01000000
            jp nz, +
                xor a   ; set color to 0
            +:

            ld (hl), a  ; store new color in ram.color
        +:

        ; Next loop
        jp update
.ends
