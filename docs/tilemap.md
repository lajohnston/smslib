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

### tilemap.loadRow

Load 32 uncompressed tiles.

```
myRow:
    .repeat 32
        tilemap.tile 5
    .endr

tilemap.setColRow 0, 0  ; write from column 0, row 0 onwards
ld hl, myRow            ; point to data
tilemap.loadRow         ; load data (32 tiles)
```

### tilemap.loadRows

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
ld d, tilemap.VISIBLE_ROWS  ; number of rows to load; all visible rows (25)
ld e, tilemap.MAP_COLS * 2  ; number of full map columns * 2 (each tile is 2 bytes)

tilemap.loadRows            ; load row data

```

## Scrolling

The tilemap supports 8-direction scrolling. This is a simple but low-level API that handles the fine pixel scroll registers, row/column scroll detection and VRAM write addresses. You will need a scroll handler on top of this which will maintain the position in the world and adjust it based on the scroll direction. It will also need to handle your tile format, whether raw tile data or 'metatiles' that group multiple tiles together to save memory.

A suggested workflow is to maintain a pointer to the top-left visible tile of your tilemap and adjust it based on the scroll direction. You can then draw the next column or row based on this position. The steps each frame would be the following (described in further detail below):

1. Adjust the tilemap by x and y number of pixels
2. If row or column scrolling detected, adjust row/col of the top-left pointer
    - (Optional) Prevent the pointer going out of bounds
4. Load the new row and/or column into the RAM buffers
    - Right edge will be top-left pointer + 31 columns
    - Bottom edge will be top-left pointer + 24 rows
5. During VBlank, transfer these changes from the RAM buffer to the VDP

### Adjust position

Adjust the x and y axis by a maximum of 8 pixels each per frame (-8 to +8 inclusive). This limit is not enforced so ensure you stay within it.

```
; Initialise (beginning of level)
tilemap.reset           ; initialise RAM and scroll registers

; Adjust x-axis. Negative values scroll left, positive scroll right
ld a, 1                 ; amount of pixels to scroll the x-axis (1 pixel right)
tilemap.adjustXPixels

; Adjust y-axis. Negative values scroll up, positive scroll down
ld a, -1                ; amount to pixels to scroll the y-axis (1 pixel up)
tilemap.adjustYPixels

tilemap.calculateScroll ; calculate these changes
```

### tilemap.ifColScroll

You can detect if a new column needs processing using `tilemap.ifColScroll`.

```
tilemap.ifColScroll +
    ; A new column has scrolled onto screen
+:
```

You can pass three arguments to this to act like a switch statement for each direction.

```
tilemap.ifColScroll left, right, +
    left:
        ; Scrolling left
        jp +    ; (skip right label)
    right:
        ; Scrolling right
+:  ; will jump here if no column needs scrolling
```

A variation of this is `tilemap.ifColScrollElseRet`. This will execute a return instruction if no column scroll is required, otherwise it will jump/continue to the given left/right labels.

```
tilemap.ifColScrollElseRet left, right
    left:
        ; Scrolling left
    right:
        ; Scrolling right
```

### tilemap.ifRowScroll

You can detect if a new row needs processing using `tilemap.ifRowScroll`.

```
tilemap.ifRowScroll +
    ; A new row has scrolled onto screen
+:
```

You can pass three arguments to this to act like a switch statement for each direction.

```
tilemap.ifRowScroll up, down, +
    up:
        ; Scrolling up
        jp +    ; (skip down label)
    down:
        ; Scrolling down
+:  ; will jump here if no row needs scrolling
```

A variation of this is `tilemap.ifRowScrollElseRet`. This will execute a return instruction if no row scroll is required, otherwise it will jump/continue to the given up/down labels.

```
tilemap.ifRowScrollElseRet up, down
    up:
        ; Scrolling up
    down:
        ; Scrolling down
```

### Add data to the column buffer

If a column scroll is detected you can transfer the new column data to the column buffer in RAM.

```
tilemap.loadDEColBuffer ; point DE to the column buffer

tilemap.loadBColBytes   ; load B with the number of bytes to write to the buffer
tilemap.loadBCColBytes  ; or, load BC with the value (for use with ldi)
```

You will need a routine to write sequential tile data for a column from top to bottom. The routine should write a tile, jump to the next row, then write another tile, until the byte counter is 0.

### Add new data to the row buffer

The row buffer is split by `tilemap.asm` into `rowBufferA` and `rowBufferB`, to handle scroll wrapping. Start by writing data to `rowBufferA` then write the remainder (if any) to `rowBufferB`. Start with the tile on the left edge of the screen and work to the right.

```
; Example routine
ld hl, pointerToARow

; Set DE to rowBufferA and set A to number of bytes to write
tilemap.setRowBufferA

ld b, 0
ld c, a ; transfer byte count to BC
ldir    ; copy data until BC == 0
```

Once `rowBufferA` is full, write the remaining tiles (if any) to `rowBufferB`. Unlike `rowBufferA`, `rowBufferB` can sometimes have a size of 0, so ensure you check this.

```
; Set DE to rowBufferB and set A to number of bytes to write
tilemap.setRowBufferB

jp z, +     ; jp if there are no bytes to write
    ld b, 0
    ld c, a ; transfer A to BC
    ldir    ; copy data until BC == 0
+:
```

### Updating VRAM

During VBlank you can safely write the buffered data to VRAM. The easiest way to do this is to call `tilemap.writeScrollBuffers`. This will write the scroll registers, the column buffer and/or the row buffer when necessary.

```
tilemap.writeScrollBuffers
```

Alternatively you can perform these separately:

```
tilemap.writeScrollRegisters

tilemap.ifRowScroll +
    tilemap.writeScrollRow
+:

tilemap.ifColScroll +
    tilemap.writeScrollCol
+
```

### Bounds checking

If you detect a row or column scroll will take the tilemap out of bounds, you can call the following scroll stop routines to stop the column and/or row scroll from happening. This will set the pixel scroll to the farthest edge of the in-bounds tiles, but later calls to `tilemap.ifRowScroll` and/or `tilemap.ifColScroll` will no longer detect a scroll and thus not trigger out-of-bounds rows or columns to be drawn.

Note: these should be called before calling `tilemap.calculateScroll` so it takes the cancelling into account.

```
tilemap.ifRowScroll _up, _down, +
    _up:
        ; ...logic that checks bounds
        tilemap.stopUpRowScroll
        jp +
    _down:
        ; ...logic that checks bounds
        tilemap.stopDownRowScroll
+:
```

```
tilemap.ifColScroll, _left, _right, +
    _left:
        ; ...logic that checks bounds
        tilemap.stopLeftColScroll
        jp +
    _right:
        ; ...logic that checks bounds
        tilemap.stopRightColScroll
+:
```
