;====
; Utilities for writing data to the VDP
;====

.define utils.vdp 1

;====
; Dependencies
;====
.ifndef utils.outiBlock
    .include "utils/outiBlock.asm"
.endif

;====
; Constants
;====

; VDP ports
.define utils.vdp.VDP_COMMAND_PORT $bf
.define utils.vdp.VDP_DATA_PORT $be

;====
; Prepares the VDP to write to the given VRAM write address
;
; @in   address     the VRAM write address
; @in   [setPort]   if 1 (the default) then the c register will be loaded with
;                   the VDP data. Set to 0 if the port is already set (saves 7
;                   cycles)
;====
.macro "utils.vdp.prepWrite" args address setPort
    ; Output low byte to VDP
    ld a, <address
    out (utils.vdp.VDP_COMMAND_PORT), a

    ; Output high byte to VDP
    ; OR with $40 (%01000000) to set 6th bit and issue write command
    ld a, >address | $40
    out (utils.vdp.VDP_COMMAND_PORT), a

    ; Port to write to
    .ifndef setPort
        .redefine setPort 1
    .endif

    .if setPort == 1
        ld c, utils.vdp.VDP_DATA_PORT
    .endif
.endm

;====
; Zeroes all the VRAM
;====
.section "utils.vdp.clearVram" free
    utils.vdp.clearVram:
        ; 1. Set VRAM write address to $0000
        utils.vdp.prepWrite 0

        ; 2. Output 16KB of zeroes
        ld bc, $4000     ; Counter for 16KB of VRAM
        -:
            xor a
            out (utils.vdp.VDP_DATA_PORT), a ; Output to VRAM address, which is auto-incremented after each write
            dec bc
            ld a, b
            or c
        jr nz, -
    ret
.ends

; Macro alias for call utils.vdp.clearVram
.macro "utils.vdp.clearVram"
    call utils.vdp.clearVram
.endm
