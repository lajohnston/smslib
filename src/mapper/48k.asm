;===
; Simple 48KB ROM with no paging
;===
.define mapper.ENABLED 1

.define mapper.FIXED_SLOT = 0
.define mapper.PAGE_SLOT_A = 0 ; no paging
.define mapper.PAGE_SLOT_B = 0 ; no paging
.define mapper.RAM_SLOT = 1

.memorymap
    defaultslot mapper.FIXED_SLOT

    ; 48KB ROM
    slotsize $C000
    slot mapper.FIXED_SLOT $0000

    ; 8KB RAM
    slotsize $2000
    slot mapper.RAM_SLOT $c000
.endme

.rombankmap
    ; Single 48KB bank
    bankstotal 1
    banksize $C000
    banks 1
.endro

.macro "mapper.init"
    ; nothing to set up
.endm

.macro "mapper.pageBank"
    ; no paging
.endm