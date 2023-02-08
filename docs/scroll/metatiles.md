# scroll/metatiles.asm

A scroll handler that groups tiles together into 'metatiles', reducing the amount of memory required and allowing for much larger tilemaps. This handler builds on the API provided by [tilemap.asm](../tilemap.md).

A typical workflow is to compress the tilemaps in ROM then decompress them to RAM so they can be scrolled quickly, but this requires enough RAM to store the decompressed tilemap. An individual tile uses 2-bytes of memory so a screen of 32x24 tiles would take up 1536-bytes. 4KB of RAM (half the amount available) would therefore still only be enough to store 2.5 screens.

A 2x2 metatile combines 4 individual tiles together and refers to them in a single byte, so what would have taken 8-bytes in the tilemap now takes 1-byte. For the same amount of RAM you can therefore have maps 8x as large. Further space savings and map size increases can be made by increasing the number of tiles in the metatiles, at the cost of potentially reducing the complexity and uniqueness of the graphics you can display at a given time.

| Metatile size | Space saving/Map size increase|
|---------------|-------------------------------|
| 2x2           | 8x                            |
| 2x4           | 16x                           |
| 2x8           | 32x                           |
| 4x4           | 32x                           |
| 2x16          | 64x                           |
| 4x8           | 64x                           |
| 4x16          | 128x                          |
| 8x8           | 128x                          |
| 8x16          | 256x                          |
| 16x16         | 512x                          |


## Importing the handler and setting the metatile size

The module isn't included by default so will need to be included. You can specify the size of each metatile in rows and columns (allowed value: 2, 4, 8, 16). They default to 2.

```
.define scroll.metatiles.COLS_PER_METATILE 4
.define scroll.metatiles.ROWS_PER_METATILE 4
.include "scroll/metatiles.asm"
```

## Data Format

### Metatile definitions

The definitions contain the raw tile data stored sequentially (i.e. the top row of subtiles is stored from left to right, then the second row, etc.). See [tilemap.asm](../tilemap.md) for more information about the tile data format. The definitions should be aligned to the `scroll.metatiles.DEFS_ALIGN` value:

```
.section "myMetatileDefs" free align scroll.metatiles.DEFS_ALIGN
    my2x2MetatileDefs:
        ;===
        ; Metatile #0
        ;===
        ; Row 1
        tilemap.tile 0  ; left tile, pattern #0
        tilemap.tile 1  ; right tile, pattern #1

        ; Row 2
        tilemap.tile 2  ; left tile, pattern #2
        tilemap.tile 3  ; right tile, pattern #3

        ;===
        ; Metatile #1
        ;===
        ; Row 1 ...
        ; Row 2 ...
.ends
```

You can define multiple sets of these and specify which to use with `scroll.metatiles.setDefs`:

```
ld hl, my2x2MetatileDefs
scroll.metatiles.setDefs
```

## Metatilemap data

The tilemap consists of 1-byte references that each point to one of the current 256 metatile definitions. Due to optimisations within the lookup code the metatile reference may not always match up with the order defined in the metatile definitions. You can use `scroll.metatiles.ref` to define a byte containing the correct reference number.

```
scroll.metatiles.ref 0      ; the first metatile definition
scroll.metatiles.ref 1      ; the second metatile definition
scroll.metatiles.ref 255    ; the last metatile definition
```

The width of the tilemap is variable at runtime to allow a variety of level sizes, but the width * height must fit within the map RAM buffer. This buffer size is determined by the `scroll.metatiles.MAX_MAP_BYTES` value which defaults to 4096, meaning a map with a width of 128 would have a height of 32 (4096 / 128).

You can change the RAM allocation by setting the `scroll.metatiles.MAX_MAP_BYTES` value before importing the module:

```
; 2048 bytes of RAM will be allocated to the map, restricting its maximum height
.define scroll.metatiles.MAX_MAP_BYTES 2048
.include "scroll/metatiles.asm"
```

An example 64x32 metatile map. 64*32 = 2048, so this will fit into 2048-bytes of RAM.

```
; 32 metatile rows (height)
.repeat 32
    ; Each row contains 64 metatile columns (width)
    .repeat 64
        scroll.metatiles.ref 5  ; the 6th metatile definition (0-based)
    .endr
.endr
```

## Usage

### 1. Initialise the map

Draw the initial view of the map when the display is off.

```
; Set the address of the metatile definitions
ld hl, myMetatileDefs
scroll.metatiles.setDefs

ld a, 64                ; the map has a width of 64 metatiles
ld d, 64                ; the map has a height of 64 metatiles. Only required
                        ; if ENFORCE_BOUNDS is enabled
ld b, 0                 ; starting column offset, in metatiles
ld c, 0                 ; starting row offset, in metatiles
scroll.metatiles.init   ; draw map
```

### 2. Adjust once per frame

Adjust the x and y pixels by up to 8 pixels each per frame (-8 to +8 inclusive). This limit isn't enforced so ensure you stay within it for correct results.

```
; Negative x values move left, positive move right
ld a, 1                         ; move right 1 pixel
scroll.metatiles.adjustXPixels
```

```
; Negative y values move up, positive move down
ld a, -2                        ; move up 2 pixels
scroll.metatiles.adjustYPixels
```

After adjusting these, use `scroll.metatiles.update` to apply the changes to the RAM buffers.

### 3. Transfer changes to VRAM (during VBlank)

`scroll.metatiles.render` will apply the scroll register changes to the VDP, and write the new row and/or column to the tilemap if required.

## Bounds Checking

Optional bounds checking can be enabled to ensure the map doesn't scroll beyond the edges of the map data, at the cost of a few bytes of RAM and some additional cycles. This is disabled by default which means if the map does scroll out of bounds the scrolled rows and columns will contain junk data.

Depending on your engine and map designs you might not need these additional checks, for example if the edges of the maps have space around them that the player can't actually move beyond.

```
.define scroll.metatiles.ENFORCE_BOUNDS
.include "scroll/metatiles.asm"
```
