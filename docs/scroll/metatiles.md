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

## Metatilemap data

The tilemap consists of 1-byte references to these definitions, allowing 256 metatiles at a time. The width of the tilemap is variable, but currently must be either 16, 32 or 64. The maximum height is then determined by how much RAM has been allocated for the map. This defaults to 4096-bytes, so with a width of 32 the maximum height of the map would be 128 (4096 / 32 = 128).

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
        .db 2   ; fill map with metatile #2
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

ld b, scroll.metatiles.WIDTH_64 ; map has a width of 64 metatiles
ld d, 0                         ; starting column offset, in metatiles
ld e, 0                         ; starting row offset, in metatiles
scroll.metatiles.init           ; draw map
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

Note: The metatile scroll handler doesn't currently enforce bounds checking, so the scroll could potentially start drawing non-existent tiles off the screen.

### 3. Transfer changes to VRAM (during VBlank)

`scroll.metatiles.render` will apply the scroll register changes to the VDP, and write the new row and/or column to the tilemap if required.
