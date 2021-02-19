# Sega Master System Z80 Libs

Low level Z80 WLA-DX libs for handling Sega Master System hardware. Its aim is to provide a consistent API for the hardware with zero/very low cost abstractions and to minimise the boilerplate required to get homebrew projects up and running quickly.

## Contents

- [boot.asm](./docs/boot) - boots the system and initialises smslib modules
- [input.asm](./docs/input) - interprets the joypad inputs
- [interrupts.asm](./docs/interrupts) - handles VBlank and HBlank interrupts
- [/mapper/\*.asm](./docs/mappers)
- [palette.asm](./docs/palette) - handles the color palettes
- [patterns.asm](./docs/patterns) - handles patterns (tile images)
- [pause.asm](./docs/pause) - handles the pause button
- [sprites.asm](./docs/sprites) - manages a sprite table in a RAM and pushes to VRAM when required
- [tilemap.asm](./docs/tilemap) - handles the background tile
- [vdpreg.asm](./docs/vdpreg) - defines and sets graphics chip register settings

## Usage

```
.incdir "lib/smslib"    ; set the working directory to the smslib directory
.include "smslib.asm"   ; include the libs

; SMSLib will call 'init' label once it has booted the system
init:
    ...
```

See example programs in the `examples` directory. Build the examples using the `build.sh` script (Linux). wlalink and wla-z80 should be in your system path. The compiled .sms ROM will appear in the `examples/build` directory.

Each module is decoupled from the others and can be imported individually without having to include `smslib.asm`.

### Settings

Many of the lib files include settings that default to sensible values but can be overridden if required. These are defined in the 'Settings' section near the top of each file. The overrides must be defined at some point before you `.include` the relevant file.

## Design principles

### Low level

The libs act as a thin layer to the Master System chips, to ensure they are applicable across many projects and engines. They provide macros and routines to abstract many of the nuances of Master System development so you can build a more fuller-blown engine on top of them.

### Priorities: Speed > Ease > Size

Over time the routines will be optimised for speed and size without one aspect adversely affecting the other. There will however be an emphasis on speed as code size is rarely a problem in Master System projects (especially compared to asset sizes) whereas speed can be a bottleneck, especially within VBlank timing constraints.

The libs are also designed for ease of use so long as this doesn't reduce the speed of the generated code.

### Decoupled

SMSLib modules are independent of one another so you can pick or choose only the ones you want. For convenience you can just include `smslib.asm` and this will pull them all in for you and WLA-DX will only assemble the code you actually use.

### Namespaced prefixes

Each library file prefixes its labels with its name and a '.' (i.e. input.readPortA). Although it can make things more verbose it makes for much easier code tracking and prevents naming collisions.

### Unsafe register preservation

The library routines don't generally PUSH or POP registers to preserve them, meaning they will happily 'clobber' registers if need be. This shifts the responsibility of preservation to the code calling the library, mainly for efficiency reasons: the calling code knows what registers it actually cares about, so only needs to preserve those.
