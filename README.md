# Sega Master System Z80 Libs

Low level Z80 WLA-DX libs for handling Sega Master System hardware.

## Contents

- [smslib.asm](#smslibasm) - common functions used by all the libs
- [input.asm](#inputasm) - interprets the joypad inputs
- [palette.asm](#paletteasm) - handles the color palettes
- [patterns.asm](#patternsasm) - handles patterns (tile images)
- **sprites.asm** - manages a sprite table in a RAM and pushes to VRAM when required
- [vdpreg.asm](#vdpregasm) - defines and sets graphics chip register settings
- **z80.asm** - logical/math routines
- [/mapper](#mappers)

## Usage

Include `smslib.asm` file then any of the specific libs you wish to use:

```
.include "lib/smslib/smslib.asm"
.include "lib/smslib/input.asm"
.include "lib/smslib/palette.asm"
.include "lib/smslib/patterns.asm"

```

See `examples` directory for examples. Within an example, call the `build.sh` script (Linux). wlalink and wla-z80 should be in your system path. The compiled .sms ROM will appear in the `examples/build` directory.

## Design principles

### Low level

The libs act as a thin layer to the Master System chips, to ensure they are applicable across many projects and engines. They provide macros and routines to abstract many of the nuances of Master System development so you can build a more fuller-blown engine on top of them.

### Priorities: Speed > Ease > Size

Over time the routines will be optimised for speed and size without one aspect adversely affecting the other. There will however be an emphasis on speed as code size is rarely a problem in Master System projects (especially compared to asset sizes) whereas speed can be a bottleneck, especially within VBlank timing constraints.

The libs are also designed for ease of use so long as this doesn't reduce the speed of the generated code.

### Decoupled

The smslib.asm file contains common functionality used by the other lib files, but other than that the separate files don't reference each other and you can pick and choose which ones to include in your project.

### Prefixes

Each library file prefixes its labels with its name and a '.' (i.e. input.readPortA). Although it can make things more verbose it makes for much easier code tracking.

### No unnecessary pushing/popping

The library routines don't PUSH or POP registers to preserve them, meaning they will happily 'clobber' registers if need be. This shifts the responsibility of preservation to the code calling the library, mainly for efficiency reasons: the calling code knows what registers it actually cares about, so only needs to preserve those.

### Documentation

Each routine is documented with a comment block above it specifying the parameters (registers or macro arguments)

## input.asm

Allows you to read input from the controller pads.

```
input.readPort1

input.if input.LEFT, +
    ; Left has been pressed
+:

input.if input.BUTTON1, +
    ; Button 1 has been pressed
+:

```

If needed you can change the register that holds the input value (default is `a`):

```
.redefine input.register "d"
.input.readPort1 ; result stored in register d
```

## vdpreg.asm

Handles the VDP registers and settings.

Initialise the VDP registers with sensible initial defaults:

```
vdpreg.init
```

Change register values. See vdpreg.asm for available options:

```
vdpreg.setRegister0 vdpreg.HIDE_LEFT_COLUMN
vdpreg.setRegister1 vdpreg.ENABLE_DISPLAY|vdpreg.ENABLE_VBLANKS
vdpreg.setBackgroundColor 0 ; use first slot in sprite palette
vdpreg.setScrollX 100
vdpreg.setScrollY 255
```

## palette.asm

Handles the VDP color palettes. There are 31 color slots:

- Sprites can only use the last 16 slots (16-31).
- Each background pattern (tile) can use either the first 16 slots (0-15) or
  the last 16 (16-31)

Each color is a byte containing 2-bit RGB color values (--BBGGRR). You can call `palette.rgb` with the RGB values to generate a color byte with an approximate RGB value. Each color component can have the value of 0, 85, 170 or 255. Values inbetween these will be rounded to the closest factor.

```
paletteData:
    palette.rgb 255, 0, 0   ; red
    palette.rgb 255, 170, 0 ; orange
    palette.rgb 255, 255, 0 ; yellow
    palette.rgb 0, 255, 0   ; green
    palette.rgb 0, 0, 255   ; blue
    palette.rgb 85, 0, 85   ; indigo
    palette.rgb 170, 0, 255 ; violet
```

You can then load these into the VDP VRAM the following macros:

```
; load 7 colors into slot 0 onwards
palette.setSlot 0
palette.load paletteData, 7

; load 5 colors into slot 16 onwards, skipping the first 2 (red, orange)
palette.setSlot 16
palette.load paletteData, 5, 2  ; load 5, skipping first 2 (red, orange)

; ...append red and orange at the end (no need to call setSlot again)
palette.load paletteData, 2
```

## patterns.asm

Loads patterns (tiles) into the VRAM, which can be used for background images or sprites. See `patterns.asm` for documentation about the format requirement.

This only deals with uncompressed tile data and is provided for example purposes to get you started. For an actual game you would want to compress pattern data using an algorithm such as zx7 or aPLib and use the appropriate lib to decompress and send to VRAM.

```
patternData:
    .incbin 'tiles.bin'

; Load 4 tiles into tile slot 0 onwards (0-4)
patterns.setSlot 0
patterns.load patternData, 5

; ...then load pattern 10 into the next slot (5)
patterns.load patternData, 1, 9 ; skip first 9
```

# mappers

The Master System can only view 48KB of ROM memory at a time. Mappers control which portions of ROM are visible within this 48KB window and can dynamically switch portions at runtime to allow for much larger cartridge sizes. The included smslib mappers can abstract this complexity from you or can be used as examples to create your own.

Include the mapper you wish to use:

```
.include "smslib/mapper/waimanu.asm"
```

Initialise the SMS mapping registers when booting your game:

```
mapper.init
```

The mapper exposes FIXED_SLOT, PAGEABLE_SLOT and RAM_SLOT constants:

```
; Fixed slot is appropriate for code
.slot mapper.FIXED_SLOT
.include "game.asm"

; Pageable slot is appropriate for assets
.slot mapper.PAGEABLE_SLOT
.include "assets.asm"

; RAM slot can be used for RAM sections
.ramsection "foo" slot mapper.RAM_SLOT
    bar     DB
.ends
```

Before loading assets remember to page the bank you want to access. You can use WLA-DX's
colon prefix to retrieve a bank number for a given address:

```
mapper.pageBank :paletteData
palette.load 0, paletteData, paletteDataEnd
```

You can customise some mappers with additional paramters. Check the relevant mapper asm file to see which settings are supported.

```
.define mapper.pageableBanks 4
.include "smslib/mapper/waimanu.asm"
```

# smslib.asm

Base library containing common functionality.

Use smslib.init to initialise the system (disables interrupts, sets stack pointer, clears vram). This should be called at .orga 0.
If you've included an smslib mapper it will set up the paging registers. It will also initialise the VDP registers if you're using vdpreg.

```
.orga 0
.section "main" force
    smslib.init init    ; init system then jump to init label
.ends

.section "init" free
    init:
        ; game init
.ends
```

# tilemap.asm

Manages the tilemap, which utilises patterns to create the background image.

Output ASCII data:

```
    .asciitable
        map " " to "~" = 0
    .enda

    message:
        .asc "Hello, world"
        .db $ff ; terminator byte

    tilemap.setSlot 0, 0 ; top left tile slot
    tilemap.loadBytesUntil $ff message
```
