;====
; Manages the VDP registers
;====

.define vdp.ENABLED 1

;====
; Dependencies
;====
.ifndef utils.ram
    .include "utils/ram.asm"
    utils.ram.assertRamSlot
.endif

.ifndef utils.vdp
    .include "utils/vdp.asm"
.endif

;====
; Default register values
;====
.define vdp.REGISTER_0_DEFAULT  %00000110;  Mode control 1
                                ;|||||||`-  Sync enable; always 0
                                ;||||||`--  Extra height enable/TMS9918 mode select; always 1
                                ;|||||`---  Mode 4 enable; always 1
                                ;||||`----  Shift sprites left 8 pixels
                                ;|||`-----  Enable line interrupts
                                ;||`------  Hide leftmost 8 pixels
                                ;|`-------  Horizontal scroll lock
                                ;`--------  Vertical scroll lock

.define vdp.REGISTER_1_DEFAULT  %10000000;  Mode control 2
                                ;|||||||`-  Zoomed sprites -> 16x16 pixels
                                ;||||||`--  Tall sprites -> 2 tiles per sprite, 8x16
                                ;|||||`---  Mega Drive mode 5 enable
                                ;||||`----  30 row/240 line mode (SMS2 only)
                                ;|||`-----  28 row/224 line mode (SMS2 only)
                                ;||`------  Enable VBlank interrupts
                                ;|`-------  Enable display
                                ;`--------  Unused; always 1

.define vdp.REGISTER_2_DEFAULT  %11111111;  Tilemap base address (default = $3800)
                                ;|||||||`-  Mask bit (SMS1)
                                ;```````--  Name table base address

.define vdp.REGISTER_3_DEFAULT  %11111111   ; Palette base address (always $ff for SMS1)
.define vdp.REGISTER_4_DEFAULT  %00000111   ; Pattern base address (last 3 bits always set for SMS1)
.define vdp.REGISTER_5_DEFAULT  %11111111   ; Sprite table base address (usually $ff)
.define vdp.REGISTER_6_DEFAULT  %11111111   ; Sprite pattern generator base address (always $ff)
.define vdp.REGISTER_7_DEFAULT  %00000000   ; Overscan/backdrop color index (bits 0-3)
.define vdp.REGISTER_8_DEFAULT  %00000000   ; Background X scroll
.define vdp.REGISTER_9_DEFAULT  %00000000   ; Background Y scroll
.define vdp.REGISTER_10_DEFAULT %11111111   ; Line interrupt counter

;====
; Batch variables
; Batches setting changes so they can be applied together
;====
.define vdp.batchInProgress 0

; Pending register 0 changes
.define vdp.batchRegister0Enable    0
.define vdp.batchRegister0Disable   0

; Pending register 1 changes
.define vdp.batchRegister1Enable    0
.define vdp.batchRegister1Disable   0

;====
; Constants
;====
.define vdp.COMMAND_PORT             $bf   ; write (issue command to vdp)

;====
; RAM
;====

; Buffer for setting the mode control registers, to allow settings to be changed
; without overwriting existing ones
.ramsection "vdp.ram" slot utils.ram.SLOT
    vdp.ram.register0Buffer: db
    vdp.ram.register1Buffer: db
.ends

;====
; Defines the default register values ready to be written with vdp.writeRegisters
;====
.section "vdp.initData" free
    vdp.initData:
        .db vdp.REGISTER_0_DEFAULT, $80
        .db vdp.REGISTER_1_DEFAULT, $81
        .db vdp.REGISTER_2_DEFAULT, $82
        .db vdp.REGISTER_3_DEFAULT, $83
        .db vdp.REGISTER_4_DEFAULT, $84
        .db vdp.REGISTER_5_DEFAULT, $85
        .db vdp.REGISTER_6_DEFAULT, $86
        .db vdp.REGISTER_7_DEFAULT, $87
        .db vdp.REGISTER_8_DEFAULT, $88
        .db vdp.REGISTER_9_DEFAULT, $89
        .db vdp.REGISTER_10_DEFAULT, $8a
    vdp.initDataEnd:
.ends

;====
; Initialises the vdp registers with sensible defaults
;====
.macro "vdp.init"
    vdp.writeRegisters vdp.initData, vdp.initDataEnd

    ; Set register buffers
    ld a, vdp.REGISTER_0_DEFAULT
    ld (vdp.ram.register0Buffer), a

    ld a, vdp.REGISTER_1_DEFAULT
    ld (vdp.ram.register1Buffer), a
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
.macro "vdp.writeRegisters" args start end
    ld hl, start
    ld c, vdp.COMMAND_PORT
    ld b, end - start
    otir
.endm

;====
; Begins a batch of setting changes for registers 0 and 1. Once the changes have
; been specified the batch can be ended/applied using vdp.endBatch
;====
.macro "vdp.startBatch"
    .ifeq vdp.batchInProgress 1
        .print "vdp.startBatch: Batch already in progress."
        .print " Ensure you also call vdp.endBatch\n\n"
    .endif

    .redefine vdp.batchInProgress 1
.endm

;====
; Applies the pending changes specified since calling vdp.startBatch
;====
.macro "vdp.endBatch"
    vdp._applyBatch
.endm

;====
; Enable the display
;====
.macro "vdp.enableDisplay"
    vdp._addSettingToBatch 1 $40 1
.endm

;====
; Disable the display
;====
.macro "vdp.disableDisplay"
    vdp._addSettingToBatch 1 $40 0
.endm

;====
; Enables frame interrupts, which occur when a frame has finished being drawn
;====
.macro "vdp.enableVBlank"
    vdp._addSettingToBatch 1 $20 1
.endm

;====
; Disables frame interrupts
;====
.macro "vdp.disableVBlank"
    vdp._addSettingToBatch 1 $20 0
.endm

;====
; Sets all sprites to be 2-tiles high. The bottom sprite will be the sprite's
; pattern number rounded down to the nearest even number. The top sprite will be
; the next pattern (odd number)
;====
.macro "vdp.enableTallSprites"
    vdp._addSettingToBatch 1 $02 1
.endm

;====
; Disables tall sprites
;====
.macro "vdp.disableTallSprites"
    vdp._addSettingToBatch 1 $02 0
.endm

;====
; Renders each sprite pixel as 2x2 pixels. Note: SMS1 can only display the first
; 4 sprites per scanline in this way, and the rest on the scanline will only be
; zoomed vertically leading to distortion
;====
.macro "vdp.enableSpriteZoom"
    vdp._addSettingToBatch 1 $01 1
.endm

;====
; Disables zoomed sprites
;====
.macro "vdp.disableSpriteZoom"
    vdp._addSettingToBatch 1 $01 0
.endm

;====
; Enable horizontal blank interrupts, which occur when the line counter falls
; below 0. The line counter can be set using vdp.setLineCounter. The counter
; is decremented after each line is drawn
;====
.macro "vdp.enableHBlank"
    vdp._addSettingToBatch 0 $10 1
.endm

;====
; Disables line interrupts
;====
.macro "vdp.disableHBlank"
    vdp._addSettingToBatch 0 $10 0
.endm

;====
; Shift all sprites 8-pixels to the left. Useful to allow sprites to move
; on/off the left-side of the screen smoothly, as an alternative to
; vdp.hideLeftColumn
;====
.macro "vdp.enableSpriteShift"
    vdp._addSettingToBatch 0 $08 1
.endm

;====
; Disables the option to shift sprite positions to the left. This is the default
; behaviour
;====
.macro "vdp.disableSpriteShift"
    vdp._addSettingToBatch 0 $08 0
.endm

;====
; Hide the left-most column (8-pixels). Useful to allow sprites to move on/off
; the left-side of the screen smoothly as an alternative to vdp.shiftSprites
;====
.macro "vdp.hideLeftColumn"
    vdp._addSettingToBatch 0 $20 1
.endm

;====
; Displays the left-most column (the default)
;====
.macro "vdp.showLeftColumn"
    vdp._addSettingToBatch 0 $20 0
.endm

;====
; Stops the top two rows scrolling horizontally. They can however still scroll
; vertically which can cause unwanted effects. Often used to implement status
; bars
;====
.macro "vdp.lockHScroll"
    vdp._addSettingToBatch 0 $40 1
.endm

;====
; Allows the top two rows to scroll horizontally (the default)
;====
.macro "vdp.unlockHScroll"
    vdp._addSettingToBatch 0 $40 0
.endm

;====
; Stops the right-most 8 columns scrolling vertically. They can however still
; scroll horizontally which can cause unwanted effects. Often used to implement
; status bars
;====
.macro "vdp.lockVScroll"
    vdp._addSettingToBatch 0 $80 1
.endm

;====
; Allows the right-most 8-columns to scroll vertically (the default)
;====
.macro "vdp.unlockVScroll"
    vdp._addSettingToBatch 0 $80 0
.endm

;====
; Sets the overscan/border color
;
; @in   value   the palette index to use. Must be index 16-31 (the sprite palette)
;====
.macro "vdp.setBorderColorIndex" args value
    .if value < 16
        .redefine value 16
        .print "Warning: vdp.setBorderColorIndex value must be between 16 and 31\n"
    .endif

    utils.vdp.setRegister utils.vdp.BORDER_COLOR_REGISTER (value - 16)
.endm

;====
; Sets the background horizontal scroll value. Decreasing the value moves
; the screen from right to left
;
; @in   a|value the register value
;====
.macro "vdp.setScrollX" args value
    .ifdef value
        utils.vdp.setRegister utils.vdp.SCROLL_X_REGISTER value
    .else
        utils.vdp.setRegister utils.vdp.SCROLL_X_REGISTER
    .endif
.endm

;====
; Sets the background vertical scroll value. Value should be between 0-223 for
; the standard 192-line mode
;
; @in   a|value the register value
;====
.macro "vdp.setScrollY" args value
    .ifdef value
        utils.vdp.setRegister utils.vdp.setRegister utils.vdp.SCROLL_Y_REGISTER value
    .else
        utils.vdp.setRegister utils.vdp.setRegister utils.vdp.SCROLL_Y_REGISTER
    .endif
.endm

;====
; Sets the line interrupt counter
;
; @in   a|value the register value
;====
.macro "vdp.setLineCounter" args value
    .ifdef value
        utils.vdp.setRegister utils.vdp.LINE_COUNTER_REGISTER value
    .else
        utils.vdp.setRegister utils.vdp.LINE_COUNTER_REGISTER
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
.macro "vdp._applyRegisterBatch" args register enableMask disableMask
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
    utils.vdp.setRegister register
.endm

;====
; Apply batched changes
;====
.macro "vdp._applyBatch"
    ; If changes are pending for register 0
    .if vdp.batchRegister0Enable + vdp.batchRegister0Disable > 0
        ld de, vdp.ram.register0Buffer
        vdp._applyRegisterBatch 0 vdp.batchRegister0Enable vdp.batchRegister0Disable
    .endif

    ; If changes are pending for register 1
    .if vdp.batchRegister1Enable + vdp.batchRegister1Disable > 0
        ; If register 0 was changed, just inc de to point to register1 buffer
        .if vdp.batchRegister0Enable + vdp.batchRegister0Disable > 0
            inc de
        .else
            ld de, vdp.ram.register1Buffer
        .endif

        vdp._applyRegisterBatch 1 vdp.batchRegister1Enable vdp.batchRegister1Disable
    .endif

    ; Reset mask buffers
    .redefine vdp.batchInProgress        0
    .redefine vdp.batchRegister0Enable   0
    .redefine vdp.batchRegister0Disable  0
    .redefine vdp.batchRegister1Enable   0
    .redefine vdp.batchRegister1Disable  0
.endm

;====
; Adds a setting to the pending batch. If a batch is not in progress the setting
; is sent to the VDP immediately
;
; @in   register    the register number (0 or 1)
; @in   mask        the bit mask to apply to alter the current value with
; @in   value       whether the bits should be set (1) or reset (0)
;====
.macro "vdp._addSettingToBatch" args register mask value
    .if register == 0
        .if value == 1
            .redefine vdp.batchRegister0Enable vdp.batchRegister0Enable|mask
        .else
            .redefine vdp.batchRegister0Disable vdp.batchRegister0Disable|mask
        .endif
    .endif

    .if register == 1
        .if value == 1
            .redefine vdp.batchRegister1Enable vdp.batchRegister1Enable|mask
        .else
            .redefine vdp.batchRegister1Disable vdp.batchRegister1Disable|mask
        .endif
    .endif

    ; If batch not in progress, apply changes now
    .if vdp.batchInProgress == 0
        vdp._applyBatch
    .endif
.endm
