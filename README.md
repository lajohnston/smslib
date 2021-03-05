# SMSLib - Sega Master System Z80 Libs

Low-level Sega Master System libs for the Z80 WLA-DX assembler. Its aim is to provide a consistent API for the hardware with zero/very low cost abstractions and to minimise the boilerplate required to get homebrew projects up and running quickly.

## Quick start

```
.incdir "lib/smslib"    ; set the working directory to the smslib directory
.include "smslib.asm"   ; include the libs

; SMSLib will call 'init' label once it has booted the system
init:
    ...
```

Each module is decoupled from the others and can be imported individually. `smslib.asm` is just a file that just pulls in all the modules for convenience.

## Examples

See example programs in the `examples` directory. Build the examples using the `build.sh` script (Linux). `wlalink` and `wla-z80` should be in your system path. The compiled .sms ROM will appear in the `examples/build` directory ready to be run in an emulator.

## Docs

- [init.asm](./docs/init.md) - initialises the system and smslib modules
- [input.asm](./docs/input.md) - interprets the joypad inputs
- [interrupts.asm](./docs/interrupts.md) - handles VBlank and HBlank interrupts
- [/mapper/\*.asm](./docs/mappers.md) - memory mapper handlers
- [palette.asm](./docs/palette.md) - handles the color palettes
- [patterns.asm](./docs/patterns.md) - handles patterns (tile images)
- [pause.asm](./docs/pause.md) - handles the pause button
- [sprites.asm](./docs/sprites.md) - manages a sprite table in a RAM and pushes to VRAM when required
- [tilemap.asm](./docs/tilemap.md) - handles the background tile
- [vdp.asm](./docs/vdp.md) - defines and sets graphics chip register settings

## Design Principles

### Low level

The libs act as a thin layer to the Master System chips to ensure they are applicable across many projects and engines. They provide macros and routines to abstract many of the nuances of Master System development so you can build a more fuller-blown engine on top of them.

### Priorities: Speed > Ease > Size

Over time the routines will be optimised for speed and size without one aspect adversely affecting the other. There will however be an emphasis on speed as code size is less of a problem in Master System projects (especially compared to asset sizes) whereas speed can be a bottleneck, especially within VBlank timing constraints.

- The lib is designed for ease of use so long as this doesn't reduce the speed of the generated code.
- The lib makes heavy use of macros to generate inline code and save on `call` and `ret` costs. The macros are though mindful of code size so will generate `call`s to large shared routines where necessary.

### Unsafe Register Preservation

As part of the speed priority the library routines will happily 'clobber' register values without preserving them onto the stack. This is because `push` and `pop` calls on multiple register pairs is expensive, and you may not even need some of them preserved.

The register values before and after a call may therefore change. This shifts the responsibility of preservation to you, mainly for efficiency reasons; you know best what registers you actually care about, so only need to preserve those. The flipside of this is that it is a bit of a 'gotcha' to be aware of.

### Decoupled

SMSLib modules are independent of one another so you can pick or choose only the ones you want. For convenience you can just include `smslib.asm` and this will pull them all in for you. In either case WLA-DX will only assemble the code you actually use.

### Namespaced Prefixes

Each library file prefixes its labels with its name and a '.' (i.e. input.readPortA). Although it can make things more verbose it makes for much easier code tracking and prevents naming collisions.

### Customisable

Many of the lib files include settings that default to sensible values but can be overridden if required. These are defined in the 'Settings' section near the top of each file. The overrides must be defined at some point before you `.include` the relevant file.

## Sources

The code and techniques utilised by the lib try to credit original authors where known. Of particular help was the thread [A few hints on coding a medium/large sized game using WLA-DX](https://www.smspower.org/forums/15794-AFewHintsOnCodingAMediumLargeSizedGameUsingWLADX) on the smslib.org forums.

Much of the information contained in the docs was learned from https://www.smspower.org, in particular the [Development documents](https://www.smspower.org/Development/Documents) section.
