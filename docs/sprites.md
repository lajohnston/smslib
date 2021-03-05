## Sprites (sprites.asm)

The VDP holds a sprite table in VRAM containing the tile patterns and x and y positions of up to 64 on-screen sprites. It's generally advisable to work with a copy of this table in normal RAM so you can edit it efficiently. You can then transfer it to VRAM in bulk when it's safe to do so without causing graphical corruption i.e when the display is off or during VBlank (see [interrupts](./interrupts.md))

`sprites.asm` manages an efficient sprite buffer in RAM and lets you output it to VRAM when required.

## Init

Reset the sprite buffer at the start of each game loop. This will set it back to the first slot so you can start adding sprites to the beginning of the table.

```
sprites.reset
```

## Adding Sprites

```
ld a, 100           ; a = yPos
ld b, 80            ; b = xPos
ld c, 5             ; c = pattern number
sprites.add
```

## Sprite Groups

Sprite groups allow you to conveniently add multiple sprites with positions relative to a shared anchor point. The offsets must be positive numbers. If any sub-sprites fall off screen they will not be added:

```
; Define a sprite group of 2x2 sprites
spriteGroup:
    sprites.startGroup
        ; pattern number, relX, relY
        sprites.sprite 1, 0, 0  ; top left
        sprites.sprite 2, 8, 0  ; top right (x + 8)
        sprites.sprite 3, 0, 8  ; bottom left (y + 8)
        sprites.sprite 4, 8, 8  ; bottom right (x + 8, y + 8)
    sprites.endGroup        ; end of group

; Add the group to the buffer
code:
    ld hl, spriteGroup  ; hl = pointer to our sprite group
    ld b, 150           ; b  = anchor x pos
    ld c, 50            ; c  = anchor y pos
    sprites.addGroup    ; add the sprites to the sprite table
```

## Batching

It is more efficient to add multiple sprites and/or sprite groups within a 'batch'. This allows smslib to avoid having to store and retrieve the next slot from RAM for each sprite, and instead can do it once at the beginning of the batch and once at the end.

During a batch the next sprite slot will be kept in `de` and incremented each time so be careful not to clobber this:

```
sprites.startBatch
... ; add multiple sprites or sprite groups
sprites.endBatch
```

## Transfer to VRAM

Transfer buffer to VRAM when safe to do so, either when the display is off or during VBlank:

```
sprites.copyToVram
```
