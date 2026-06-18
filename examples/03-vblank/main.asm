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
; between frames where we can write data to VRAM without restriction.
;
; In addition, as the interrupt occurs every 50 or 60 times a second for
; PAL/NTSC respectively, we can use this frequency to regulate the speed our
; logic runs at.
;====
.sdsctag 1.10, "smslib vblank", "smslib vblank tutorial", "lajohnston"

; Import smslib
.incdir "../../src"                 ; back to smslib directory
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

        ld a, 1
        ld (ram.color), a   ; set color to 1 (red)

        ; Enable the display
        vdp.enableDisplay

        ; Begin
        jp update
.ends

;====
; Update each frame. Most of our logic will go here
;====
.section "update" free
    update:
        ; Update the background color every 50 frames
        ld a, (ram.counter) ; load counter from RAM
        inc a               ; increment counter
        ld (ram.counter), a ; store counter back in RAM

        ; If counter is 50, update background color
        cp 50
        jp nz, +                ; jump if counter isn't 50 yet
            xor a               ; reset counter to 0
            ld (ram.counter), a ; store counter back in RAM

            ld a, (ram.color)   ; load color value from RAM
            inc a               ; increment color value
            and %00111111       ; keep in 0-63 range
            ld (ram.color), a   ; store color value back in RAM
        +:

        ;====
        ; Wait for VBlank, when the VDP has drawn the last/bottom line of the
        ; current frame. This VBlank period is the best time to write data to
        ; VDP without causing graphical corruption. It also allows us to
        ; regulate the speed of our update to 50fps (PAL) or 60fps (NTSC)
        ;====
        interrupts.waitForVBlank

        ; Write ram.color into palette index 0
        palette.setIndex 0
        palette.writeBytes ram.color 1

        ; Next loop
        jp update
.ends
