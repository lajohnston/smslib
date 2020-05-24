;====
; SMSLib Static sprites example
;
; Renders static sprites on the screen
;====
.sdsctag 1.10, "smslib sprites", "smslib static sprite tutorial", "lajohnston"

;====
; Import smslib
;====
.incdir "../../"            ; back to smslib directory
.include "smslib.asm"       ; base library
.include "mapper/basic.asm" ; memory mapper
.include "palette.asm"      ; handles colors
.include "patterns.asm"     ; handles patterns (tile images)
.include "sprites.asm"      ; handles a sprite buffer in RAM
.include "vdpreg.asm"       ; handles vdp settings
.include "boot.asm"         ; initialise system and smslib modules

;====
; Initialise program
;====
.section "init" free
    init:
        ; Load sprite palette
        palette.setSlot palette.SPRITE_PALETTE
        palette.load paletteData, 6

        ; Load pattern data into slots 256+ (used for sprites, by default)
        patterns.setSlot 256
        patterns.load patternData, 6

        ; Add sprite to buffer
        sprites.setSlot 0
        ld a, 100   ; y
        ld b, 80    ; x
        ld c, 5     ; pattern number
        sprites.add

        ; Add a sprite group - multiple sprites relative to a position
        ld hl, spriteGroup
        ld b, 140   ; base x pos
        ld c, 50    ; base y pos
        sprites.addGroup

        ; Another group - same group, different position
        ld hl, spriteGroup
        ld b, 170   ; base x pos
        ld c, 120   ; base y pos
        sprites.addGroup

        ; Mark end of sprites to ensure no more get rendered
        sprites.end

        ; Copy buffer to VRAM
        sprites.copyToVram

        ; Enable the display then stop
        vdpreg.enableDisplay
        -: jr -
.ends

;====
; Assets
;====

.section "assets" free
    paletteData:
        .db $00 $11 $22 $32 $36 $3F

    patternData:
        ; Tile index $000
        .db $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00
        ; Tile index $001
        .db $08 $07 $00 $00 $04 $1C $03 $00 $10 $30 $0F $00 $20 $60 $1F $00 $80 $40 $3F $00 $40 $C0 $3F $00 $00 $80 $7F $00 $00 $80 $7F $00
        ; Tile index $002
        .db $10 $E0 $00 $00 $20 $38 $C0 $00 $08 $0C $F0 $00 $64 $06 $F8 $00 $11 $02 $FC $00 $0A $03 $FC $00 $08 $01 $FE $00 $00 $01 $FE $00
        ; Tile index $003
        .db $00 $80 $7F $00 $00 $80 $7F $00 $40 $C0 $3F $00 $80 $40 $3F $00 $20 $60 $1F $00 $10 $30 $0F $00 $04 $1C $03 $00 $08 $07 $00 $00
        ; Tile index $004
        .db $00 $01 $FE $00 $00 $01 $FE $00 $02 $03 $FC $00 $01 $02 $FC $00 $04 $06 $F8 $00 $08 $0C $F0 $00 $20 $38 $C0 $00 $10 $E0 $00 $00
        ; Tile index $005
        .db $42 $3C $00 $00 $81 $42 $3C $00 $08 $81 $7E $00 $04 $81 $7E $00 $00 $81 $7E $00 $00 $81 $7E $00 $81 $42 $3C $00 $42 $3C $00 $00

    spriteGroup:
        ; pattern, relativeX, relativeY
        sprites.sprite 1, 0, 0  ; top left      (x0, y0)
        sprites.sprite 2, 8, 0  ; top right     (x+8, y0)
        sprites.sprite 3, 0, 8  ; bottom left   (x0, y+8)
        sprites.sprite 4, 8, 8  ; bottom right  (x+8, y+8)
        sprites.endGroup
.ends
