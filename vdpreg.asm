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
    vdpreg.DISPLAY_ENABLED  DB

    ;====
    ; Enables VBlank interrupts
    ; Default: off
    ;====
    vdpreg.FRAME_INTERRUPTS_ENABLED DB

    ;====
    ; Enable HBlank interrupts
    ; Default: off
    ;====
    vdpreg.LINE_INTERRUPTS_ENABLED  DB

    ;====
    ; The line interrupt counter
    ;====
    vdpreg.LINE_INTERRUPT_COUNTER DB

    ;====
    ; Useful to allow sprites to move on/off the left side of the screen smoothly
    ; Default: off
    ;====
    vdpreg.LEFT_COLUMN_HIDDEN    DB

    ;====
    ; Stops the top two rows scrolling horizontally. They can still scroll vertically
    ; though which can cause unwanted effects.
    ;
    ; Can be used to implement status bars
    ;
    ; Default: off
    ;====
    vdpreg.HORIZONTAL_SCROLL_LOCKED  DB

    ;====
    ; Sets all sprites to be 2-tiles high. The sprite's pattern number rounded
    ; down to the nearest multiple of 2 will be used for the bottom sprite,
    ; and the next pattern in the table will be used for the top
    ;
    ; Default: off
    ;====
    vdpreg.TALL_SPRITES_ENABLED  DB

    ;====
    ; Stops the right-most 8 columns scrolling vertically. They can still scroll horizontally
    ; though which can cause unwanted effects
    ;
    ; Can be used to implement status bars
    ;
    ; Default: off
    ;====
    vdpreg.VERTICAL_SCROLL_LOCKED  DB

    ;====
    ; Renders each pixel as as 2x2 pixels.
    ;
    ; Note: SMS1 can only display the first 4 sprites per scanline in this way,
    ; and the rest on the scanline will only be zoomed vertically
    ;
    ; Default: off
    ;====
    vdpreg.SPRITES_ZOOMED  DB
.ende

;====
; Constants
;====
.define vdpreg.COMMAND_PORT $bf   ; write (issue command to vdp)

;====
; Internal variables
;====

; Mode control 1
.define vdpreg.register0 %00000110
.define vdpreg.register0Pending 1

; Mode control 2
.define vdpreg.register1 %00000000
.define vdpreg.register1Pending 1

; Tilemap base address
.define vdpreg.register2 $ff
.define vdpreg.register2Pending 1

; Palette base address
.define vdpreg.register3 $ff
.define vdpreg.register3Pending 1

; Pattern base address
.define vdpreg.register4 $00
.define vdpreg.register4Pending 1

; Sprite table base address
.define vdpreg.register5 $ff
.define vdpreg.register5Pending 1

; Sprite pattern generator base address
.define vdpreg.register6 $ff
.define vdpreg.register6Pending 1

; Overscan/backdrop color
.define vdpreg.register7 %00000000
.define vdpreg.register7Pending 1

; Background X scroll
.define vdpreg.register8 $00
.define vdpreg.register8Pending 1

; Background Y scroll
.define vdpreg.register9 $00
.define vdpreg.register9Pending 1

; Line interrupt counter
.define vdpreg.register10 $ff
.define vdpreg.register10Pending 1

;====
; Sets the value of a given setting and stores the result in the relevant
; assembler vdpreg.registerx variable. Once all settings have been set you can
; use the 'vdpreg.apply' macro to send the data to the VDP.
;
; @in     setting     the setting identifier. See 'Settings' at the top
; @in     value       the setting value
;====
.macro "vdpreg.set" args setting value
    .if setting == vdpreg.LINE_INTERRUPTS_ENABLED
        .redefine vdpreg.register0Pending 1

        .if value == 0
            .redefine vdpreg.register0 vdpreg.register0 & %11101111 ; reset bit 4
        .else
            .redefine vdpreg.register0 vdpreg.register0 | %00010000 ; set bit 4
        .endif
    .endif

    .if setting == vdpreg.LEFT_COLUMN_HIDDEN
        .redefine vdpreg.register0Pending 1

        .if value == 0
            .redefine vdpreg.register0 vdpreg.register0 & %11011111 ; reset bit 5
        .else
            .redefine vdpreg.register0 vdpreg.register0 | %00100000 ; set bit 5
        .endif
    .endif

    .if setting == vdpreg.HORIZONTAL_SCROLL_LOCKED
        .redefine vdpreg.register0Pending 1

        .if value == 0
            .redefine vdpreg.register0 vdpreg.register1 & %10111111 ; reset bit 6
        .else
            .redefine vdpreg.register0 vdpreg.register1 | %01000000 ; set bit 6
        .endif
    .endif

    .if setting == vdpreg.VERTICAL_SCROLL_LOCKED
        .redefine vdpreg.register0Pending 1

        .if value == 0
            .redefine vdpreg.register0 vdpreg.register1 & %01111111 ; reset bit 7
        .else
            .redefine vdpreg.register0 vdpreg.register1 | %10000000 ; set bit 7
        .endif
    .endif

    ; Register 1
    .if setting == vdpreg.SPRITES_ZOOMED
        .redefine vdpreg.register1Pending 1

        .if value == 0
            .redefine vdpreg.register1 vdpreg.register1 & %11111110 ; reset bit 0
        .else
            .redefine vdpreg.register1 vdpreg.register1 | %00000001 ; set bit 0
        .endif
    .endif

    .if setting == vdpreg.TALL_SPRITES_ENABLED
        .redefine vdpreg.register1Pending 1

        .if value == 0
            .redefine vdpreg.register1 vdpreg.register1 & %11111101 ; reset bit 1
        .else
            .redefine vdpreg.register1 vdpreg.register1 | %00000010 ; set bit 1
        .endif
    .endif

    .if setting == vdpreg.FRAME_INTERRUPTS_ENABLED
        .redefine vdpreg.register1Pending 1

        .if value == 0
            .redefine vdpreg.register1 vdpreg.register1 & %11011111 ; reset bit 5
        .else
            .redefine vdpreg.register1 vdpreg.register1 | %00100000 ; set bit 5
        .endif
    .endif

    .if setting == vdpreg.DISPLAY_ENABLED
        .redefine vdpreg.register1Pending 1

        .if value == 0
            .redefine vdpreg.register1 vdpreg.register1 & %10111111 ; reset bit 6
        .else
            .redefine vdpreg.register1 vdpreg.register1 | %01000000 ; set bit 6
        .endif
    .endif

    ; Register 7
    .if setting == vdpreg.BORDER_PALETTE_SLOT
        .redefine vdpreg.register7Pending 1
        .redefine vdpreg.register7 value & %00001111
    .endif

    ; Register 10
    .if setting == vdpreg.LINE_INTERRUPT_COUNTER
        .redefine vdpreg.register10Pending 1
        .redefine vdpreg.register10 value
    .endif
.endm

;====
; Apply the register settings set since the last call to this function
;
; @clobs af, bc, de, hl
;====
.macro "vdpreg.apply"
    ; Define register data
    jp _registerDataEnd\@

    _registerData\@:
        vdpreg.defineData
    _registerDataEnd\@:

    ; Write register data
    vdpreg.write _registerData\@ _registerDataEnd\@

    ; Clear pending flags
    .redefine vdpreg.register0Pending 0
    .redefine vdpreg.register1Pending 0
    .redefine vdpreg.register2Pending 0
    .redefine vdpreg.register3Pending 0
    .redefine vdpreg.register4Pending 0
    .redefine vdpreg.register5Pending 0
    .redefine vdpreg.register6Pending 0
    .redefine vdpreg.register7Pending 0
    .redefine vdpreg.register8Pending 0
    .redefine vdpreg.register9Pending 0
    .redefine vdpreg.register10Pending 0
.endm

;====
; Defines the register data as data bytes, ready to be written by vdpreg.write
;====
.macro "vdpreg.defineData"
    .if vdpreg.register0Pending == 1
        .db vdpreg.register0, $80
    .endif

    .if vdpreg.register1Pending == 1
        .db vdpreg.register1, $81
    .endif

    .if vdpreg.register2Pending == 1
        .db vdpreg.register2, $82
    .endif

    .if vdpreg.register3Pending == 1
        .db vdpreg.register3, $83
    .endif

    .if vdpreg.register4Pending == 1
        .db vdpreg.register4, $84
    .endif

    .if vdpreg.register5Pending == 1
        .db vdpreg.register5, $85
    .endif

    .if vdpreg.register6Pending == 1
        .db vdpreg.register6, $86
    .endif

    .if vdpreg.register7Pending == 1
        .db vdpreg.register7, $87
    .endif

    .if vdpreg.register8Pending == 1
        .db vdpreg.register8, $88
    .endif

    .if vdpreg.register9Pending == 1
        .db vdpreg.register9, $89
    .endif

    .if vdpreg.register10Pending == 1
        .db vdpreg.register10, $8a
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
.macro "vdpreg.write" args start end
    ld hl, start
    ld c, vdpreg.COMMAND_PORT
    ld b, end - start
    otir
.endm