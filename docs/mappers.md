# Memory Mappers

The Master System can only view 48KB of ROM memory at a time. Mappers control which portions of ROM are visible within this 48KB window and can dynamically switch portions at runtime to allow for much larger cartridge sizes. The included smslib mappers can abstract this complexity from you or can be used as examples to create your own.

Mappers define one or more fixed-sized 'slots' that can provide access to a small portion of the larger ROM at any given time. The portion of ROM they provide access to (called a 'bank') can be changed at runtime.

## Selecting a Mapper

SMSLib will default to using a basic 48KB mapper which is small enough to not require any paging. If you require a larger ROM than this then you can choose another one by including it before `smslib.asm`:

```
.incdir "lib/smslib"        ; point to smslib directory
.include "mapper/sega.asm"  ; use sega mapper
.include "smslib.asm"       ; include rest of smslib
```

## Slots

Only one mapper can be used per project. All mappers expose `FIXED_SLOT`, `PAGE_SLOT_A`, `PAGE_SLOT_B` and `RAM_SLOT` constants. Using these constants should make it easier for you to swap out a mapper at a later stage of development if you decide to do so.

```
; Pageable slots are good for asset data that is only needed at certain times
.slot mapper.PAGE_SLOT_A
.include "assets.asm"       ; contents can now be paged into PAGE_SLOT_A

; Fixed slot is good for code to ensure it's always accessible
.slot mapper.FIXED_SLOT
.include "game.asm"         ; contents will always be accessible

; RAM slot should be used for RAM variables
.ramsection "foo" slot mapper.RAM_SLOT
    bar     DB
.ends
```

## Paging Data

Before accessing data from the page slots (e.g. when loading an asset) remember to first tell the mapper to 'page' to the bank you want to access. You can use WLA-DX's colon prefix for a label to retrieve the bank number it has been placed in.

```
mapper.pageBank :paletteData        ; ensure the bank containing paletteData is accessible
palette.loadSlice paletteData, 1    ; you can now use paletteData
```

### Page Slot B

Some mappers also provide a second pageable slot, `PAGE_SLOT_B`. It's generally simpler to stick to the one (`PAGE_SLOT_A`) but if you happened to have an asset over 16KB in size then both page slots could be used together to map the whole asset at once.

```
; Asset intended to be mapped into mapper.PAGE_SLOT_B
.slot mapper.PAGE_SLOT_B
paletteData:
    ...

; you must provide PAGE_SLOT_B as the second parameter
mapper.pageBank :paletteData, mapper.PAGE_SLOT_B
palette.loadSlice paletteData, 1  ; palette data now accessible

```

## Settings

You can customise some mappers with additional parameters. Check the relevant mapper asm file to see which settings are supported.

```
.define mapper.pageableBanks 4
.define mapper.enableCartridgeRam 1
.include "smslib/mapper/sega.asm"
```
