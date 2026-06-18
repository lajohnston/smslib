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
.ifndef utils.clobbers
    .include "utils/clobbers.asm"
.endif

.ifndef utils.port
    .include "utils/port.asm"
.endif

;====
; Settings
;
; Define these before including this file if you wish to override the defaults
;====

; If set, HBlanks will jump to an interrupts.onHBlank label defined in your code
.ifndef interrupts.INTERRUPT_HBLANKS
    .define interrupts.INTERRUPT_HBLANKS 0
.else
    .redefine interrupts.INTERRUPT_HBLANKS 1
.endif

;==
; If 1, allows the interrupt handler to utilise shadow registers to efficiently
; preserve registers instead of using the slower stack.
;
; If you wish to use shadow registers outside interrupts then you may need to
; set this to 0 to prevent the interrupt from overwriting data, or just ensure
; that an interrupt doesn't occur at this point in the code (i.e. by using
; interrupts.waitForVBlank to ensure they don't clash)
;==
.ifndef interrupts.USE_SHADOW_REGISTERS
    .define interrupts.USE_SHADOW_REGISTERS 0
.endif

;====
; Constants
;====
.define interrupts.VDP_STATUS_PORT $bf ; read = status; write = command
.define interrupts.VDP_VERTICAL_COUNTER_PORT $7e

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
.macro "interrupts.handler"
    .if interrupts.INTERRUPT_HBLANKS == 0
        ret     ; No handling necessary
    .else
        interrupts._preserveAF

        ; Consume and reset VDP flags
        utils.port.read interrupts.VDP_STATUS_PORT
        or a                        ; analyse status flags
        jp p, interrupts.onHBlank   ; jump to HBlank handler if HBlank flag set

        ; Interrupt was a VBlank - ignore and return
        interrupts._restoreAF
        ei
        ret
    .endif
.endm

; If interrupts.DISABLE_HANDLER is not defined, create the handler
.ifndef interrupts.DISABLE_HANDLER
    ;====
    ; Places the interrupt handler at address $38. The SMS will jump to this
    ; location when an HBlank (line) or VBlank (screen) interrupt occurs
    ;====
    .bank 0 slot 0
    .orga $38
    .section "interrupts.handler" force
        interrupts.handler
    .ends
.endif

;====
; Returns from an HBlank interrupt
;====
.macro "interrupts.endHBlank"
    interrupts._restoreAF   ; restore a, overwritten by status read
    ei                      ; re-enable interrupts
    ret                     ; reti not needed for SMS; ret is faster
.endm

;====
; (Private) Polls the VDP status flags until the VBlank flag is set. If the
; sprite overflow or collision flags are set at any point they will be set
; in the returned flags in A
;====
.section "vdpStatusFlags._waitForVBlank" free
    vdpStatusFlags._waitForVBlank:
        utils.port.read interrupts.VDP_STATUS_PORT ; read (and clear) flags from VDP
        and %01111111                       ; clear VBlank flag

        ; Poll until VBlank flag set, ensuring to preserve sprite flags
        -:
            ld b, a                         ; store accumulated flags in B
            utils.port.read interrupts.VDP_STATUS_PORT ; get latest flags from VDP
            or b                            ; combine with previous flags
            ret m                           ; return if VBlank flag set
        jp -                                ; otherwise, keep polling
.ends

;====
; Waits until a VBlank next occurs before continuing
;
; @out  af  the VDP status flags
;           bit 7 = VBlank (will be set)
;           bit 6 = set if more than 8 sprites were on one scanline
;           bit 5 = set if visible pixels from 2+ sprites overlapped
;====
.macro "interrupts.waitForVBlank" isolated
    utils.clobbers "bc"
        call vdpStatusFlags._waitForVBlank
    utils.clobbers.end
.endm

;====
; Set the number of lines that should be drawn until triggering the next
; HBlank interrupt
;
; @in a|value   if using a, 0-based. If using value, 1-based
;====
.macro "interrupts.setLineInterval" args value
    utils.clobbers "af"
        .ifdef value
            ld a, value - 1
        .endif

        out (interrupts.VDP_STATUS_PORT), a
        ld a, $8a   ; register 10
        out (interrupts.VDP_STATUS_PORT), a
    utils.clobbers.end
.endm

;====
; Retrieve the current line that is being/just been drawn
;
; @out  a   the line that is being/just been drawn (0-based)
;====
.macro "interrupts.getLine"
    utils.port.read interrupts.VDP_VERTICAL_COUNTER_PORT
.endm
