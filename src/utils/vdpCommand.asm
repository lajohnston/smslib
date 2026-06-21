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
