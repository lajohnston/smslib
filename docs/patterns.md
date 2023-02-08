# Patterns (patterns.asm)

Loads patterns (tiles) into the VRAM, which can be used for background images or sprites.

This only deals with uncompressed tile data and is provided for example purposes to get you started. For an actual game you would want to compress pattern data using an algorithm such as zx7 or aPLib and use the appropriate lib to decompress the data and send it to VRAM.

## patterns.load

Loads uncompressed pattern data into VRAM.

Due to WLA-DX limitations the size parameter must be an `immediate` value, so cannot be calculated using something like `endAddr - startAddr`. It can therefore either be a constant, or if using `fsize` to calculate the size of an included binary you just have to ensure this label is defined before this macro is called.

```
uncompressedPatternData:
    .incbin "tiles.bin" fsize patternDataSize

; load pattern data from index 16 onwards
patterns.setIndex 16
patterns.load uncompressedPatternData, patternDataSize
```

## patterns.loadSlice

Lets you pick out certain tiles from the binary data and load them individually.

```
myUncompressedPatternData:
    .incbin 'tiles.bin'

; load 4 patterns into pattern index 0 onwards (indices 0-3)
patterns.setIndex 0
patterns.loadSlice myUncompressedPatternData, 4

; ...then load another pattern into the next index (index 4)
patterns.loadSlice myUncompressedPatternData, 1
```

An optional third parameter lets you skip a certain number of patterns in the data:

```
; load another pattern, skipping the first 9
patterns.loadSlice otherPatternData, 1, 9
```

## Data format

Patterns are an image of 8x8 pixels. Each pixel is a 4-bit color palette index reference, making a total of 32-bytes.

The 4-bit color palette index value (0-15) can reference either index 0-15 or index 16-31 of the palette, depending on the context where the pattern is used; sprites use indices 16-31 whereas background tiles in the tilemap contain a bit that determines which to use. If the pattern is used for a sprite then color index 0 is used as the transparent color (i.e. not drawn)

Pixels are encoded in bitplanes so the bits of each are strewn across 2-bytes. This is hard to explain, but given 4 pixels (A, B, C, D), the ordering of each bit will be bitplane encoded as:

- Byte 1: A1 B1 C1 D1, A2 B2 C2 D2
- Byte 2: A3 B3 C3 D3, A4 B4 C4 D4

If A was 1111 and the rest were 0000, the encoding would be:

- Byte 1: **1**000 **1**000
- Byte 2: **1**000 **1**000

If B was 1101 and the rest were 0000, the encoding would be:

- Byte 1: 0**1**00 0**1**00 (first two bits- 1, 1)
- Byte 2: 0**0**00 0**1**00 (second two bits - 0, 1)

## Settings

If you wish to change these defaults, use `.define` to define these value at some point before you import the library.

### patterns.address

The pattern address in VRAM. Defaults to $0000
