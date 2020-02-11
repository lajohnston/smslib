;===
; Taken from Waimanu source by Disjointed Studio
;
; Documented in http://www.smspower.org/forums/15794-AFewHintsOnCodingAMediumLargeSizedGameUsingWLADX
;
; Features:
;   * Main 32KB bank in non-pageable slot 0
;   * 6 additional 16KB banks in pageable slot 2
;===

.define smslib.mapper.CODE_SLOT = 0
.define smslib.mapper.ASSET_SLOT = 2
.define smslib.mapper.RAM_SLOT = 3

.memorymap
    defaultslot 0
    slotsize $7ff0 ; ROM (won't page this)
    slot 0 $0000
    slotsize $0010 ; SEGA ROM header (won't page this too)
    slot 1 $7ff0
    slotsize $4000 ; ROM (... will page this!)
    slot 2 $8000
    slotsize $2000 ; RAM
    slot smslib.mapper.RAM_SLOT $c000
.endme

.rombankmap
    bankstotal 8
    banksize $7ff0 ; 32 KB minus 16 bytes
    banks 1
    banksize $0010 ; 16 bytes, for SEGA ROM header
    banks 1
    banksize $4000 ; 16 KB (each)
    banks 6        ; 6 of them. Makes this 128 KB total
.endro

;===
; Initialise the paging registers
;===
.macro "mapper.init"
    ld de, $fffc
    ld hl, _mapperInitValues
    ld bc, $0004
    ldir

    jp +
        _mapperInitValues:
            .db $00, $00, $01, $02
    +:
.endm