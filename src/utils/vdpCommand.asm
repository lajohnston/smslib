;====
; Sets the VDP commands, such as read/write VRAM
;====

.define utils.vdpCommand 1

;====
; Constants
;====

; Ports
.define utils.vdpCommand.COMMAND_PORT $bf
.define utils.vdpCommand.DATA_PORT $be

; Commands
.define utils.vdpCommand.READ_VRAM      %00111111   ; AND mask
.define utils.vdpCommand.WRITE_VRAM     %01000000   ; OR mask
.define utils.vdpCommand.WRITE_CRAM     %11000000   ; Constant
.define utils.vdpCommand.WRITE_REGISTER %10000000   ; OR mask

;====
; Dependencies
;====
.ifndef utils.registers
    .include "utils/registers.asm"
.endif

;====
; Sets the VRAM write address
;
; @in   address     the VRAM write address
;====
.macro "utils.vdpCommand.setVramWriteAddress" args address
    utils.assert.range address 0 $3fff "\.: Address should be a valid VRAM address"

    utils.clobbers "af"
        ; Output low byte to VDP
        utils.registers.loadA <address
        out (utils.vdpCommand.COMMAND_PORT), a

        ; Output high byte to VDP with write command set
        utils.registers.transformA <address, >address | utils.vdpCommand.WRITE_VRAM
        out (utils.vdpCommand.COMMAND_PORT), a
    utils.clobbers.end
.endm

;====
; Sets the write address to the given Color RAM address/index
;
; @in   address     the color RAM write address (0-31)
;====
.macro "utils.vdpCommand.setColorRamWriteAddress" args address
    utils.assert.range address 0, 31, "\.: Address must be between 0-31"

    utils.clobbers "af"
        ; Output address
        utils.registers.loadA address
        out (utils.vdpCommand.COMMAND_PORT), a

        ; Output CRAM write command
        utils.registers.transformA address, utils.vdpCommand.WRITE_CRAM
        out (utils.vdpCommand.COMMAND_PORT), a
    utils.clobbers.end
.endm

;====
; Sets the value of the given VDP register
;
; @in   registerNumber  the register number (0-10)
; @in   a|registerValue the register value
;====
.macro "utils.vdpCommand.setRegister" args registerNumber registerValue
    utils.assert.range registerNumber, 0, 10, "\.: Invalid register number"

    utils.clobbers "af"
        ; Load A with value if one is given
        .ifdef registerValue
            utils.registers.loadA registerValue
        .endif

        ; Send the register value
        out (utils.vdpCommand.COMMAND_PORT), a

        ; Send register number, ORed with WRITE_REGISTER command
        .ifdef registerValue
            utils.registers.transformA registerValue, utils.vdpCommand.WRITE_REGISTER | registerNumber
        .else
            ld a, utils.vdpCommand.WRITE_REGISTER | registerNumber
        .endif

        out (utils.vdpCommand.COMMAND_PORT), a
    utils.clobbers.end
.endm

;====
; Sets the command bits on the high byte of the VRAM address
;
; @in   a   high byte of the VRAM address ($00 - $3F)
; @in   a   high byte of the address with the command bits set
;====
.macro "utils.vdpCommand._setCommandBits" args command
    utils.assert.oneOf command, utils.vdpCommand.READ_VRAM, utils.vdpCommand.WRITE_VRAM, utils.vdpCommand.WRITE_CRAM, utils.vdpCommand.WRITE_REGISTER, "\.: Invalid command argument"

    utils.clobbers "af"
        .if command == utils.vdpCommand.READ_VRAM
            ; Reset high bits
            and utils.vdpCommand.READ_VRAM
        .elif command == utils.vdpCommand.WRITE_VRAM
            ; Set bit 6; if address is correct, bit 7 should already by reset
            or utils.vdpCommand.WRITE_VRAM
        .elif command == utils.vdpCommand.WRITE_CRAM
            ld a, utils.vdpCommand.WRITE_CRAM
        .elif command == utils.vdpCommand.WRITE_REGISTER
            ld a, utils.vdpCommand.WRITE_REGISTER
        .endif
    utils.clobbers.end
.endm

;====
; Set a VDP operation as stored in HL. The 6th and 7th bits of the high byte
; should be set to the command (see below), otherwise pass the command argument
; to have these set at runtime.
;
; VRAM read - HL should be set to the VRAM address. The 6th and 7th bits of the
; high byte should be reset (%00xxxxxx).
;
; VRAM write - HL should be set to the VRAM address. The 6th bit of the high
; byte should be set and the 7th bit should be reset (%01xxxxxx).
;
; Register write - L should be set to the register number (0-10). H should be
; $80.
;
; Color RAM write - L is the index (0-31). H should be $c0
;
; @in   hl                  the operation to perform
; @in   [command]           (optional) one of:
;                               utils.vdpCommand.READ_VRAM
;                               utils.vdpCommand.WRITE_VRAM
;                               utils.vdpCommand.WRITE_CRAM
;                               utils.vdpCommand.WRITE_REGISTER
;
;                           if not present, H should already have the correct
;                           command bits (6th and 7th) set or reset.
; @out  VDP write address   for VRAM read/write or CRAM write, the VDP write
;                           address will be set
;====
.macro "utils.vdpCommand.setFromHl" args command
    .ifdef command
        utils.assert.oneOf command, utils.vdpCommand.READ_VRAM, utils.vdpCommand.WRITE_VRAM, utils.vdpCommand.WRITE_CRAM, utils.vdpCommand.WRITE_REGISTER, "\.: Invalid command argument"
    .endif

    utils.clobbers "af"
        ; Output low byte to VDP
        ld a, l
        out (utils.vdpCommand.COMMAND_PORT), a  ; output low byte

        ; Load high byte into A
        ld a, h

        .ifdef command
            utils.vdpCommand._setCommandBits command
        .endif

        ; Output high address byte + command
        out (utils.vdpCommand.COMMAND_PORT), a
    utils.clobbers.end
.endm

;====
; Set a VDP operation as stored in DE (see utils.vdpCommand.setFromHl)
;====
.macro "utils.vdpCommand.setFromDe" args command
    .ifdef command
        utils.assert.oneOf command, utils.vdpCommand.READ_VRAM, utils.vdpCommand.WRITE_VRAM, utils.vdpCommand.WRITE_CRAM, utils.vdpCommand.WRITE_REGISTER, "\.: Invalid command argument"
    .endif

    utils.clobbers "af"
        ; Output low byte to VDP
        ld a, e
        out (utils.vdpCommand.COMMAND_PORT), a  ; output low byte

        ; Load high byte into A
        ld a, d

        .ifdef command
            utils.vdpCommand._setCommandBits command
        .endif

        ; Output high address byte + command
        out (utils.vdpCommand.COMMAND_PORT), a
    utils.clobbers.end
.endm
