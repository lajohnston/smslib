# Sega Master System Z80 Libs

Low level Z80 WLA-DX libs for handling Sega Master System hardware. Its aim is to provide a consistent API for the hardware with zero/very low cost abstractions and to minimise the boilerplate required to get homebrew projects up and running quickly.

## Contents

- [boot.asm](./docs/boot) - boots the system and initialises smslib modules
- [input.asm](./docs/input) - interprets the joypad inputs
- [interrupts.asm](./docs/interrupts) - handles VBlank and HBlank interrupts
- [/mapper/\*.asm](./docs/mappers)
- [palette.asm](./docs/palette) - handles the color palettes
- [patterns.asm](./docs/patterns) - handles patterns (tile images)
- [pause.asm](#pauseasm) - handles the pause button
- [sprites.asm](#spritesasm) - manages a sprite table in a RAM and pushes to VRAM when required
- [tilemap.asm](#tilemapasm) - handles the background tile
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

SMSLib modules are independent of one another so you can pick or choose only the ones you want.

### Namespaced prefixes

Each library file prefixes its labels with its name and a '.' (i.e. input.readPortA). Although it can make things more verbose it makes for much easier code tracking and prevents naming collisions.

### Unsafe register preservation

The library routines don't generally PUSH or POP registers to preserve them, meaning they will happily 'clobber' registers if need be. This shifts the responsibility of preservation to the code calling the library, mainly for efficiency reasons: the calling code knows what registers it actually cares about, so only needs to preserve those.

# Documentation

## pause.asm

Provides a pause handler that toggles a flag in RAM whenever the pause button is pressed. This flag can be detected at a safe position in your code such as at the start of the game loop.

Basic pause functionality can be provided by simply waiting until the pause button is pressed again:

```
pause.waitIfPaused
```

If you wish to jp or call a label based on the pause state, you can use the following:

```
pause.jpIfPaused myPauseState
pause.callIfPaused myPauseState

myPauseState:
    ...
```

## sprites.asm

Manages a sprite table buffer in RAM and outputs it to VRAM when required.

First, reset the sprite buffer at the start of each game loop:

```
sprites.reset
```

Add sprites to the buffer:

```
ld a, 100           ; yPos
ld b, 80            ; xPos
ld c, 5             ; pattern number
sprites.add
```

Sprite groups allow you to add multiple sprites with their positions relative to an anchor point. The offsets must be positive numbers. If any sub-sprites fall off screen they will not be added:

```
; Create 2x2 sprite
spriteGroup:
    ; pattern number, relX, relY
    sprites.sprite 1, 0, 0  ; top left
    sprites.sprite 2, 8, 0  ; top right (x + 8)
    sprites.sprite 3, 0, 8  ; bottom left (y + 8)
    sprites.sprite 4, 8, 8  ; bottom right (x + 8, y + 8)
    sprites.endGroup        ; end of group

code:
    ld hl, spriteGroup
    ld b, 150   ; anchor x pos
    ld c, 50    ; anchor y pos
    sprites.addGroup
```

It is more efficient adding multiple sprites and/or sprite groups within a batch. This allows smslib avoid having to store and retrieve the next slot from RAM for each sprite, and instead can do it once at the beginning of the batch and once at the end. During a batch the next sprite slot will be kept in `de` and incremented each time so be careful not to clobber this:

```
sprites.startBatch
... ; add multiple sprites
sprites.endBatch
```

Transfer buffer to VRAM when safe to do so, when either the display is off or during VBlank:

```
sprites.copyToVram
```

## tilemap.asm

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
