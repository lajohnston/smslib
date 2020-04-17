;====
; Utility to set VDP settings
;
; Usage:
; Use vdpreg.set to enable or disable a given setting (see Settings below)
; Use vdpreg.apply to send the settings to the VDP
;====

;====
; Settings
; Assigns unique identifiers for each setting. These can be passed to the
; vdpreg.set macro.
;
; Only the commonly used settings are implemented
;====
.enum $00
    ; The color slot in the sprite palette to use for the border (0-15)
    vdpreg.BORDER_PALETTE_SLOT DB

    ; Default: off
    vdpreg.ENABLE_DISPLAY  DB

    ;====
    ; Enable HBlank interrupts
    ; Default: off
    ;====
    vdpreg.ENABLE_HBLANK  DB

    ;====
    ; Sets all sprites to be 2-tiles high. The sprite's pattern number rounded
    ; down to the nearest multiple of 2 will be used for the bottom sprite,
    ; and the next pattern in the table will be used for the top
    ;
    ; Default: off
    ;====
    vdpreg.ENABLE_TALL_SPRITES  DB

    ;====
    ; Enables VBlank interrupts
    ; Default: off
    ;====
    vdpreg.ENABLE_VBLANK DB

    ;====
    ; Useful to allow sprites to move on/off the left side of the screen smoothly
    ; Default: off
    ;====
    vdpreg.HIDE_LEFT_COLUMN    DB

    ;====
    ; The line interrupt counter
    ;====
    vdpreg.LINE_INTERRUPT_COUNTER DB

    ;====
    ; Stops the top two rows scrolling horizontally. They can still scroll vertically
    ; though which can cause unwanted effects.
    ;
    ; Can be used to implement status bars
    ;
    ; Default: off
    ;====
    vdpreg.LOCK_H_SCROLL  DB

    ;====
    ; Stops the right-most 8 columns scrolling vertically. They can still scroll horizontally
    ; though which can cause unwanted effects
    ;
    ; Can be used to implement status bars
    ;
    ; Default: off
    ;====
    vdpreg.LOCK_V_SCROLL  DB

    ;====
    ; Renders each pixel as as 2x2 pixels.
    ;
    ; Note: SMS1 can only display the first 4 sprites per scanline in this way,
    ; and the rest on the scanline will only be zoomed vertically
    ;
    ; Default: off
    ;====
    vdpreg.ZOOM_SPRITES  DB
.ende

;====
; Constants
;====
.define vdpreg.COMMAND_PORT $bf   ; write (issue command to vdp)

;====
; Defaults
;====
.define vdpreg.default.register0    %00000110;  Mode control 1
                                    ;|||||||`-  Sync enable; always 0
                                    ;||||||`--  Extra height enable/TMS9918 mode select; always 1
                                    ;|||||`---  Mode 4 enable; always 1
                                    ;||||`----  Shift sprites left 8 pixels
                                    ;|||`-----  Enable line interrupts
                                    ;||`------  Hide leftmost 8 pixels
                                    ;|`-------  Horizontal scroll lock
                                    ;`--------  Vertical scroll lock ()

.define vdpreg.default.register1    %10000000;  Mode control 2
                                    ;|||||||`-  Zoomed sprites -> 16x16 pixels
                                    ;||||||`--  Doubled sprites -> 2 tiles per sprite, 8x16
                                    ;|||||`---  Mega Drive mode 5 enable
                                    ;||||`----  30 row/240 line mode (SMS2 only)
                                    ;|||`-----  28 row/224 line mode (SMS2 only)
                                    ;||`------  Enable VBlank interrupts
                                    ;|`-------  Enable display
                                    ;`--------  Unused; always 1

.define vdpreg.default.register2    %11111111;  Tilemap base address (default = $3800)
                                    ;|||||||`-  Mask bit (SMS1)
                                    ;```````--  Name table base address

.define vdpreg.default.register3    %11111111   ; Palette base address (always $ff for SMS1)
.define vdpreg.default.register4    %00000111   ; Pattern base address (last 3 bits always set for SMS1)
.define vdpreg.default.register5    %11111111   ; Sprite table base address (usually $ff)
.define vdpreg.default.register6    %11111111   ; Sprite pattern generator base address (always $ff)
.define vdpreg.default.register7    %00000000   ; Overscan/backdrop color slot (bits 0-3)
.define vdpreg.default.register8    %00000000   ; Background X scroll
.define vdpreg.default.register9    %00000000   ; Background Y scroll
.define vdpreg.default.register10   %11111111   ; Line interrupt counter

;====
; Pending overrides
;====
.define vdpreg.pending.register0 vdpreg.default.register0
.define vdpreg.pending.register1 vdpreg.default.register1
.define vdpreg.pending.register2 vdpreg.default.register2
.define vdpreg.pending.register3 vdpreg.default.register3
.define vdpreg.pending.register4 vdpreg.default.register4
.define vdpreg.pending.register5 vdpreg.default.register5
.define vdpreg.pending.register6 vdpreg.default.register6
.define vdpreg.pending.register7 vdpreg.default.register7
.define vdpreg.pending.register8 vdpreg.default.register8
.define vdpreg.pending.register9 vdpreg.default.register9
.define vdpreg.pending.register10 vdpreg.default.register10

;====
; Sets the value of a given setting and stores the result in a define.
; Once all settings have been set you can use the 'vdpreg.apply' macro
; to send the data to the VDP.
;
; @in     setting     the setting identifier. See 'Settings' at the top
; @in     value       the setting value
;====
.macro "vdpreg.set" args setting value
    .if setting == vdpreg.BORDER_PALETTE_SLOT
        .redefine vdpreg.pending.register7 value & %00001111
    .endif

    .if setting == vdpreg.ENABLE_DISPLAY
        .if value == 0
            .redefine vdpreg.pending.register1 vdpreg.pending.register1 & %10111111 ; reset bit 6
        .else
            .redefine vdpreg.pending.register1 vdpreg.pending.register1 | %01000000 ; set bit 6
        .endif
    .endif

    .if setting == vdpreg.ENABLE_HBLANK
        .if value == 0
            .redefine vdpreg.pending.register0 vdpreg.pending.register0 & %11101111 ; reset bit 4
        .else
            .redefine vdpreg.pending.register0 vdpreg.pending.register0 | %00010000 ; set bit 4
        .endif
    .endif

    .if setting == vdpreg.ENABLE_TALL_SPRITES
        .if value == 0
            .redefine vdpreg.pending.register1 vdpreg.pending.register1 & %11111101 ; reset bit 1
        .else
            .redefine vdpreg.pending.register1 vdpreg.pending.register1 | %00000010 ; set bit 1
        .endif
    .endif

    .if setting == vdpreg.ENABLE_VBLANK
        .if value == 0
            .redefine vdpreg.pending.register1 vdpreg.pending.register1 & %11011111 ; reset bit 5
        .else
            .redefine vdpreg.pending.register1 vdpreg.pending.register1 | %00100000 ; set bit 5
        .endif
    .endif

    .if setting == vdpreg.HIDE_LEFT_COLUMN
        .if value == 0
            .redefine vdpreg.pending.register0 vdpreg.pending.register0 & %11011111 ; reset bit 5
        .else
            .redefine vdpreg.pending.register0 vdpreg.pending.register0 | %00100000 ; set bit 5
        .endif
    .endif

    .if setting == vdpreg.LINE_INTERRUPT_COUNTER
        .redefine vdpreg.pending.register10 value
    .endif

    .if setting == vdpreg.LOCK_H_SCROLL
        .if value == 0
            .redefine vdpreg.pending.register0 vdpreg.pending.register1 & %10111111 ; reset bit 6
        .else
            .redefine vdpreg.pending.register0 vdpreg.pending.register1 | %01000000 ; set bit 6
        .endif
    .endif

    .if setting == vdpreg.ZOOM_SPRITES
        .if value == 0
            .redefine vdpreg.pending.register1 vdpreg.pending.register1 & %11111110 ; reset bit 0
        .else
            .redefine vdpreg.pending.register1 vdpreg.pending.register1 | %00000001 ; set bit 0
        .endif
    .endif

    .if setting == vdpreg.LOCK_V_SCROLL
        .if value == 0
            .redefine vdpreg.pending.register0 vdpreg.pending.register1 & %01111111 ; reset bit 7
        .else
            .redefine vdpreg.pending.register0 vdpreg.pending.register1 | %10000000 ; set bit 7
        .endif
    .endif
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
.macro "vdpreg.load" args start end
    ld hl, start
    ld c, vdpreg.COMMAND_PORT
    ld b, end - start
    otir
.endm

;===
; Defines the initial/default register data ready to be loaded with vdpreg.load
;===
.macro "vdpreg.defineInitData"
    .db vdpreg.default.register0, $80
    .db vdpreg.default.register1, $81
    .db vdpreg.default.register2, $82
    .db vdpreg.default.register3, $83
    .db vdpreg.default.register4, $84
    .db vdpreg.default.register5, $85
    .db vdpreg.default.register6, $86
    .db vdpreg.default.register7, $87
    .db vdpreg.default.register8, $88
    .db vdpreg.default.register9, $89
    .db vdpreg.default.register10, $8a
.endm

;===
; Defines the data changed by vdpreg.set, ready to loaded by vdpreg.load
;===
.macro "vdpreg.defineData"
    .ifneq vdpreg.pending.register0 vdpreg.default.register0
        .db vdpreg.pending.register0, $80
    .endif

    .ifneq vdpreg.pending.register1 vdpreg.default.register1
        .db vdpreg.pending.register1, $81
    .endif

    .ifneq vdpreg.pending.register2 vdpreg.default.register2
        .db vdpreg.pending.register2, $82
    .endif

    .ifneq vdpreg.pending.register3 vdpreg.default.register3
        .db vdpreg.pending.register3, $83
    .endif

    .ifneq vdpreg.pending.register4 vdpreg.default.register4
        .db vdpreg.pending.register4, $84
    .endif

    .ifneq vdpreg.pending.register5 vdpreg.default.register5
        .db vdpreg.pending.register5, $85
    .endif

    .ifneq vdpreg.pending.register6 vdpreg.default.register6
        .db vdpreg.pending.register6, $86
    .endif

    .ifneq vdpreg.pending.register7 vdpreg.default.register7
        .db vdpreg.pending.register7, $87
    .endif

    .ifneq vdpreg.pending.register8 vdpreg.default.register8
        .db vdpreg.pending.register8, $88
    .endif

    .ifneq vdpreg.pending.register9 vdpreg.default.register9
        .db vdpreg.pending.register9, $89
    .endif

    .ifneq vdpreg.pending.register10 vdpreg.default.register10
        .db vdpreg.pending.register10, $8a
    .endif

    ; Reset back to defaults
    .redefine vdpreg.pending.register0 vdpreg.default.register0
    .redefine vdpreg.pending.register1 vdpreg.default.register1
    .redefine vdpreg.pending.register2 vdpreg.default.register2
    .redefine vdpreg.pending.register3 vdpreg.default.register3
    .redefine vdpreg.pending.register4 vdpreg.default.register4
    .redefine vdpreg.pending.register5 vdpreg.default.register5
    .redefine vdpreg.pending.register6 vdpreg.default.register6
    .redefine vdpreg.pending.register7 vdpreg.default.register7
    .redefine vdpreg.pending.register8 vdpreg.default.register8
    .redefine vdpreg.pending.register9 vdpreg.default.register9
    .redefine vdpreg.pending.register10 vdpreg.default.register10
.endm
