;====
; Manages the VDP registers
;====

.define vdpSettings.ENABLED 1

;====
; Dependencies
;====
.ifndef utils.ram
    .include "utils/ram.asm"
    utils.ram.assertRamSlot
.endif

.ifndef utils.vdpCommand
    .include "utils/vdpCommand.asm"
.endif

;====
; Default register values
;====
.define vdpSettings.REGISTER_0_DEFAULT  %00000110;  Mode control 1
                                        ;|||||||`-  Sync enable; always 0
                                        ;||||||`--  Extra height enable/TMS9918 mode select; always 1
                                        ;|||||`---  Mode 4 enable; always 1
                                        ;||||`----  Shift sprites left 8 pixels
                                        ;|||`-----  Enable line interrupts
                                        ;||`------  Hide leftmost 8 pixels
                                        ;|`-------  Horizontal scroll lock
                                        ;`--------  Vertical scroll lock

.define vdpSettings.REGISTER_1_DEFAULT  %10100000;  Mode control 2
                                        ;|||||||`-  Zoomed sprites -> 16x16 pixels
                                        ;||||||`--  Tall sprites -> 2 tiles per sprite, 8x16
                                        ;|||||`---  Mega Drive mode 5 enable
                                        ;||||`----  30 row/240 line mode (SMS2 only)
                                        ;|||`-----  28 row/224 line mode (SMS2 only)
                                        ;||`------  Enable VBlank interrupts
                                        ;|`-------  Enable display
                                        ;`--------  Unused; always 1

.define vdpSettings.REGISTER_2_DEFAULT  %11111111;  Tilemap base address (default = $3800)
                                        ;|||||||`-  Mask bit (SMS1)
                                        ;```````--  Name table base address

.define vdpSettings.REGISTER_3_DEFAULT  %11111111   ; Palette base address (always $ff for SMS1)
.define vdpSettings.REGISTER_4_DEFAULT  %00000111   ; Pattern base address (last 3 bits always set for SMS1)
.define vdpSettings.REGISTER_5_DEFAULT  %11111111   ; Sprite table base address (usually $ff)
.define vdpSettings.REGISTER_6_DEFAULT  %11111111   ; Sprite pattern generator base address (always $ff)
.define vdpSettings.REGISTER_7_DEFAULT  %00000000   ; Overscan/backdrop color index (bits 0-3)
.define vdpSettings.REGISTER_8_DEFAULT  %00000000   ; Background X scroll
.define vdpSettings.REGISTER_9_DEFAULT  %00000000   ; Background Y scroll
.define vdpSettings.REGISTER_10_DEFAULT %11111111   ; Line interrupt counter

.define vdpSettings.BORDER_COLOR_REGISTER 7
.define vdpSettings.SCROLL_X_REGISTER 8
.define vdpSettings.SCROLL_Y_REGISTER 9
.define vdpSettings.LINE_COUNTER_REGISTER 10

;====
; Batch variables
; Batches setting changes so they can be applied together
;====
.define vdpSettings.batchInProgress 0

; Pending register 0 changes
.define vdpSettings.batchRegister0Enable    0
.define vdpSettings.batchRegister0Disable   0

; Pending register 1 changes
.define vdpSettings.batchRegister1Enable    0
.define vdpSettings.batchRegister1Disable   0

;====
; Constants
;====
.define vdpSettings.COMMAND_PORT             $bf   ; write (issue command to vdp)

;====
; RAM
;====

; Buffer for setting the mode control registers, to allow settings to be changed
; without overwriting existing ones
.ramsection "vdpSettings.ram" slot utils.ram.SLOT
    vdpSettings.ram.register0Buffer: db
    vdpSettings.ram.register1Buffer: db
.ends

;====
; Defines the default register values ready to be written with vdpSettings.writeRegisters
;====
.section "vdpSettings.initData" free
    vdpSettings.initData:
        .db vdpSettings.REGISTER_0_DEFAULT, $80
        .db vdpSettings.REGISTER_1_DEFAULT, $81
        .db vdpSettings.REGISTER_2_DEFAULT, $82
        .db vdpSettings.REGISTER_3_DEFAULT, $83
        .db vdpSettings.REGISTER_4_DEFAULT, $84
        .db vdpSettings.REGISTER_5_DEFAULT, $85
        .db vdpSettings.REGISTER_6_DEFAULT, $86
        .db vdpSettings.REGISTER_7_DEFAULT, $87
        .db vdpSettings.REGISTER_8_DEFAULT, $88
        .db vdpSettings.REGISTER_9_DEFAULT, $89
        .db vdpSettings.REGISTER_10_DEFAULT, $8a
    vdpSettings.initDataEnd:
.ends

;====
; Initialises the vdp registers with sensible defaults
;====
.macro "vdpSettings.init"
    vdpSettings.writeRegisters vdpSettings.initData, vdpSettings.initDataEnd

    ; Set register buffers
    ld a, vdpSettings.REGISTER_0_DEFAULT
    ld (vdpSettings.ram.register0Buffer), a

    ld a, vdpSettings.REGISTER_1_DEFAULT
    ld (vdpSettings.ram.register1Buffer), a
.endm

;====
; Write the given data bytes to the VDP registers. The data should be data
; bytes in value : (register number + $80) pairs
; i.e. .db $ff, $81 sets the value $ff register 1
;
; @in   start   start address of the data
; @in   end     end address of the data
; @clobs        bc, hl
;====
.macro "vdpSettings.writeRegisters" args start end
    ld hl, start
    ld c, vdpSettings.COMMAND_PORT
    ld b, end - start
    otir
.endm

;====
; Begins a batch of setting changes for registers 0 and 1. Once the changes have
; been specified the batch can be ended/applied using vdpSettings.endBatch
;====
.macro "vdpSettings.startBatch"
    .ifeq vdpSettings.batchInProgress 1
        .print "vdpSettings.startBatch: Batch already in progress."
        .print " Ensure you also call vdpSettings.endBatch\n\n"
    .endif

    .redefine vdpSettings.batchInProgress 1
.endm

;====
; Applies the pending changes specified since calling vdpSettings.startBatch
;====
.macro "vdpSettings.endBatch"
    vdpSettings._applyBatch
.endm

;====
; Enable the display
;====
.macro "vdpSettings.enableDisplay"
    vdpSettings._addSettingToBatch 1 $40 1
.endm

;====
; Disable the display
;====
.macro "vdpSettings.disableDisplay"
    vdpSettings._addSettingToBatch 1 $40 0
.endm

;====
; Enables frame interrupts, which occur when a frame has finished being drawn
;====
.macro "vdpSettings.enableVBlank"
    vdpSettings._addSettingToBatch 1 $20 1
.endm

;====
; Disables frame interrupts
;====
.macro "vdpSettings.disableVBlank"
    vdpSettings._addSettingToBatch 1 $20 0
.endm

;====
; Sets all sprites to be 2-tiles high. The bottom sprite will be the sprite's
; pattern number rounded down to the nearest even number. The top sprite will be
; the next pattern (odd number)
;====
.macro "vdpSettings.enableTallSprites"
    vdpSettings._addSettingToBatch 1 $02 1
.endm

;====
; Disables tall sprites
;====
.macro "vdpSettings.disableTallSprites"
    vdpSettings._addSettingToBatch 1 $02 0
.endm

;====
; Renders each sprite pixel as 2x2 pixels. Note: SMS1 can only display the first
; 4 sprites per scanline in this way, and the rest on the scanline will only be
; zoomed vertically leading to distortion
;====
.macro "vdpSettings.enableSpriteZoom"
    vdpSettings._addSettingToBatch 1 $01 1
.endm

;====
; Disables zoomed sprites
;====
.macro "vdpSettings.disableSpriteZoom"
    vdpSettings._addSettingToBatch 1 $01 0
.endm

;====
; Enable horizontal blank interrupts, which occur when the line counter falls
; below 0. The line counter can be set using vdpSettings.setLineCounter. The counter
; is decremented after each line is drawn
;====
.macro "vdpSettings.enableHBlank"
    vdpSettings._addSettingToBatch 0 $10 1
.endm

;====
; Disables line interrupts
;====
.macro "vdpSettings.disableHBlank"
    vdpSettings._addSettingToBatch 0 $10 0
.endm

;====
; Shift all sprites 8-pixels to the left. Useful to allow sprites to move
; on/off the left-side of the screen smoothly, as an alternative to
; vdpSettings.hideLeftColumn
;====
.macro "vdpSettings.enableSpriteShift"
    vdpSettings._addSettingToBatch 0 $08 1
.endm

;====
; Disables the option to shift sprite positions to the left. This is the default
; behaviour
;====
.macro "vdpSettings.disableSpriteShift"
    vdpSettings._addSettingToBatch 0 $08 0
.endm

;====
; Hide the left-most column (8-pixels). Useful to allow sprites to move on/off
; the left-side of the screen smoothly as an alternative to vdpSettings.shiftSprites
;====
.macro "vdpSettings.hideLeftColumn"
    vdpSettings._addSettingToBatch 0 $20 1
.endm

;====
; Displays the left-most column (the default)
;====
.macro "vdpSettings.showLeftColumn"
    vdpSettings._addSettingToBatch 0 $20 0
.endm

;====
; Stops the top two rows scrolling horizontally. They can however still scroll
; vertically which can cause unwanted effects. Often used to implement status
; bars
;====
.macro "vdpSettings.lockHScroll"
    vdpSettings._addSettingToBatch 0 $40 1
.endm

;====
; Allows the top two rows to scroll horizontally (the default)
;====
.macro "vdpSettings.unlockHScroll"
    vdpSettings._addSettingToBatch 0 $40 0
.endm

;====
; Stops the right-most 8 columns scrolling vertically. They can however still
; scroll horizontally which can cause unwanted effects. Often used to implement
; status bars
;====
.macro "vdpSettings.lockVScroll"
    vdpSettings._addSettingToBatch 0 $80 1
.endm

;====
; Allows the right-most 8-columns to scroll vertically (the default)
;====
.macro "vdpSettings.unlockVScroll"
    vdpSettings._addSettingToBatch 0 $80 0
.endm

;====
; Sets the overscan/border color
;
; @in   value   the palette index to use. Must be index 16-31 (the sprite palette)
;====
.macro "vdpSettings.setBorderColorIndex" args value
    .if value < 16
        .redefine value 16
        .print "Warning: vdpSettings.setBorderColorIndex value must be between 16 and 31\n"
    .endif

    utils.vdpCommand.setRegister tilemap.BORDER_COLOR_REGISTER (value - 16)
.endm

;====
; Sets the background horizontal scroll value. Decreasing the value moves
; the screen from right to left
;
; @in   a|value the register value
;====
.macro "vdpSettings.setScrollX" args value
    .ifdef value
        utils.vdpCommand.setRegister vdpSettings.SCROLL_X_REGISTER value
    .else
        utils.vdpCommand.setRegister vdpSettings.SCROLL_X_REGISTER
    .endif
.endm

;====
; Sets the background vertical scroll value. Value should be between 0-223 for
; the standard 192-line mode
;
; @in   a|value the register value
;====
.macro "vdpSettings.setScrollY" args value
    .ifdef value
        utils.vdpCommand.setRegister vdpSettings.SCROLL_Y_REGISTER value
    .else
        utils.vdpCommand.setRegister vdpSettings.SCROLL_Y_REGISTER
    .endif
.endm

;====
; Sets the line interrupt counter
;
; @in   a|value the register value
;====
.macro "vdpSettings.setLineCounter" args value
    .ifdef value
        utils.vdpCommand.setRegister vdpSettings.LINE_COUNTER_REGISTER value
    .else
        utils.vdpCommand.setRegister vdpSettings.LINE_COUNTER_REGISTER
    .endif
.endm

;====
; Applies batched changes for the given register
;
; @in   de          the address of the register's buffer
; @in   register    the register number (0 or 1)
; @in   enableMask  the bits to set (bits that are set will be set to 1)
; @in   disableMask the bits to reset (bits that are set will be set to 0)
;====
.macro "vdpSettings._applyRegisterBatch" args register enableMask disableMask
    ; Load bufferer value
    ld a, (de)

    ; Apply pending enables
    .if enableMask > 0
        or enableMask
    .endif

    ; Apply pending disables
    .if disableMask > 0
        and (disableMask ~ $ff) ; negate mask
    .endif

    ; Save updated value to buffer
    ld (de), a

    ; Send value to VDP
    utils.vdpCommand.setRegister register
.endm

;====
; Apply batched changes
;====
.macro "vdpSettings._applyBatch"
    ; If changes are pending for register 0
    .if vdpSettings.batchRegister0Enable + vdpSettings.batchRegister0Disable > 0
        ld de, vdpSettings.ram.register0Buffer
        vdpSettings._applyRegisterBatch 0 vdpSettings.batchRegister0Enable vdpSettings.batchRegister0Disable
    .endif

    ; If changes are pending for register 1
    .if vdpSettings.batchRegister1Enable + vdpSettings.batchRegister1Disable > 0
        ; If register 0 was changed, just inc de to point to register1 buffer
        .if vdpSettings.batchRegister0Enable + vdpSettings.batchRegister0Disable > 0
            inc de
        .else
            ld de, vdpSettings.ram.register1Buffer
        .endif

        vdpSettings._applyRegisterBatch 1 vdpSettings.batchRegister1Enable vdpSettings.batchRegister1Disable
    .endif

    ; Reset mask buffers
    .redefine vdpSettings.batchInProgress        0
    .redefine vdpSettings.batchRegister0Enable   0
    .redefine vdpSettings.batchRegister0Disable  0
    .redefine vdpSettings.batchRegister1Enable   0
    .redefine vdpSettings.batchRegister1Disable  0
.endm

;====
; Adds a setting to the pending batch. If a batch is not in progress the setting
; is sent to the VDP immediately
;
; @in   register    the register number (0 or 1)
; @in   mask        the bit mask to apply to alter the current value with
; @in   value       whether the bits should be set (1) or reset (0)
;====
.macro "vdpSettings._addSettingToBatch" args register mask value
    .if register == 0
        .if value == 1
            .redefine vdpSettings.batchRegister0Enable vdpSettings.batchRegister0Enable|mask
        .else
            .redefine vdpSettings.batchRegister0Disable vdpSettings.batchRegister0Disable|mask
        .endif
    .endif

    .if register == 1
        .if value == 1
            .redefine vdpSettings.batchRegister1Enable vdpSettings.batchRegister1Enable|mask
        .else
            .redefine vdpSettings.batchRegister1Disable vdpSettings.batchRegister1Disable|mask
        .endif
    .endif

    ; If batch not in progress, apply changes now
    .if vdpSettings.batchInProgress == 0
        vdpSettings._applyBatch
    .endif
.endm
