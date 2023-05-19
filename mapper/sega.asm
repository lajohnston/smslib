;===
; Standard SEGA mapper
;
; Features:
; 1 x 16KB fixed slot (for code)
; 2 x 16KB pageable slots (for assets)
;
; It's generally simpler to only use one of the 16KB pageable slots but if you
; happen to have an asset larger than 16KB you could use both slots together to
; page a contiguous 32KB block of memory
;
; More info: https://www.smspower.org/forums/17445-MemoryMappingBasicTutorial
;===

.define mapper.ENABLED 1
.include "mapper/_mapper.asm"

;====
; Settings
;
; Define these before including this file if you wish to override
; the defaults
;====

; Define the number of pageable 16KB banks (default 6 = 128KB)
.ifndef mapper.PAGEABLE_BANKS
    .define mapper.PAGEABLE_BANKS 6
.endif

; Some cartridges have an additional 8KB of RAM. If enabled this will be
; accessible in slot 2
.ifndef mapper.ENABLE_CARTRIDGE_RAM
    .define mapper.ENABLE_CARTRIDGE_RAM 0
.endif

;====
; Constants
;====
.define mapper.FIXED_SLOT = 0
.define mapper.PAGE_SLOT_A = 1
.define mapper.PAGE_SLOT_B = 2
.define mapper.RAM_SLOT = 3

; Slots
.memorymap
    defaultslot mapper.FIXED_SLOT
    slotsize $4000                  ; each slot is 16KB

    slot mapper.FIXED_SLOT  $0000   ; ROM (non-pageable)
    slot mapper.PAGE_SLOT_A $4000   ; ROM (pageable slot 1)
    slot mapper.PAGE_SLOT_B $8000   ; ROM (pageable slot 2)
    slot mapper.RAM_SLOT    $c000   ; RAM (8KB + 8KB mirror)
.endme

; ROM Banks
; These can be loaded into the slots at runtime
.rombankmap
    bankstotal mapper.PAGEABLE_BANKS
    banksize $4000 ; 16KB
    banks mapper.PAGEABLE_BANKS
.endro

;===
; Initialise the paging registers
;===
.macro "mapper.init"
    .ifeq mapper.ENABLE_CARTRIDGE_RAM, 1
        _mapper.ENABLE_CARTRIDGE_RAM
    .endif
.endm

;===
; Page a bank into the given slot
;
; @in   bankNumber      the bank number to page in. Use the colon prefix in
;                       WLA-DX to retrieve the bank number of an address,
;                       i.e. mapper.pageBank :myAsset
; @in   [slotNumber]    the slot number to page into. Defaults to PAGE_SLOT_A
;===
.macro "mapper.pageBank" args bankNumber slotNumber
    .ifndef slotNumber
        .define slotNumber mapper.PAGE_SLOT_A
    .endif

    _mapper.pageBank bankNumber slotNumber
.endm
