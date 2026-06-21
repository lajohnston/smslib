;====
; Sets the VDP commands, such as read/write VRAM
;====

.define utils.vdpCommand 1

;====
; Constants
;====
.define utils.vdpCommand.COMMAND_PORT $bf
.define utils.vdpCommand.WRITE_VRAM %01000000   ; OR mask

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
        ld a, >address | utils.vdpCommand.WRITE_VRAM
        out (utils.vdpCommand.COMMAND_PORT), a
    utils.clobbers.end
.endm
