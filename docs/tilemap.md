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
