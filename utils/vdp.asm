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

; Registers
.define utils.vdp.BORDER_COLOR_REGISTER 7
.define utils.vdp.SCROLL_X_REGISTER 8
.define utils.vdp.SCROLL_Y_REGISTER 9
.define utils.vdp.LINE_COUNTER_REGISTER 10

; Commands
.define utils.vdp.commands.READ     %00111111   ; AND mask
.define utils.vdp.commands.WRITE    %01000000   ; OR mask

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
    .ifeq <address 0
        xor a
    .else
        ld a, <address
    .endif

    out (utils.vdp.VDP_COMMAND_PORT), a

    ; Output high byte to VDP with write command set
    ld a, >address | utils.vdp.commands.WRITE
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
; Prepare a VRAM read or write to the address stored in HL
;
; @in   hl                  VRAM address
; @in   [command]           utils.vdp.command.READ or utils.vdp.command.WRITE
;                           if not present, H should already have the correct
;                           command bits (6th and 7th) set or reset.
;                           (00 = read; 01 = write)
; @out  VRAM write address  VRAM address with command bits set
; @out  c                   VDP data port
;====
.macro "utils.vdp.prepCommandHL" args command
    ; Output low byte to VDP
    ld a, l
    out (utils.vdp.VDP_COMMAND_PORT), a ; output low address byte

    ; Output high byte to VDP with write command
    ld a, h

    ; If command given, set command bits
    .ifdef command
        .if command == utils.vdp.commands.READ
            ; Reset high bits
            and utils.vdp.commands.READ
        .elif command == utils.vdp.commands.WRITE
            ; Set bit 6; assumes bit 7 is already 0
            or utils.vdp.commands.WRITE
        .endif
    .endif

    ; Output high address byte + command
    out (utils.vdp.VDP_COMMAND_PORT), a

    ; Port to write to
    ld c, utils.vdp.VDP_DATA_PORT
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

;====
; Sets the value of the given VDP register
;
; @in   registerNumber  the register number (0-10)
; @in   a|registerValue the register value
;====
.macro "utils.vdp.setRegister" args registerNumber registerValue
    .ifdef registerValue
        ld a, registerValue             ; load A with value if one is given
    .endif

    out (utils.vdp.VDP_COMMAND_PORT), a ; send the register value first
    ld a, %10000000 | registerNumber    ; load write command with register number
    out (utils.vdp.VDP_COMMAND_PORT), a ; send the register write command
.endm
