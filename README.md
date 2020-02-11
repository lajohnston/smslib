# Sega Master System Z80 Libs

- **smslib.asm** - some common functions used by all the libs
- **input.asm** - reading the joypad inputs
- **sprites.asm** - maintains a sprite table in a RAM and pushes to VRAM when required
- **vdpreg.asm** - defines and sets graphics chip register settings
- **vdp.asm** - graphics routines
- **z80.asm** - logical/math routines

## Design principles for the Libs

### Decoupled

The smslib.asm file contains common functionality used by the other lib files, but other than that the separate files don't reference each other and you can pick and choose which ones to include in your project.

### Low level

The libs act as a thin layer to the Master System chips, to ensure they are applicable across many projects and engines. They provide macros and routines to abstract many of the nuances of Master System development, but don't aim to be a full-blown engine.

### Speed > Size

Over time the routines will be optimised for speed and size without one aspect adversely affecting the other. There will however be an emphasis on speed, as code size is rarely a problem in Master System projects whereas speed can be a bottleneck, especially within VBlank timing constraints.

### Prefixes

Each library file prefixes its labels with its name and a '.' (i.e. input.readPortA)

### No unnecessary pushing/popping

The library routines don't PUSH or POP registers to preserve them, meaning they will happily 'clobber' registers if need be. This shifts this responsibility to the code calling the library, mainly for efficiency reasons: the calling code knows what registers it actually cares about, so only needs to preserve those.

### No RAMSECTIONS

This may change, but the libs don't define RAMSECTIONS. They instead export structs, which the calling code can place in RAMSECTIONS in the location/slot they desire.

### Documentation

Each routine is documented with a comment block above it specifying the parameters (registers)
