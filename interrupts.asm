;====
; Handles vertical (frame) and horizontal (line) blanks. Assumes the use of
; interrupt mode 1 (im 1).
;
; VBlanks and HBlanks will still need to be enabled in the VDP registers. You
; can use smslib vdpreg.asm for this:
;
; Enable HBlank - VDP register 0, bit 4
; Enable VBlank - VDP register 1, bit 5
;====
.define interrupts.ENABLED 1

;====
; Dependencies
;====
.include "./utils/ram.asm"

;====
; Settings
;
; Define these before including this file if you wish to override the defaults
;====

; If 1, VBlanks will jump to an interrupts.onVBlank label defined in your code
.ifndef interrupts.handleVBlank
    .define interrupts.handleVBlank 0
.endif

; If 1, HBlanks will jump to an interrupts.onHBlank label defined in your code
.ifndef interrupts.handleHBlank
    .define interrupts.handleHBlank 0
.endif

;==
; If 1, the handler will use ex af, 'af preserve the af registers when
; handling interrupts, instead of push/pop. This reduces the delay executing
; handlers by 7 clock cycles but means you have to be careful using ex in your
; own code outside of your interrupt code
;==
.ifndef interrupts.useShadowRegisters
    .define interrupts.useShadowRegisters 0
.endif

;====
; Constants
;====
.define interrupts.VDP_STATUS_PORT $bf

;====
; RAM
;====

;====
; Flag is set when a VBlank interrupt has occurred so that
; interrupts.waitForVBlank can differentiate them from pauses and HBlanks
;====
.ramsection "interrupts.ram.vBlankFlag" slot utils.ram.SLOT
    interrupts.ram.vBlankFlag: db
.ends

;====
; Code
;====

; Preserve AF depending on interrupts.useShadowRegisters setting
.macro "interrupts._preserveAF"
    .if interrupts.useShadowRegisters == 1
        ex af, af'
    .else
        push af
    .endif
.endm

; Preserve AF depending on interrupts.useShadowRegisters setting
.macro "interrupts._restoreAF"
    .if interrupts.useShadowRegisters == 1
        ex af, af'
    .else
        pop af
    .endif
.endm

;====
; Handler for vertical (frame) and horizontal (line) interrupts. Assumes the use
; of interrupt mode 1 which jumps to address $38 when an interrupt occurs
;====
.bank 0 slot 0
.orga $38
.section "interrupts.handler" force
    .if interrupts.handleVBlank + interrupts.handleHBlank == 0
        ret ; No handling necessary
    .else
        interrupts._preserveAF
        in a, (interrupts.VDP_STATUS_PORT)  ; satisfy interrupt

        ; If VBlank and HBlank are both enabled
        .if interrupts.handleVBlank + interrupts.handleHBlank == 2
            or a                        ; analyse a
            jp p, interrupts.onHBlank   ; jp if 7th bit (VBlank) is reset
            jp interrupts.onVBlank
        .else
            ; If only VBlank enabled, jump to that handler
            .if interrupts.handleVBlank == 1
                jp interrupts.onVBlank
            .endif

            ; If only HBlank enabled, jump to that handler
            .if interrupts.handleHBlank == 1
                jp interrupts.onHBlank
            .endif
        .endif
    .endif
.ends

;====
; Returns from a VBlank interrupt
;====
.macro "interrupts.endVBlank"
    ; Set flag to signal that a VBlank has occurred
    push hl
        ld hl, interrupts.ram.vBlankFlag
        inc (hl)
    pop hl

    interrupts._restoreAF   ; restore a, overwritten by status read
    ei                      ; re-enable interrupts
    ret                     ; faster than reti
.endm

;====
; Returns from an HBlank interrupt
;====
.macro "interrupts.endHBlank"
    interrupts._restoreAF   ; restore a, overwritten by status read
    ei                      ; re-enable interrupts
    ret                     ; faster than reti
.endm

;====
; Initialises the interrupt handler in RAM, if necessary
;====
.macro "interrupts.init"
    ld de, interrupts.ram.vBlankFlag
    xor a       ; a = 0
    ld (de), a  ; set vBlankFlag to zero
.endm

;====
; Enables interrupts in the Z80. Ensures there are no pending/unsatisfied
; VDP interrupts that will unexpectedly trigger as soon as 'ei' takes effect
;====
.macro "interrupts.enable"
    ; Ensure there are no pending interrupts that will trigger unexpectedly
    in a, (interrupts.VDP_STATUS_PORT)  ; reset status
    ei
.endm

;====
; Waits until a VBlank next occurs before continuing
;====
.macro "interrupts.waitForVBlank"
    ; Poll VBlank flag in RAM
    -:
    halt        ; wait for next interrupt (pause, VBlank, HBlank)
    ld de, interrupts.ram.vBlankFlag
    ld a, (de)  ; load vBlankFlag
    or a        ; analyze a
    jp z, -     ; if zero, wait again

    ; VBlank occurred - reset flag then continue
    xor a       ; set a to 0
    ld (de), a  ; reset VBlank flag
.endm

;====
; Set the number of lines that should be drawn until triggering the next
; HBlank interrupt
;
; @in a|value   if using a, 0-based. If using value, 1-based
;====
.macro "interrupts.setLineInterval" args value
    .ifdef value
        ld a, value - 1
    .endif

    out (vdpreg.COMMAND_PORT), a
    ld a, $8a   ; register 10
    out (vdpreg.COMMAND_PORT), a
.endm

;====
; Retrieve the current line that is being/just been drawn
;
; @out  a   the line that is being/just been drawn (0-based)
;====
.macro "interrupts.getLine"
    in a, ($7e)
.endm
