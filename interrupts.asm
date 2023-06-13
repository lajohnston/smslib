;====
; Handles vertical (frame) and horizontal (line) blanks. Assumes the use of
; interrupt mode 1 (im 1).
;
; VBlanks and HBlanks will still need to be enabled in the VDP registers. You
; can use smslib vdp.asm for this:
;
; Enable HBlank - VDP register 0, bit 4
; Enable VBlank - VDP register 1, bit 5
;====
.define interrupts.ENABLED 1

;====
; Dependencies
;====
.ifndef utils.ram
    .include "utils/ram.asm"
.endif

;====
; Settings
;
; Define these before including this file if you wish to override the defaults
;====

; If 1, VBlanks will jump to an interrupts.onVBlank label defined in your code
.ifndef interrupts.HANDLE_VBLANK
    .define interrupts.HANDLE_VBLANK 0
.endif

; If 1, HBlanks will jump to an interrupts.onHBlank label defined in your code
.ifndef interrupts.HANDLE_HBLANK
    .define interrupts.HANDLE_HBLANK 0
.endif

;==
; If 1, allows the interrupt handler to utilise shadow registers to efficiently
; preserve registers instead of using the slower stack. When enabled it will
; also preserve af, bc, de and hl during VBlank so you don't need to push/pop
; these registers.
;
; If you wish to use shadow registers outside interrupts then you may need to
; set this to 0 to prevent the interrupt from overwriting data, or just ensure
; that an interrupt doesn't occur at this point in the code (i.e. by using
; interrupts.waitForVBlank to ensure they don't clash)
;==
.ifndef interrupts.USE_SHADOW_REGISTERS
    .define interrupts.USE_SHADOW_REGISTERS 1
.endif

;====
; Constants
;====
.define interrupts.VDP_PORT $bf ; read = status; write = command

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

; Preserve AF depending on interrupts.USE_SHADOW_REGISTERS setting
.macro "interrupts._preserveAF"
    .if interrupts.USE_SHADOW_REGISTERS == 1
        ex af, af'
    .else
        push af
    .endif
.endm

; Preserve AF depending on interrupts.USE_SHADOW_REGISTERS setting
.macro "interrupts._restoreAF"
    .if interrupts.USE_SHADOW_REGISTERS == 1
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
    .if interrupts.HANDLE_VBLANK + interrupts.HANDLE_HBLANK == 0
        ret ; No handling necessary
    .else
        interrupts._preserveAF
        in a, (interrupts.VDP_PORT)     ; satisfy interrupt

        ; If VBlank and HBlank are both enabled
        .if interrupts.HANDLE_VBLANK + interrupts.HANDLE_HBLANK == 2
            or a                        ; analyse vdp status in 'a'

            ; HBlank
            jp p, interrupts.onHBlank   ; jp if 7th bit (VBlank) is reset

            ; VBlank
            .if interrupts.USE_SHADOW_REGISTERS == 1
                exx
            .endif

            jp interrupts.onVBlank
        .else
            ; If only VBlank enabled, jump to that handler
            .if interrupts.HANDLE_VBLANK == 1
                .if interrupts.USE_SHADOW_REGISTERS == 1
                    exx
                .endif

                jp interrupts.onVBlank
            .endif

            ; If only HBlank enabled, jump to that handler
            .if interrupts.HANDLE_HBLANK == 1
                jp interrupts.onHBlank
            .endif
        .endif
    .endif
.ends

;====
; Returns from a VBlank interrupt
;====
.macro "interrupts.endVBlank"
    .if interrupts.USE_SHADOW_REGISTERS == 0
        push hl
    .endif

    ; Set flag to signal that a VBlank has occurred
    ld hl, interrupts.ram.vBlankFlag
    inc (hl)

    .if interrupts.USE_SHADOW_REGISTERS == 0
        pop hl
    .endif

    interrupts._restoreAF   ; restore af, overwritten by status read
    exx                     ; restore bc, de, hl from shadow registers
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
    ; Set vBlankFlag to 0
    xor a ; a = 0
    ld (interrupts.ram.vBlankFlag), a
.endm

;====
; Enables interrupts in the Z80. Ensures there are no pending/unsatisfied
; VDP interrupts that will unexpectedly trigger as soon as 'ei' takes effect
;====
.macro "interrupts.enable"
    ; Ensure there are no pending interrupts that will trigger unexpectedly
    in a, (interrupts.VDP_PORT) ; reset status

    ; Enable interrupts on the Z80
    ei
.endm

;====
; Waits until a VBlank next occurs before continuing
;====
.macro "interrupts.waitForVBlank"
    ; Poll VBlank flag in RAM
    -:
        halt        ; wait for next interrupt (pause, VBlank, HBlank)
        ld a, (interrupts.ram.vBlankFlag)  ; load vBlankFlag
        or a        ; analyze a
    jp z, -         ; if wasn't VBlank, wait again

    ; VBlank occurred - reset flag then continue
    xor a   ; set a to 0
    ld (interrupts.ram.vBlankFlag), a
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

    out (interrupts.VDP_PORT), a
    ld a, $8a   ; register 10
    out (interrupts.VDP_PORT), a
.endm

;====
; Retrieve the current line that is being/just been drawn
;
; @out  a   the line that is being/just been drawn (0-based)
;====
.macro "interrupts.getLine"
    in a, ($7e)
.endm
