; Common functions used by mappers. Not intended to be used directly

;====
; Paging registers
;
; Writes to these addresses are intercepted by the cartridge's mapper chip and
; inform it which banks of ROM to make available and which cartridge features
; to enable
;
; Further documentation can be found at:
; https://www.smspower.org/Development/Mappers
;====

;====
; Cartridge features
;       00000000
;       ||||||**- Bank shift (no known software uses this)
;       |||||*--- RAM bank select
;       ||||*---- Enable cartridge RAM ($8000- $bfff, slot 2, overrides ROM bank)
;       |||*----- Enable cartridge RAM ($4000- $7fff) - no known software uses
;       |**------ unused
;       *-------- Enable ROM-write (no known software uses this)
;====
.define _mapper.FEATURES_REGISTER = $fffc

; Values written to these determine which bank is paged into which slot
.define _mapper.SLOT_0_REGISTER = $fffd
.define _mapper.SLOT_1_REGISTER = $fffe
.define _mapper.SLOT_2_REGISTER = $ffff

;====
; Enables the on-cartridge RAM in slot 2, accessible with addresses
; $8000- $bfff
;====
.macro "_mapper.enableCartridgeRam"
    ld a, %00001000
    ld (_mapper.FEATURES_REGISTER), a
.endm

;===
; Page a bank into the given slot
;
; @in   bankNumber      the bank number to page in. Use the colon prefix in
;                       WLA-DX to retrieve the bank number of an address,
;                       i.e. mapper.pageBank :myAsset
; @in   [slotNumber]    the slot number to page the bank into. Defaults to
;                       slot 1
;===
.macro "_mapper.pageBank" args bankNumber slotNumber
    ld a, bankNumber

    .ifeq slotNumber 2
        ld (_mapper.SLOT_2_REGISTER), a
    .else
        ; Default
        ld (_mapper.SLOT_1_REGISTER), a
    .endif
.endm
