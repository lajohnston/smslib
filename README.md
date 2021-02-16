# Sega Master System Z80 Libs

Low level Z80 WLA-DX libs for handling Sega Master System hardware. Its aim is to provide a consistent API for the hardware with zero/very low cost abstractions and to minimise the boilerplate required to get homebrew projects up and running quickly.

## Contents

- [boot.asm](./docs/boot) - boots the system and initialises smslib modules
- [input.asm](./docs/input) - interprets the joypad inputs
- [interrupts.asm](#interruptsasm) - handles VBlank and HBlank interrupts
- [palette.asm](#paletteasm) - handles the color palettes
- [patterns.asm](./docs/patterns) - handles patterns (tile images)
- [pause.asm](#pauseasm) - handles the pause button
- [sprites.asm](#spritesasm) - manages a sprite table in a RAM and pushes to VRAM when required
- [tilemap.asm](#tilemapasm) - handles the background tile
- [vdpreg.asm](#vdpregasm) - defines and sets graphics chip register settings
- [/mapper](#mappers)

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

## interrupts.asm

Creates an efficient handler for VBlank and/or HBlank interrupts.

### Enabling interrupts

You will need to enable interrupts in both the VDP and Z80. After you initialise your game you can enable VBlanks and HBlanks in the VDP using registers 0 and 1:

- Enable HBlank - VDP register 0, bit 4
- Enable VBlank - VDP register 1, bit 5

You can use [vdpreg.asm](#vdpregasm) for this, taking care not to overwrite any other flags that are also stored within these registers (see vdpreg.asm file for documentation):

```
vdpreg.enableHBlank
vdpreg.enableVBlank
```

You also need to enable interrupts within the Z80 CPU:

```
interrupts.enable
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
    jp gameLoop         ; run loop again
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

## mappers

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
mapper.pageBank :paletteData                ; page to the paletteData
palette.load 0, paletteData, paletteDataEnd ; paletteData is now accessible
```

You can customise some mappers with additional parameters. Check the relevant mapper asm file to see which settings are supported.

```
.define mapper.pageableBanks 4
.include "smslib/mapper/waimanu.asm"
```

## palette.asm

Handles the VDP color palettes. There are 32 color slots:

- Each background pattern (tile) can use either the first 16 slots (0-15) or
  the last 16 (16-31)
- Sprites can only use the last 16 slots (16-31). Slot 16 is used for its transparent color

The color in each slot is a byte containing 2-bit RGB color values (--BBGGRR). You can call `palette.rgb` with the RGB values to generate a color byte with an approximate RGB value. Each color component can have the value of 0, 85, 170 or 255. Values inbetween these will be rounded to the closest factor.

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

## vdpreg.asm

Handles the VDP registers and settings.

Change register values using the provided macros. See vdpreg.asm for more details about each setting.

```
vdpreg.setBackgroundColorSlot 16
vdpreg.setScrollX 100
vdpreg.setScrollY 255

vdpreg.enableDisplay
vdpreg.disableDisplay

vdpreg.enableVBlank
vdpreg.disableVBlank

vdpreg.enableTallSprites
vdpreg.disableTallSprites

vdpreg.enableSpriteZoom
vdpreg.disableSpriteZoom

vdpreg.enableHBlank
vdpreg.disableHBlank

vdpreg.enableSpriteShift
vdpreg.disableSpriteShift

vdpreg.hideLeftColumn
vdpreg.showLeftColumn

vdpreg.lockHScroll
vdpreg.unlockHScroll

vdpreg.lockVScroll
vdpreg.unlockVScroll
```

Many settings are stored within the same VDP register, so if you are changing multiple settings then it's much more efficient to batch them together by wrapping them in calls to `vdpreg.startBatch` and `vdpreg.endBatch`:

```
vdpreg.startBatch
vdpreg.enableDisplay
vdpreg.enableVBlank
vdpreg.endBatch
```
