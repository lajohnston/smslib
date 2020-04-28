;===
; Taken from Waimanu source
;
; @author Disjointed Studio
;
; Documented in http://www.smspower.org/forums/15794-AFewHintsOnCodingAMediumLargeSizedGameUsingWLADX
;
; Features:
;   * Main 32KB bank in non-pageable slot 0
;   * Multiple (default 6) additional 16KB banks in pageable slot 2
;===
.define mapper 1

;====
; Settings
;====

; Define the number of pageable 16KB banks (default 6 = 128KB)
.ifndef mapper.pageableBanks
    .define mapper.pageableBanks 6
.endif

;====
; Constants
;====
.define mapper.FIXED_SLOT = 0
.define mapper.PAGEABLE_SLOT = 2
.define mapper.RAM_SLOT = 3

; Slots
.memorymap
    defaultslot mapper.FIXED_SLOT

    ; ROM (non-pageable)
    slotsize $7ff0  ; 32KB minus 16 byte header
    slot mapper.FIXED_SLOT $0000

    ; SEGA ROM header (non-pageable)
    slotsize $0010  ; 16 byte SEGA ROM header
    slot 1 $7ff0

    ; ROM (pageable)
    slotsize $4000
    slot mapper.PAGEABLE_SLOT $8000

    ; RAM
    slotsize $2000
    slot mapper.RAM_SLOT $c000
.endme

; Banks
; These can be loaded into the slots at runtime
.rombankmap
    bankstotal mapper.pageableBanks + 2

    banksize $7ff0 ; 32KB minus 16 bytes
    banks 1

    banksize $0010 ; 16 bytes, for SEGA ROM header
    banks 1

    banksize $4000 ; 16KB
    banks mapper.pageableBanks
.endro

;===
; Initialise the paging registers
;===
.section "mapper.init" free
    mapper.init:
        ld de, $fffc
        ld hl, _mapperInitValues
        ld bc, _mapperInitValuesEnd - _mapperInitValues
        ldir
        ret

    _mapperInitValues:
        .db $00 ; $fffc - Cartridge RAM mapping (disabled)
        .db $00 ; $fffd - ROM Bank 0 - use slot 0
        .db $01 ; $fffe - ROM Bank 1 - use slot 1
        .db $02 ; $ffff - ROM Bank 2 - use slot 2
    _mapperInitValuesEnd:
.ends

.macro "mapper.init"
    call mapper.init
.endm

;===
; Page a bank into the pageable slot
; Use the colon prefix in WLA-DX to retrieve the bank number of an address, i.e.
;   mapper.pageBank :assetAddr
;===
.macro "mapper.pageBank"
    ld a, \1
    ld ($fffe), a
.endm
