;====
; Manages the VDP registers
;====

;====
; Default register values
;====
.define vdpreg.register0Default     %00000110;  Mode control 1
                                    ;|||||||`-  Sync enable; always 0
                                    ;||||||`--  Extra height enable/TMS9918 mode select; always 1
                                    ;|||||`---  Mode 4 enable; always 1
                                    ;||||`----  Shift sprites left 8 pixels
                                    ;|||`-----  Enable line interrupts
                                    ;||`------  Hide leftmost 8 pixels
                                    ;|`-------  Horizontal scroll lock
                                    ;`--------  Vertical scroll lock

.define vdpreg.register1Default     %10000000;  Mode control 2
                                    ;|||||||`-  Zoomed sprites -> 16x16 pixels
                                    ;||||||`--  Doubled sprites -> 2 tiles per sprite, 8x16
                                    ;|||||`---  Mega Drive mode 5 enable
                                    ;||||`----  30 row/240 line mode (SMS2 only)
                                    ;|||`-----  28 row/224 line mode (SMS2 only)
                                    ;||`------  Enable VBlank interrupts
                                    ;|`-------  Enable display
                                    ;`--------  Unused; always 1

.define vdpreg.register2Default     %11111111;  Tilemap base address (default = $3800)
                                    ;|||||||`-  Mask bit (SMS1)
                                    ;```````--  Name table base address

.define vdpreg.register3Default     %11111111   ; Palette base address (always $ff for SMS1)
.define vdpreg.register4Default     %00000111   ; Pattern base address (last 3 bits always set for SMS1)
.define vdpreg.register5Default     %11111111   ; Sprite table base address (usually $ff)
.define vdpreg.register6Default     %11111111   ; Sprite pattern generator base address (always $ff)
.define vdpreg.register7Default     %00000000   ; Overscan/backdrop color slot (bits 0-3)
.define vdpreg.register8Default     %00000000   ; Background X scroll
.define vdpreg.register9Default     %00000000   ; Background Y scroll
.define vdpreg.register10Default    %11111111   ; Line interrupt counter

;====
; Constants
;====
.define vdpreg.COMMAND_PORT             $bf   ; write (issue command to vdp)
.define vdpreg.ENABLE_HBLANK            %00010000
.define vdpreg.HIDE_LEFT_COLUMN         %00100000
.define vdpreg.ENABLE_DISPLAY           %01000000
.define vdpreg.ENABLE_TALL_SPRITES      %00000010
.define vdpreg.ENABLE_VBLANK            %00100000
.define vdpreg.LOCK_H_SCROLL            %01000000
.define vdpreg.LOCK_V_SCROLL            %10000000
.define vdpreg.ZOOM_SPRITES             %00000001

;====
; Write the given data bytes to the VDP registers. The data should be data
; bytes in value : (register number + $80) pairs
; i.e. .db $ff, $81 sets the value $ff register 1
;
; @in   start   start address of the data
; @in   end     end address of the data
; @clobs        bc, hl
;====
.macro "vdpreg.load" args start end
    ld hl, start
    ld c, vdpreg.COMMAND_PORT
    ld b, end - start
    otir
.endm

;====
; Defines the default register values ready to be loaded with vdpreg.load
;====
.section "vdpreg.initData" free
    vdpreg.initData:
        .db vdpreg.register0Default, $80
        .db vdpreg.register1Default, $81
        .db vdpreg.register2Default, $82
        .db vdpreg.register3Default, $83
        .db vdpreg.register4Default, $84
        .db vdpreg.register5Default, $85
        .db vdpreg.register6Default, $86
        .db vdpreg.register7Default, $87
        .db vdpreg.register8Default, $88
        .db vdpreg.register9Default, $89
        .db vdpreg.register10Default, $8a
    vdpreg.initDataEnd:
.ends

;====
; Initialises the vdp registers with sensible defaults
;====
.macro "vdpreg.init"
    vdpreg.load vdpreg.initData, vdpreg.initDataEnd
.endm

;====
; Sets the value of the given register
;
; @in   number  the register number (0-10)
; @in   value   the register value
;====
.macro "vdpreg.setRegister" args number value
    ld a, value
    out (vdpreg.COMMAND_PORT), a
    ld a, $80 + number
    out (vdpreg.COMMAND_PORT), a
.endm

;====
; Set the value of register 0 (Mode Control 1)
;
; Usage: vdpreg.setRegister0 vdpreg.ENABLE_HBLANK | vdpreg.HIDE_LEFT_COLUMN
;
; @in value     accepts the following options which can be ORed together (|).
;               Any options that are not passed are set back to their
;               default off setting
;
; Options:
;   vdpreg.ENABLE_HBLANK
;       Enable HBlank interrupts, which occur after each scan line is drawn
;
;   vdpreg.HIDE_LEFT_COLUMN
;       Hide the left-most column (8-pixels). Useful to allow sprites to move
;       on/off  the left-side of the screen smoothly
;
;   vdpreg.LOCK_H_SCROLL
;       Stops the top two rows scrolling horizontally. They can however still
;       scroll vertically which can cause unwanted effects. Often used to
;       implement status bars
;
;   vdpreg.LOCK_V_SCROLL
;       Stops the right-most 8 columns scrolling vertically. They can however
;       still scroll horizontally which can cause unwanted effects. Often used
;       to implement status bars
;====
.macro "vdpreg.setRegister0" args value
    vdpreg.setRegister 0 (vdpreg.register0Default | value)
.endm

;====
; Set the value of register 1 (Mode Control 2)
;
; Usage: vdpreg.setRegister1 vdpreg.ENABLE_DISPLAY | vdpreg.ENABLE_VBLANK
;
; @in value     accepts the following options which can be ORed together (|).
;               Any options that are not passed are set back to their
;               default off setting
;
; Options:
;   vdpreg.ENABLE_DISPLAY
;
;   vdpreg.ENABLE_TALL_SPRITES
;       Sets all sprites to be 2-tiles high. The sprite's pattern number
;       rounded down to the nearest multiple of 2 will be used for the
;       bottom sprite and the next pattern in the table will be used for the
;       top
;
;   vdpreg.ENABLE_VBLANK
;       Enable the display
;
;   vdpreg.ZOOM_SPRITES
;       Renders each sprite pixel as 2x2 pixels. Note: SMS1 can only display
;       the first 4 sprites per scanline in this way, and the rest on the
;       scanline will only be zoomed vertically
;====
.macro "vdpreg.setRegister1" args value
    vdpreg.setRegister 1 (vdpreg.register1Default | value)
.endm

;====
; Sets the overscan/border colour
;
; @in   value   the palette slot to use. This is taken from the sprite palette,
;               so 0 = slot 16, 15 = slot 31
;====
.macro "vdpreg.setBackgroundColor" args value
    vdpreg.setRegister 7 value
.endm

;====
; Sets the line interrupt counter
;
; @in   value
;====
.macro "vdpreg.setLineCounter" args value
    vdpreg.setRegister 10 value
.endm

;====
; Sets the background horizontal scroll value
;
; @in   value
;====
.macro "vdpreg.setScrollX" args value
    vdpreg.setRegister 8 value
.endm

;====
; Sets the background horizontal scroll value
;
; @in   value
;====
.macro "vdpreg.setScrollY" args value
    vdpreg.setRegister 9 value
.endm
