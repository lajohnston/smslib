;===
; Simple 32KB ROM with no paging
;===
.define mapper 1

.define mapper.FIXED_SLOT = 0
.define mapper.PAGEABLE_SLOT = 0 ; none
.define mapper.RAM_SLOT = 1

.memorymap
    defaultslot mapper.FIXED_SLOT

    ; 32KB ROM
    slotsize $8000
    slot mapper.FIXED_SLOT $0000

    ; 8KB RAM
    slotsize $2000
    slot mapper.RAM_SLOT $c000
.endme

.rombankmap
    bankstotal 1

    ; Single 32KB bank
    banksize $8000
    banks 1
.endro

.macro "mapper.init"
    ; nothing to set up
.endm

.macro "mapper.pageBank"
    ; no paging
.endm