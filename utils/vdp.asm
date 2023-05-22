;====
; Utilities for writing data to the VDP
;====

.define utils.vdp 1

;====
; Dependencies
;====
.ifndef utils.assert
    .include "utils/assert.asm"
.endif

.ifndef utils.outiBlock
    .include "utils/outiBlock.asm"
.endif

;====
; Constants
;====

; VDP ports
.define utils.vdp.COMMAND_PORT $bf
.define utils.vdp.DATA_PORT $be

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

    out (utils.vdp.COMMAND_PORT), a

    ; Output high byte to VDP with write command set
    ld a, >address | utils.vdp.commands.WRITE
    out (utils.vdp.COMMAND_PORT), a

    ; Port to write to
    .ifndef setPort
        .redefine setPort 1
    .endif

    .if setPort == 1
        ld c, utils.vdp.DATA_PORT
    .endif
.endm

;====
; Sets the command bits on the high byte of the VRAM address
;
; @in   a   high byte of the VRAM address ($00 - $3F)
; @in   a   high byte of the address with the command bits set
;====
.macro "utils.vdp._setCommand" args command
    utils.assert.oneOf command, utils.vdp.commands.READ, utils.vdp.commands.WRITE, "utils/vdp.asm \.: Invalid command argument"

    .if command == utils.vdp.commands.READ
        ; Reset high bits
        and utils.vdp.commands.READ
    .elif command == utils.vdp.commands.WRITE
        ; Set bit 6; if address is correct bit 7 should already by reset
        or utils.vdp.commands.WRITE
    .endif
.endm

;====
; Prepare a VRAM read or write to the address stored in HL. Port C must be set
; to utils.vdp.DATA_PORT before you can read or write the data
;
; @in   hl                  VRAM address ($0000 - $3FFF)
; @in   [command]           utils.vdp.command.READ or utils.vdp.command.WRITE
;                           if not present, H should already have the correct
;                           command bits (6th and 7th) set or reset.
;                           (%00 = read; %01 = write)
; @out  VRAM write address  VRAM address with command bits set
;====
.macro "utils.vdp.setCommandHL" args command
    .ifdef command
        utils.assert.oneOf command, utils.vdp.commands.READ, utils.vdp.commands.WRITE, "utils/vdp.asm \.: Invalid command argument"
    .endif

    ; Output low byte to VDP
    ld a, l
    out (utils.vdp.COMMAND_PORT), a ; output low address byte

    ; Load high byte into A
    ld a, h

    .ifdef command
        utils.vdp._setCommand command
    .endif

    ; Output high address byte + command
    out (utils.vdp.COMMAND_PORT), a
.endm

;====
; Prepare a VRAM read or write to the address stored in DE. Port C must be set
; to utils.vdp.DATA_PORT before you can read or write the data
;
; @in   de                  VRAM address ($0000 - $3FFF)
; @in   [command]           utils.vdp.command.READ or utils.vdp.command.WRITE
;                           if not present, D should already have the correct
;                           command bits (6th and 7th) set or reset.
;                           (%00 = read; %01 = write)
; @out  VRAM write address  VRAM address with command bits set
;====
.macro "utils.vdp.setCommandDE" args command
    .ifdef command
        utils.assert.oneOf command, utils.vdp.commands.READ, utils.vdp.commands.WRITE, "utils/vdp.asm \.: Invalid command argument"
    .endif

    ; Output low byte to VDP
    ld a, e
    out (utils.vdp.COMMAND_PORT), a ; output low address byte

    ; Load high byte into A
    ld a, d

    .ifdef command
        utils.vdp._setCommand command
    .endif

    ; Output high address byte + command
    out (utils.vdp.COMMAND_PORT), a
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
            out (utils.vdp.DATA_PORT), a ; output + increment VRAM address
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

    out (utils.vdp.COMMAND_PORT), a     ; send the register value first
    ld a, %10000000 | registerNumber    ; load write command with register number
    out (utils.vdp.COMMAND_PORT), a     ; send the register write command
.endm
