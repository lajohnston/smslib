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
