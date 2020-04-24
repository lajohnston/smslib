# Sega Master System Z80 Libs

Low level Z80 WLA-DX libs for handling Sega Master System hardware.

## Contents

- **smslib.asm** - common functions used by all the libs
- [input.asm](#inputasm) - interprets the joypad inputs
- [palette.asm](#paletteasm) - handles the colour palettes
- **sprites.asm** - manages a sprite table in a RAM and pushes to VRAM when required
- **vdp.asm** - graphics routines
- [vdpreg.asm](#vdpregasm) - defines and sets graphics chip register settings
- **z80.asm** - logical/math routines
- [/mapper](#mappers)

## Design principles

### Low level

The libs act as a thin layer to the Master System chips, to ensure they are applicable across many projects and engines. They provide macros and routines to abstract many of the nuances of Master System development, but don't aim to be a full-blown engine.

### Speed > Size

Over time the routines will be optimised for speed and size without one aspect adversely affecting the other. There will however be an emphasis on speed as code size is rarely a problem in Master System projects (especially compared to asset sizes) whereas speed can be a bottleneck, especially within VBlank timing constraints.

### Decoupled

The smslib.asm file contains common functionality used by the other lib files, but other than that the separate files don't reference each other and you can pick and choose which ones to include in your project.

### Prefixes

Each library file prefixes its labels with its name and a '.' (i.e. input.readPortA). Although it can make things more verbose it makes for much easier code tracking.

### No unnecessary pushing/popping

The library routines don't PUSH or POP registers to preserve them, meaning they will happily 'clobber' registers if need be. This shifts this responsibility to the code calling the library, mainly for efficiency reasons: the calling code knows what registers it actually cares about, so only needs to preserve those.

### No RAMSECTIONS

This may change, but the libs don't define RAMSECTIONS. They instead export structs, which the calling code can place in RAMSECTIONS in the location/slot they desire.

### Documentation

Each routine is documented with a comment block above it specifying the parameters (registers or macro arguments)

## input.asm

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
vdpInitData:
    vdpreg.defineInitData
vdpInitDataEnd:

vdpreg.load vdpInitData, vdpInitDataEnd
```

Change registers relative to default values:

```
vdpData:
    ; See vdpreg.asm for supported settings
    vdpreg.set vdpreg.ENABLE_DISPLAY    1   ; enable display
    vdpreg.set vdpreg.ENABLE_VBLANK     0   ; disable frame interrupts
    vdpreg.defineData
vdpDataEnd:

vdpreg.load vdpData, vdpDataEnd
```

Note: some options reside in the same VDP register (such as ENABLE_DIAPLSY and ENABLE_VBLANK) so setting one may reset another back to its default. Check vdpreg.asm for more details about which options share registers.

## palette.asm

Handles the VDP colour palettes. There are 31 colour slots:

- Sprites can only use the last 16 slots (16-31).
- Each background pattern (tile) can use either the first 16 slots (0-15) or
  the last 16 (16-31)

Each colour is a byte containing 2-bit RGB colour values (--BBGGRR). You can call `palette.rgb` with the RGB values to generate a colour byte with an approximate RGB value. Each colour component can have the value of 0, 85, 170 or 255. Values inbetween these will be rounded to the closest factor.

```
paletteStart:
    palette.rgb 255, 0, 0   ; red
    palette.rgb 255, 170, 0 ; orange
    palette.rgb 255, 255, 0 ; yellow
    palette.rgb 0, 255, 0   ; green
    palette.rgb 0, 0, 255   ; blue
    palette.rgb 85, 0, 85   ; indigo
    palette.rgb 170, 0, 255 ; violet
paletteEnd:

; load colours into slot 16 onwards
palette.setSlot 16
palette.load paletteStart, paletteEnd
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
