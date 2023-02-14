;====
; SMSLib Mapper example
;
; The Master System can only view 48KB of ROM at a time. For larger ROMs we will
; only be able to view portions of it at a time. We will therefore need to 'page'
; these chunks into the memory map when we need them
;====
.sdsctag 1.10, "smslib mapper example", "smslib mapper example", "lajohnston"

;====
; Import smslib
;====
.define interrupts.handleVBlank 1   ; enable VBlanks
.define mapper.enableCartridgeRam 1

.incdir "../../"                ; point to smslib directory
.include "mapper/sega.asm"      ; select Sega mapper. Note: if you swap this
                                ; another one this example should still work
.include "smslib.asm"           ; include rest of smslib lib

;====
; Define some assets that can be paged into PAGE_SLOT_A. Some mappers (like the
; SEGA mapper) also have a separate PAGE_SLOT_B slot we can use but it's
; generally simpler to stick to one. This example will stick to PAGE_SLOT_A.
;====
.slot mapper.PAGE_SLOT_A

; Map ASCII data to byte values so we can use .asc later (see wla-dx docs)
.asciitable
    map " " to "~" = 0
.enda

;====
; superfree allows wla-dx to decide where best to place each section in the ROM.
; This may mean they end up in separate ROM banks, and so we'll later need to
; 'page' these banks into the memory map whenever we want to use the assets
;====
.section "palette data" superfree
    paletteData:
        palette.rgb 0, 0, 0         ; black
        palette.rgb 170, 85, 170    ; purple
.ends

.section "font data" superfree
    fontData:
        .incbin "../assets/font.bin" fsize fontDataSize
.ends

.section "instructions" superfree
    instructions:
        .asc " Press button 1 or 2 to change         the current bank"
        .db $ff ; terminator byte
.ends

.section "lots of 1s" superfree
    lotsOf1s:
        .asc "          Lots of 1s            "
        .asc "                                "

        .rept $3800
            .asc "1"
        .endr
.ends

.section "lots of 2s" superfree
    lotsOf2s:
        .asc "          Lots of 2s            "
        .asc "                                "

        .rept $3800
            .asc "2"
        .endr
.ends

;====
; Initialise program
;
; It's best to place code in the fixed slot so it's always available to the CPU
;====
.slot mapper.FIXED_SLOT

.section "init" free
    init:
        ; Load palette
        palette.setIndex 0
        mapper.pageBank :paletteData        ; ensure paletteData is visible
                      ; ^ note the colon prefix - this gives us the bank number
        palette.writeSlice paletteData, 2   ; we can now use paletteData

        ; Load font tiles
        patterns.setIndex 0
        mapper.pageBank :fontData           ; ensure fontData is visible
        patterns.load fontData, fontDataSize

        ; Display font tiles on screen
        tilemap.setColRow 0, 6
        mapper.pageBank :instructions       ; ensure instructions is visible
        tilemap.loadBytesUntil $ff instructions

        ; Enable the display and VBlank
        vdp.startBatch
            vdp.enableDisplay
            vdp.enableVBlank
        vdp.endBatch

        ; Enable interrupts
        interrupts.enable

        ; Infinite loop
        -: jr -
.ends

;====
; VBlank Handler
;
; This will get called 50 or 60 times a second (PAL/NTSC respectively)
; We can check the input at each interval
;====
.section "VBlank handler" free
    interrupts.onVBlank:
        ; Read the input from joypad 1
        input.readPort1

        ; If button 1 pressed, page-in and display part of lotsOf1s
        input.if input.BUTTON_1, +
            tilemap.setColRow 0, 10
            mapper.pageBank :lotsOf1s       ; make lotsOf1s available
            tilemap.loadBytes lotsOf1s, 224 ; load first 224 bytes
            jp _end
        +:

        ; If button 2 pressed, page-in and display part of lotsOf2s
        input.if input.BUTTON_2, +
            tilemap.setColRow 0, 10
            mapper.pageBank :lotsOf2s       ; make lotsOf2s available
            tilemap.loadBytes lotsOf2s, 224 ; load first 224 bytes
        +:

    _end:
        interrupts.endVBlank
.ends
