# Patterns (patterns.asm)

Loads patterns (tiles) into VRAM, which can be used for background images or sprites.

This module only deals with uncompressed tile data and is provided for example purposes to get you started. For an actual game you might want to compress pattern data using an algorithm such as zx7 or aPLib and use the appropriate lib to decompress the data and write it to VRAM.

## Data format

Patterns are an image of 8x8 (64) pixels. Each pixel is a 4-bit (half a byte) color palette index reference, making a total of 32-bytes (64 / 2).

The 4-bit color palette index value (0-15) can reference either index 0-15 or index 16-31 of the palette, depending on the context where the pattern is used; sprites use indices 16-31 whereas background tiles in the tilemap contain a bit that determines which to use. If the pattern is used for a sprite then the first color (index 16) is used as the 'transparent' color and is not visible.

Each row consists of 4 bytes. The pixels in each are encoded in bitplanes, so the bits of each are strewn across these 4-bytes. This is hard to explain, but given 8 pixels in a row (A, B, C, D, E, F, G, H), the row will be encoded as:

- Byte 0: A0 B0 C0 D0 E0 F0 G0 H0
- Byte 1: A1 B1 C1 D1 E1 F1 G1 H1
- Byte 2: A2 B2 C2 D2 E2 F2 G2 H2
- Byte 3: A3 B3 C3 D3 E3 F3 G3 H3

If pixel A's index was **1111** and the rest were 0000, the encoding would be:

- Byte 0: **1**000 0000
- Byte 1: **1**000 0000
- Byte 2: **1**000 0000
- Byte 3: **1**000 0000

If pixel B's index was **1101** and the rest were 0000, the encoding would be:

- Byte 0: 0**1**00 0000
- Byte 1: 0**1**00 0000
- Byte 2: 0**0**00 0000
- Byte 3: 0**1**00 0000

## Usage

### patterns.writeBytes

Writes uncompressed pattern data into VRAM.

Due to WLA-DX limitations the size parameter must be an `immediate` value, so cannot be calculated using something like `endAddr - startAddr`. It can therefore either be a constant, or if using `fsize` to calculate the size of an included binary you just have to ensure this label is defined before this macro is called.

```asm
uncompressedPatternData:
    .incbin "tiles.bin" fsize patternDataSize

; Write pattern data from index 16 onwards
patterns.setIndex 16
patterns.writeBytes uncompressedPatternData, patternDataSize
```

### patterns.writeSlice

Lets you pick out certain tiles from the binary data and write them individually.

```asm
myUncompressedPatternData:
    .incbin 'tiles.bin'

; Write 4 patterns into pattern index 0 onwards (indices 0-3)
patterns.setIndex 0
patterns.writeSlice myUncompressedPatternData, 4

; ...then write another pattern into the next index (index 4)
patterns.writeSlice myUncompressedPatternData, 1
```

An optional third parameter lets you skip a certain number of patterns in the data:

```asm
; Write another pattern, skipping the first 9
patterns.writeSlice otherPatternData, 1, 9
```

### Settings

If you wish to change the below defaults, use `.define` to define these value at some point before you import the library.

### patterns.VRAM_ADDRESS

The pattern address in VRAM. Defaults to $0000
