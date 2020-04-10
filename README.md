# Sega Master System Z80 Libs

Low level Z80 ASM libs for handling Sega Master System hardware.

## Contents

- **smslib.asm** - some common functions used by all the libs
- [input.asm](#inputasm) - reading the joypad inputs
- **sprites.asm** - manages a sprite table in a RAM and pushes to VRAM when required
- [vdpreg.asm](#vdpregasm) - defines and sets graphics chip register settings
- **vdp.asm** - graphics routines
- **z80.asm** - logical/math routines

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

```
vdpreg.set vdpreg.DISPLAY_ENABLED 0             ; disable display
vdpreg.set vdpreg.FRAME_INTERRUPTS_ENABLED 1    ; enable frame interrupts

; send the settings to the VDP
vdpreg.apply
```

See the vdpreg.asm file for all supported settings.
