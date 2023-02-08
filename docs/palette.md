# Color Palette (palette.asm)

Handles the VDP color palettes. There are 2 palettes of 16 color slots:

- Each background pattern (tile) can use either the first 16 slots (0-15) or
  the last 16 (16-31)
- Sprites can only use the last 16 slots (16-31)

The first color slot of each palette (slot 0 or slot 16) is used as the transparent color. This color will be omitted for sprites. Background tiles aren't affected by it unless they are marked as a 'priority' in the tilemap. Priority background patterns are rendered in front of sprites, except for the first color which is rendered behind.

The color in each slot is a byte containing 2-bit RGB color values (--BBGGRR).

The pixel values defined within tiles/patterns don't define their colors directly but rather reference the color slots you set in the palette.

## Setting palette colors

To get you started you can call `palette.rgb` with some RGB values to generate a color byte with an approximate RGB value. In reality you'll probably use a tool to generate this data for you from image data (such as [BMP2Tile](https://www.smspower.org/maxim/Software/BMP2Tile)).

Each color component can have the value of 0, 85, 170 or 255. Values inbetween these will be rounded to the closest factor.

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

You can then load these into the VDP VRAM the following macros.

### palette.load

Load palette data from a binary file to VRAM.

```
myPaletteData:
  .incbin "myPalette.inc" fsize myPaletteDataSize

palette.setIndex 0
palette.load myPaletteData, myPaletteDataSize
```

### palette.loadSlice

Load specific colors from the data.

```
palette.setIndex 0                    ; point to first palette index
palette.loadSlice paletteData, 3      ; load 3 colors from current index onwards (indices 0, 1, 2)
palette.loadSlice otherPaletteData, 2 ; then load 2 more colors (indices 3 and 4)
```

An optional third parameter lets you skip some colors in the data:

```
; Load 5 colors but skip the first 2
palette.loadSlice paletteData, 5, 2
```

### palette.loadRGB

Loads an approximate RGB value into the current palette slot. Each component is rounded to the nearest of the following values: 0, 85, 170, 255.

```
palette.setIndex 0
palette.loadRGB 255, 0, 0  ;  a bright red
```