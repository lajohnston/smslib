# Tilemap (tilemap.asm)

Manages the tilemap, which places patterns/tiles in a grid to create the background image.

## Output ASCII data

```
.asciitable
    map " " to "~" = 0
.enda

message:
    .asc "Hello, world"
    .db $ff ; terminator byte

tilemap.setSlot 0, 0 ; top left tile slot
tilemap.loadBytesUntil $ff message  ; load from 'message' label until $ff reached
```

## Load bytes

Load bytes of data representing pattern refs. Each tile will contain the same tile attributes. These attributes can be passed in as an optional 3rd parameter.

```
message:
    .asc "Hello, world"

tilemap.setSlot 0, 0            ; top left
tilemap.loadBytes message 5     ; load first 5 bytes of message ('Hello')

; load 12 bytes, all flipped horizontally and vertically
tilemap.loadBytes message 12 (tilemap.FLIPX|tilemap.FLIPY)
```
