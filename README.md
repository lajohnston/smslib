# Sega Master System Z80 Libs

Low level Z80 WLA-DX libs for handling Sega Master System hardware.

## Contents

- [smslib.asm](#smslibasm) - common functions used by all the libs
- [input.asm](#inputasm) - interprets the joypad inputs
- [interrupts.asm](#interruptsasm) - handles VBlank and HBlank interrupts
- [palette.asm](#paletteasm) - handles the color palettes
- [patterns.asm](#patternsasm) - handles patterns (tile images)
- [pause.asm](#pauseasm) - handles the pause button
- [sprites.asm](#sprites) - manages a sprite table in a RAM and pushes to VRAM when required
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

The smslib.asm file contains common functionality used by the other lib files, but other than that the separate files don't depend on each other and you can pick and choose which ones to include in your project.

### Prefixes

Each library file prefixes its labels with its name and a '.' (i.e. input.readPortA). Although it can make things more verbose it makes for much easier code tracking.

### Unsafe register preservation

The library routines don't generally PUSH or POP registers to preserve them, meaning they will happily 'clobber' registers if need be. This shifts the responsibility of preservation to the code calling the library, mainly for efficiency reasons: the calling code knows what registers it actually cares about, so only needs to preserve those.

### Documentation

Each routine is documented with a comment block above it specifying the parameters (registers or macro arguments)

## Settings

Many of the lib files include settings that default to sensible values but can be overridden if required. These are defined in the 'Settings' section near the top of each file. The overrides must be defined before including the relevant file:

```
.define smslib.outiBlockSize 1024
.include "smslib.asm"
```

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

If needed you can change the register that holds the input value (default is `b`):

```
.redefine input.register "d"
.input.readPort1 ; result stored in register d
```

## interrupts.asm

Creates an efficient handler for VBlank and/or HBlank interrupts.

### Enabling interrupts

You will need to enable interrupts in both the VDP and Z80. After you initialise your game you can enable VBlanks and HBlanks in the VDP using registers 0 and 1:

- Enable HBlank - VDP register 0, bit 4
- Enable VBlank - VDP register 1, bit 5

You can use [vdpreg.asm](#vdpregasm) for this, taking care not to overwrite any other flags that are also stored within these registers (see vdpreg.asm file for documentation):

```
vdpreg.setRegister0 vdpreg.ENABLE_HBLANK
vdpreg.setRegister1 vdpreg.ENABLE_DISPLAY|vdpreg.ENABLE_VBLANK
```

You also need to enable interrupts within the Z80 CPU:

```
interrupts.enable
```

### Initialise

In your init code call `interrupts.init`. This is performed automatically if you're using `smslib.init`.

```
interrupts.init
```

If you're using an smslib mapper then this will need to be imported first as it specifies the RAM slot to use. If you're not using a mapper then you will need to define an `smslib.RAM_SLOT` value before importing `interrupts.asm`:

```
.define smslib.RAM_SLOT 3
.include "interrupts.asm"
```

### VBlanks (frame interrupts)

VBlanks occur each time the VDP has finished drawing a frame (50 times a second in PAL, 60 times a second in NTSC). It's a small window of opportunity to blast data to the VDP before it starts drawing the next frame. Sending data to the VDP outside this window can result in missed writes and graphical corruption. The only other safe time to write to the VDP is when the display is off.

Enable the VBlank handler by defining `interrupts.handleVBlanks` setting before including `interrupts.asm`:

```
.define interrupts.handleVBlanks 1
.include "interrupts.asm"
```

You will also need to define an `interrupts.onVBlank` label that the handler will jump to when a VBlank occurs. This handler must end with a macro call to `interrupts.endVBlank`:

```
interrupts.onVBlank:
    ...                     ; send data to VDP
    interrupts.endVBlank    ; return from VBlank
```

VBlanks can also be used to regulate the speed of your game logic. Place `interrupts.waitForVBlank` in your game loop to ensure the logic doesn't update too quickly.

```
gameLoop:
    interrupts.waitForVBlank
    ... update logic
    jp gameLoop
```

### HBlanks (line interrupts)

HBlanks occur when the line counter in the VDP falls below zero. This counter is set to the value stored in VDP Register 10 before the frame is drawn and each time a line is drawn (from top to bottom) it is decremented. Further documentation on this can be found in Richard Talbot-Watkins documentation on [VDP Register 10](https://www.smspower.org/uploads/Development/richard.txt).

Enable the HBlank handler by defining `interrupts.handleHBlanks` setting before including `interrupts.asm`:

```
; Note: you can also enable interrupts.handleVBlanks alongside this if you wish
.define interrupts.handleHBlanks 1
.include "interrupts.asm"
```

You will also need to define an `interrupts.onHBlank` label that the handler will jump to when an HBlank occurs. This handler must end with a macro call to `interrupts.endHBlank`:

```
interrupts.onHBlank:
    ...
    interrupts.endHBlank    ; return from HBlank
```

The HBlank won't trigger unless the line interval has been set. This takes a zero-based value:

```
interrupts.setLineInterval 1    ; trigger HBlank every line (lines 0, 1, 2...)
interrupts.setLineInterval 10   ; trigger every 10th line (lines 9, 19, 29...)
```

This can also be set dynamically from `a` by omitting the argument. When using this method the value in `a` must be 0-based:

```
; Trigger every 20th line
ld a, 19
interrupts.setLineInterval
```

Please note that if you change the interval during active screen time, the new interval won't take effect until the next HBlank has occurred. This means that each interval you specify will trigger a minimum of 2 times, i.e. an interval every 10 lines will trigger for lines 9 (0-based) and line 19 even if you change it after line 9.

You can read the current line being drawn. The value will be loaded into `a`

```
interrupts.getLine
```

# mappers

The Master System can only view 48KB of ROM memory at a time. Mappers control which portions of ROM are visible within this 48KB window and can dynamically switch portions at runtime to allow for much larger cartridge sizes. The included smslib mappers can abstract this complexity from you or can be used as examples to create your own.

Include the mapper you wish to use:

```
.include "smslib/mapper/waimanu.asm"
```

Initialise the SMS mapping registers when booting your game. This will be done for you if you're using `smslib.init`

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

# pause.asm

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

# smslib.asm

Base library containing common functionality for the other modules.

Use `smslib.init` to initialise the system (disable interrupts, set stack pointer, clear vram). This should be placed in a section at .orga 0. `smslib.init` will also initialise the other smslib modules you've included, such as sprites, mapper and vdpreg to initialise the sprite buffer, paging registers and VDP registers respectively.

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

# sprites.asm

Manages a sprite table buffer in RAM and can push this to VRAM when required.

Create an instance of sprite.Buffer in RAM with an address of \$xx40 and the label 'sprites.buffer'. This offset allows it to perform some optimisations:

```
.ramsection "ram" bank 0 slot mapper.RAM_SLOT orga $C040 force
    sprites.buffer: instanceof sprites.Buffer
.ends
```

Initialise the table. This is done automatically if you use `smslib.init`:

```
sprites.init
```

Add sprites to the table:

```
sprites.setSlot 0   ; point to first sprite slot in table
ld a, 100           ; yPos
ld b, 80            ; xPos
ld c, 5             ; pattern number
sprites.add

; Add a sprite to slot 1 (not need to call sprites.setSlot again)
ld a, 150           ; yPos
ld b, 30            ; xPos
ld c, 5             ; pattern number
sprites.add

```

Add multiple sprites with positions relative to a base position. The offsets must be positive numbers, so the base position is the top-left of the entity. If any sub-sprites fall off screen they will not be added:

:

```
spriteGroup:
    ; pattern number, relX, relY
    sprites.sprite 1, 0, 0  ; top left
    sprites.sprite 2, 8, 0  ; top right
    sprites.sprite 3, 0, 8  ; bottom left
    sprites.sprite 4, 8, 8  ; bottom right
    sprites.endGroup        ; end of group

code:
    ld hl, spriteGroup
    ld b, 150   ; base x pos
    ld c, 50    ; base y pos
    sprites.addGroup
```

Mark when you've finished adding sprites. This will tell the VDP to stop processing the table from that point:

```
sprites.end
```

Transfer buffer to VRAM when safe to do so, when either the display is off or during VBlank:

```
sprites.copyToVram
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

## vdpreg.asm

Handles the VDP registers and settings.

Initialise the VDP registers with sensible initial defaults. This will be done for you if you use `smslib.init`:

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
