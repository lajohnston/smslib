# Tilemap (tilemap.asm)

Manages the tilemap, which places patterns/tiles in a grid to create the background image.

## Define tile data

Each tile in the map is 2 bytes. The first is a pattern index reference (see [patterns](./patterns.md)) and the second contains various attributes. The following attributes can be ORed together to create a byte containing all the attributes (i.e. tilemap.FLIP_X | tilemap.PRIORITY).

```asm
tilemap.HIGH_BIT        ; 9th bit for the pattern ref, allows pattern refs 256+
tilemap.FLIP_X          ; Flip horizontally
tilemap.FLIP_Y          ; Flip vertically
tilemap.FLIP_XY         ; Flip horizontally and vertically
tilemap.SPRITE_PALETTE  ; Use the sprite palette for the tile

; Render tile in front of sprites, apart from color 0/transparent which is drawn behind
tilemap.PRIORITY

; Spare bits - unused by the VDP but some games use them to hold custom attributes
; such as whether the tile is a hazard tile that costs the player health
tilemap.CUSTOM_1
tilemap.CUSTOM_2
tilemap.CUSTOM_3
```

### tilemap.tile

Define an individual tile in ROM, ready to be drawn later.

```asm
tilemap.tile 0                  ; pattern 0
tilemap.tile 0 tilemap.FLIP_X   ; pattern 0, flipped horizontally
tilemap.tile 500                ; pattern 500 (tilemap.HIGH_BIT set automatically)
```

## Output ASCII data

```asm
.asciitable
    map " " to "~" = 0
.enda

message:
    .asc "Hello, world"
    .db $ff ; terminator byte

tilemap.setColRow 0, 0              ; top left tile
tilemap.writeBytesUntil $ff message ; write from 'message' label until $ff reached
```

## Write bytes

Write bytes of data representing pattern refs. Each tile will contain the same [tile attributes](#tile-attributes). These attributes can be passed in as an optional 3rd parameter.

```asm
message:
    .asc "Hello, world"

tilemap.setColRow 5, 10         ; column 5, row 10
tilemap.writeBytes message 5    ; write first 5 bytes of message ('Hello')

; Write 12 bytes, all flipped horizontally and vertically
tilemap.writeBytes message 12, (tilemap.FLIP_X | tilemap.FLIP_Y)
```

## Write tiles

### tilemap.writeTile

Write a tile to the current position in the tilemap.

```asm
; Pattern 0 with default attributes
tilemap.writeTile 0

; Pattern 20 flipped horizontally and using the sprite palette
tilemap.writeTile 20, (tilemap.FLIP_X | tilemap.SPRITE_PALETTE)

; Pattern 500 flipped vertically (tilemap.HIGH_BIT attribute set automatically)
tilemap.writeTile 500, tilemap.FLIP_Y
```

### tilemap.writeRow

Write 32 uncompressed tiles.

```asm
myRow:
    .repeat 32
        tilemap.tile 5
    .endr

tilemap.setColRow 0, 0  ; write from column 0, row 0 onwards
ld hl, myRow            ; point to data
tilemap.writeRow        ; write data (32 tiles)
```

### tilemap.writeRows

Write multiple rows from an uncompressed tilemap. The visible tilemap is 32 tiles wide (columns) by 25 tiles high (rows) but the full map can be larger than the screen.

```asm
.define MAP_ROWS 64
.define MAP_COLS 64

myTilemap:
    .repeat MAP_ROWS
        .repeat MAP_COLS
            tilemap.tile 0
        .endr
    .endr

tilemap.setColRow 0, 0          ; write from column 0, row 0 onwards
ld hl, myTilemap                ; point to top left corner to write
ld d, tilemap.MAX_VISIBLE_ROWS  ; number of rows to write; all visible rows (25)
ld e, tilemap.MAP_COLS * 2      ; number of full map columns * 2 (each tile is 2 bytes)

tilemap.writeRows               ; write row data
```

## Scrolling

The tilemap supports 8-direction scrolling. This is a simple but low-level API that handles the fine pixel scroll registers, row/column scroll detection and VRAM write addresses. You will need a scroll handler on top of this which will maintain the position in the world and adjust it based on the scroll direction. It will also need to handle your tile format, whether raw tile data or 'metatiles' that group multiple tiles together to save memory.

Optional scroll handlers are included in the [scroll](./scroll) directory but you may also build your own if needed.

A suggested workflow is to maintain a pointer to the top-left visible tile of your tilemap and adjust it based on the scroll direction. You can then draw the next column or row based on this position. The steps each frame would be the following (described in further detail below):

1. Adjust the tilemap by x and y number of pixels
2. If row or column scrolling detected, adjust row/col of the top-left pointer
   - (Optional) Prevent the pointer going out of bounds
3. Write the new row and/or column into the RAM buffers
   - Right edge will be top-left pointer + 31 columns
   - Bottom edge will be top-left pointer + 24 rows
4. During VBlank, transfer these changes from the RAM buffer to the VDP

### Adjust position

Adjust the x and y axis by a maximum of 8 pixels each per frame (-8 to +8 inclusive). This limit is not enforced so ensure you stay within it.

```asm
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

```asm
tilemap.ifColScroll +
    ; A new column has scrolled onto screen
+:
```

You can pass three arguments to this to act like a switch statement for each direction.

```asm
tilemap.ifColScroll left, right, +
    left:
        ; Scrolling left
        jp +    ; (skip right label)
    right:
        ; Scrolling right
+:  ; will jump here if no column needs scrolling
```

A variation of this is `tilemap.ifColScrollElseRet`. This will execute a return instruction if no column scroll is required, otherwise it will jump/continue to the given left/right labels.

```asm
tilemap.ifColScrollElseRet left, right
    left:
        ; Scrolling left
    right:
        ; Scrolling right
```

### tilemap.ifRowScroll

You can detect if a new row needs processing using `tilemap.ifRowScroll`.

```asm
tilemap.ifRowScroll +
    ; A new row has scrolled onto screen
+:
```

You can pass three arguments to this to act like a switch statement for each direction.

```asm
tilemap.ifRowScroll up, down, +
    up:
        ; Scrolling up
        jp +    ; (skip down label)
    down:
        ; Scrolling down
+:  ; will jump here if no row needs scrolling
```

A variation of this is `tilemap.ifRowScrollElseRet`. This will execute a return instruction if no row scroll is required, otherwise it will jump/continue to the given up/down labels.

```asm
tilemap.ifRowScrollElseRet up, down
    up:
        ; Scrolling up
    down:
        ; Scrolling down
```

### Add data to the column buffer

If a column scroll is detected you can transfer the new column data to the column buffer in RAM.

```asm
tilemap.loadDEColBuffer ; point DE to the column buffer

tilemap.loadBColBytes   ; load B with the number of bytes to write to the buffer
tilemap.loadBCColBytes  ; or, load BC with the value (for use with ldi/ldir)
```

You will need a routine to write sequential tile data for a column from top to bottom. The routine should write a tile, jump to the next row, then write another tile, until the byte counter is 0.

### Add data to the row buffer

If a row scroll is detected you can transfer the new row data to the row buffer in RAM.

```asm
tilemap.loadDERowBuffer ; point DE to the row buffer

tilemap.loadBRowBytes   ; load B with the number of bytes to write to the buffer
tilemap.loadBCRowBytes  ; or, load BC with the value (for use with ldi)
```

You will need a routine that writes the row data to the buffer from left to right. If copying uncompressed data you would just need to point HL to the left-most visible column and use `ldir` to copy the bytes until BC is 0.

### Updating VRAM

During VBlank you can safely write the buffered data to VRAM. The easiest way to do this is to call `tilemap.writeScrollBuffers`. This will write the scroll registers, the column buffer and/or the row buffer when necessary.

```asm
tilemap.writeScrollBuffers
```

### Bounds checking

If you detect a row or column scroll will take the tilemap out of bounds, you can call the following scroll-stop routines to stop the column and/or row scroll from happening. This will set the pixel scroll to the farthest edge of the in-bounds tiles, but later calls to `tilemap.ifRowScroll` and/or `tilemap.ifColScroll` will no longer detect a scroll and thus not trigger out-of-bounds rows or columns to be drawn.

Note: these should be called before calling `tilemap.calculateScroll` so it takes the cancelling into account.

```asm
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

```asm
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
