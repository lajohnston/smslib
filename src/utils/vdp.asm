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

.ifndef utils.clobbers
    .include "utils/clobbers.asm"
.endif

.ifndef utils.outiBlock
    .include "utils/outiBlock.asm"
.endif

.ifndef utils.registers
    .include "utils/registers.asm"
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
.define utils.vdp.commands.READ_VRAM        %00111111   ; AND mask
.define utils.vdp.commands.WRITE_VRAM       %01000000   ; OR mask
.define utils.vdp.commands.WRITE_REGISTER   %10000000   ; OR mask
.define utils.vdp.commands.WRITE_CRAM       %11000000   ; Constant

;====
; Prepares the VDP to write to the given VRAM write address
;
; @in   address     the VRAM write address
; @in   [setPort]   if 1 (the default) then the c register will be loaded with
;                   the VDP data. Set to 0 if the port is already set (saves 7
;                   cycles)
; @out  c           data port, ready to output data to with out, outi etc.
;====
.macro "utils.vdp.prepVramWrite" args address setPort
    ; Assert address is in VRAM range
    utils.assert.range address 0 $3fff "\.: Address should be a valid VRAM address"

    ; Default setPort to 1
    .ifndef setPort
        .redefine setPort 1
    .endif

    utils.clobbers "af"
        ; Output low byte to VDP
        utils.registers.loadA <address
        out (utils.vdp.COMMAND_PORT), a

        ; Output high byte to VDP with write command set
        ld a, >address | utils.vdp.commands.WRITE_VRAM
        out (utils.vdp.COMMAND_PORT), a

        .if setPort == 1
            ; Port to write to
            ld c, utils.vdp.DATA_PORT
        .endif
    utils.clobbers.end
.endm

;====
; Prepares the VDP to write to the given Color RAM (CRAM) address
;
; @in   address     the CRAM write address (0-31)
; @out  c           data port, ready to output data to with out, outi etc.
;====
.macro "utils.vdp.prepCramWrite" args address
    utils.assert.range address 0, 31, "\.: Address must be between 0-31"

    utils.clobbers "af"
        ; Output address
        utils.registers.loadA address
        out (utils.vdp.COMMAND_PORT), a

        ; Output CRAM write command
        ld a, utils.vdp.commands.WRITE_CRAM
        out (utils.vdp.COMMAND_PORT), a

        ; Set port, ready for data output
        ld c, utils.vdp.DATA_PORT
    utils.clobbers.end
.endm

;====
; Sets the command bits on the high byte of the VRAM address
;
; @in   a   high byte of the VRAM address ($00 - $3F)
; @in   a   high byte of the address with the command bits set
;====
.macro "utils.vdp._setCommand" args command
    utils.assert.oneOf command, utils.vdp.commands.READ_VRAM, utils.vdp.commands.WRITE_VRAM, "\.: Invalid command argument"

    .if command == utils.vdp.commands.READ_VRAM
        ; Reset high bits
        and utils.vdp.commands.READ_VRAM
    .elif command == utils.vdp.commands.WRITE_VRAM
        ; Set bit 6; if address is correct bit 7 should already by reset
        or utils.vdp.commands.WRITE_VRAM
    .endif
.endm

;====
; Prepare a VRAM read or write to the address stored in HL. Port C must be set
; to utils.vdp.DATA_PORT before you can read or write the data
;
; @in   hl                  VRAM address ($0000 - $3FFF)
; @in   [command]           utils.vdp.command.READ_VRAM or utils.vdp.command.WRITE_VRAM
;                           if not present, H should already have the correct
;                           command bits (6th and 7th) set or reset.
;                           (%00 = read; %01 = write)
; @out  VRAM write address  VRAM address with command bits set
;====
.macro "utils.vdp.setCommandHL" args command
    .ifdef command
        utils.assert.oneOf command, utils.vdp.commands.READ_VRAM, utils.vdp.commands.WRITE_VRAM, "\.: Invalid command argument"
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
; @in   [command]           utils.vdp.command.READ_VRAM or utils.vdp.command.WRITE_VRAM
;                           if not present, D should already have the correct
;                           command bits (6th and 7th) set or reset.
;                           (%00 = read; %01 = write)
; @out  VRAM write address  VRAM address with command bits set
;====
.macro "utils.vdp.setCommandDE" args command
    .ifdef command
        utils.assert.oneOf command, utils.vdp.commands.READ_VRAM, utils.vdp.commands.WRITE_VRAM, "\.: Invalid command argument"
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
; Zeroes the VRAM
;
; @in   vram    address and command set
; @in   bc      number of bytes to clear
;====
.section "utils.vdp.writeZeroes" free
    utils.vdp.writeZeroes:
        -:
            xor a
            out (utils.vdp.DATA_PORT), a ; output + increment VRAM address
            dec bc
            ld a, b
            or c
        jp nz, -
    ret
.ends

;====
; Macro alias for call utils.vdp.writeZeroes
;
; @in   bytes       number of bytes to clear/set to zero (defaults to $4000 - all VRAM)
;====
.macro "utils.vdp.writeZeroes" args bytes
    ; Default bytes parameter
    .ifndef bytes
        .define bytes $4000
    .else
        utils.assert.range bytes 0, $4000, "\.: bytes out of VRAM range"
    .endif

    utils.clobbers "bc"
        ld bc, bytes
        call utils.vdp.writeZeroes
    utils.clobbers.end
.endm

;====
; Sets the value of the given VDP register
;
; @in   registerNumber  the register number (0-10)
; @in   a|registerValue the register value
;====
.macro "utils.vdp.setRegister" args registerNumber registerValue
    utils.assert.range registerNumber, 0, 10, "\.: Invalid register number"

    utils.clobbers "af"
        ; Load A with value if one is given
        .ifdef registerValue
            utils.registers.loadA registerValue
        .endif

        ; Send the register value
        out (utils.vdp.COMMAND_PORT), a

        ; Send register number, ORed with WRITE_REGISTER command
        ld a, utils.vdp.commands.WRITE_REGISTER | registerNumber
        out (utils.vdp.COMMAND_PORT), a
    utils.clobbers.end
.endm

;====
; Writes a byte to the data port and increments the write address
;
; @in   value   the value to write
; @in   VRAM    pointer to address (with write command set)
; @out  VRAM    pointer to given address + 1
;====
.macro "utils.vdp.writeByte" args value
    .ifndef value
        out (utils.vdp.DATA_PORT), a
    .else
        utils.assert.range value, 0, 255, "\.: Value out of byte range"

        utils.clobbers "af"
            utils.registers.loadA value

            ; Output and increment VRAM address
            out (utils.vdp.DATA_PORT), a
        utils.clobbers.end
    .endif
.endm
