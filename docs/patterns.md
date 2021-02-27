# Patterns (patterns.asm)

Loads patterns (tiles) into the VRAM, which can be used for background images or sprites.

This only deals with uncompressed tile data and is provided for example purposes to get you started. For an actual game you would want to compress pattern data using an algorithm such as zx7 or aPLib and use the appropriate lib to decompress and send to VRAM.

## Usage

## patterns.loadSlice

Lets you pick out certain tiles from binary data and load them individually.

```
myUncompressedPatternData:
    .incbin 'tiles.bin'

; Load 4 patterns into pattern slot 0 onwards (slots 0-3)
patterns.setSlot 0
patterns.loadSlice myUncompressedPatternData, 4

; ...then load another pattern into the next slot (slot 4)
patterns.loadSlice myUncompressedPatternData, 1
```

An optional third parameter lets you skip a certain number of patterns in the data:

```
; load another pattern, skipping the first 9
patterns.loadSlice otherPatternData, 1, 9
```

## Data format

Patterns are an image of 8x8 pixels. Each pixel is a 4-bit color palette slot reference, making a total of 32-bytes.

The 4-bit color palette slot value (0-15) can reference either slots 0-15 or slots 16-31 of the palette, depending on the context where the pattern is used; sprites use slots 16-31 whereas background tiles in the tilemap contain a bit that determines which to use. If the pattern is used for a sprite then color slot 0 is used as the transparent color (i.e. not drawn)

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
