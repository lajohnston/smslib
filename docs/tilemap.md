# Tilemap (tilemap.asm)

Manages the tilemap, which places patterns/tiles in a grid to create the background image.

## Define tile data

Each tile in the map is 2 bytes - the first is a pattern slot reference  (see [patterns](./patterns.md)) and the second contains various attributes. The following attributes can be ORed together to create a byte containing all the attributes (i.e. tilemap.FLIP_X|tilemap.PRIORITY).

```
tilemap.HIGH_BIT        ; 9th bit for the pattern ref, allows pattern refs 256+
tilemap.FLIP_X          ; Flip horizontally
tilemap.FLIP_Y          ; Flip vertically
tilemap.FLIP_XY         ; Flip horizontally and vertically
tilemap.SPRITE_PALETTE  ; Use the sprite palette for the tile

; Place tile in front of sprites. Color 0 acts as transparent
tilemap.PRIORITY

; Spare bits - unused by the VDP but some games use them to hold custom attributes
; such as whether the tile is a hazard tile that costs the player health
tilemap.CUSTOM_1
tilemap.CUSTOM_2
tilemap.CUSTOM_3
```

### tilemap.tile

Define an individual tile.

```
tilemap.tile 0                  ; pattern 0
tilemap.tile 0 tilemap.FLIP_X   ; pattern 0, flipped horizontally
tilemap.tile 500                ; pattern 500 (tilemap.HIGH_BIT set automatically)
```

## Output ASCII data

```
.asciitable
    map " " to "~" = 0
.enda

message:
    .asc "Hello, world"
    .db $ff ; terminator byte

tilemap.setColRow 0, 0              ; top left tile
tilemap.loadBytesUntil $ff message  ; load from 'message' label until $ff reached
```

## Load bytes

Load bytes of data representing pattern refs. Each tile will contain the same [tile attributes](#tile-attributes). These attributes can be passed in as an optional 3rd parameter.

```
message:
    .asc "Hello, world"

tilemap.setColRow 5, 10         ; column 5, row 10
tilemap.loadBytes message 5     ; load first 5 bytes of message ('Hello')

; load 12 bytes, all flipped horizontally and vertically
tilemap.loadBytes message 12 (tilemap.FLIP_X|tilemap.FLIP_Y)
```

## Load tiles

### tilemap.loadRawRow

Load 32 uncompressed tiles.

```
myRow:
    .repeat 32
        tilemap.tile 5
    .endr

tilemap.setColRow 0, 0  ; write from column 0, row 0 onwards
ld hl, myRow            ; point to data
tilemap.loadRawRow      ; load data (32 tiles)
```

### tilemap.loadRawRows

Load multiple rows from an uncompressed tilemap. The visible tilemap is 32 tiles wide (columns) by 25 tiles high (rows) but the full map can be larger than the screen.

```
.define MAP_ROWS 64
.define MAP_COLS 64

myTilemap:
    .repeat MAP_ROWS
        .repeat MAP_COLS
            tilemap.tile 0
        .endr
    .endr

tilemap.setColRow 0, 0      ; load from column 0, row 0 onwards
ld hl, myTilemap            ; point to top left corner to load
ld b, tilemap.VISIBLE_ROWS  ; number of rows to load; all visible rows (25)
ld a, tilemap.MAP_COLS * 2  ; number of full map columns * 2 (each tile is 2 bytes)

tilemap.loadRawRows         ; load rows

```

## Scrolling

The tilemap supports 8-direction scrolling. This is optimised for use with a maximum of 8 pixels per frame for each axis (8 pixels for X-axis plus 8 pixels for Y-Axis) but the limit is not enforced. See `examples/07-scrolling` example for a working demo.

```
; Initialise
tilemap.reset           ; initialise RAM and scroll registers to 0

; Adjust once per frame
ld a, 1                 ; amount to scroll x (1 pixel right)
tilemap.adjustXPixels   ; positive values scroll right; negative scroll left

ld a, -1                ; amount to scroll y (1 pixel up)
tilemap.adjustYPixels   ; positive values scroll down; negative scroll up

; Detect if a column needs scrolling
tilemap.ifColScroll left, right, +
    left:
        ; handle left scroll
        jp +    ; (skip right label)

    right:
        ; handle right scroll
+:

; Detect if a row needs scrolling
tilemap.ifColScroll up, down, +
    up:
        ; handle up scroll
        jp +    ; (skip down label)

    down:
        ; handle down scroll
+:

; During VBlank
tilemap.setScrollRegisters
```
