# Memory Mappers

The Master System can only view 48KB of ROM memory at a time. Mappers control which portions of ROM are visible within this 48KB window and can dynamically switch portions at runtime to allow for much larger cartridge sizes. The included smslib mappers can abstract this complexity from you or can be used as examples to create your own.

SMSLib will default to using a basic 32KB mapper. To choose another one just include the mapper file before including `smslib.asm`:

```
.incdir "lib/smslib"
.include "mapper/waimanu.asm"   ; use waimanu mapper
.include "smslib.asm"           ; include smslib
```

Mappers define one or more fixed-sized 'slots' that can provide access to a small portion of the larger ROM at any given time. The portion of ROM they provide access to (called a 'bank') can be changed at runtime.

Only one mapper can be used per project. All mappers expose `FIXED_SLOT`, `PAGEABLE_SLOT` and `RAM_SLOT` constants. Using these constants should make it easier for you to swap out a mapper at a later stage of development if you decide to do so:

```
; Fixed slot is good for code to ensure it's always accessible
.slot mapper.FIXED_SLOT
.include "game.asm"

; Pageable slot is good for asset data that is only needed at certain times
.slot mapper.PAGEABLE_SLOT
.include "assets.asm"

; RAM slot should be used for RAM variables
.ramsection "foo" slot mapper.RAM_SLOT
    bar     DB
.ends
```

Before accessing data from the `PAGEABLE_SLOT` (e.g. when loading an asset) remember to first tell the mapper to 'page' to the bank you want to access. You can use WLA-DX's colon prefix to retrieve a bank number for a given address:

```
mapper.pageBank :paletteData        ; ensure the bank containing paletteData is accessible
palette.loadSlice paletteData, 1    ; you can now use the data in paletteData
```

You can customise some mappers with additional parameters. Check the relevant mapper asm file to see which settings are supported.

```
.define mapper.pageableBanks 4
.include "smslib/mapper/waimanu.asm"
```
