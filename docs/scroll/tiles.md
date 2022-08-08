# scroll/tiles.md

Manages a scrollable tilemap consisting of raw uncompressed tiles (see [tilemap.asm](../tilemap.md) for more information about the tile data format). This builds on the API provided by [tilemap.asm](../tilemap.md).

## 1. Initialise the map

Initialise the map and draw the initial view using `scroll.tiles.init`. This should be performed when the display is off.

```
.define tilemapData ... ; the tilemap data (pointing to the top left of the map)
.define mapCols 64      ; the number of columns in the map (width in tiles); Max 127
.define mapRows 64      ; the number of rows in the map (height in tiles); Max 255
.define colOffset 0     ; columns to offset the initial view by
.define rowOffset 0     ; rows to offset the initial view by

scroll.tiles.init tilemapData mapCols mapRows colOffset rowOffset
```

If needed you can use registers for this, though you'll need to handle the initial view offsetting yourself in the top left pointer.

```
ld a,  mapCols * 2      ; number of bytes per row (columns * 2)
ld b,  mapRows          ; the number of rows in the tilemap
ld d,  1                ; column offset (1-based; 1 = none)
ld e,  1                ; row offset (1-based; 1 = none)
ld hl, tilemapData      ; pointer to our tilemap (top-left corner)

scroll.tiles.init       ; initialise and draw
```

## 2. Adjust once per frame

Adjust the x and y pixels by up to 8 pixels each per frame (-8 to +8 inclusive). This limit isn't enforced so ensure you stay within it for correct results.

```
; Negative x values move left, positive move right
ld a, 1                         ; move right 1 pixel
scroll.tiles.adjustXPixels
```

```
; Negative y values move up, positive move down
ld a, -2                        ; move up 2 pixels
scroll.tiles.adjustYPixels
```

After adjusting these, use `scroll.tiles.update` to apply the changes to the RAM buffers.

## 3. Transfer changes to VRAM (during VBlank)

`scroll.tiles.render` will apply the scroll register changes to the VDP, and write the new row and/or column to the tilemap if required.
