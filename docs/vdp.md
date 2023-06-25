# Visual Display Processor (vdp.asm)

Handles the general VDP (graphics chip) registers and settings. More specific aspects controlled by the VDP have been separated into their own modules, such as `sprites.asm`, `palette.asm`, `patterns.asm` and `tilemap.asm`.

Change register values using the provided macros. See vdp.asm for more details about each setting.

```asm
vdp.setBorderColorIndex 16

vdp.enableDisplay
vdp.disableDisplay

vdp.enableVBlank
vdp.disableVBlank

vdp.enableTallSprites
vdp.disableTallSprites

vdp.enableSpriteZoom
vdp.disableSpriteZoom

vdp.enableHBlank
vdp.disableHBlank

vdp.enableSpriteShift
vdp.disableSpriteShift

vdp.showLeftColumn
vdp.hideLeftColumn

; If parameter omitted, the value in register A is used
vdp.setScrollX 100
vdp.setScrollY 255

vdp.lockHScroll
vdp.unlockHScroll

vdp.lockVScroll
vdp.unlockVScroll

vdp.setLineInterrupt 5
```

## Batches

Many of the VDP's settings are stored within the same VDP registers, so if you are changing multiple settings then it's much more efficient to batch them together by wrapping them in calls to `vdp.startBatch` and `vdp.endBatch`. `vdp.asm` knows which ones belong within the same register and so only updates that register once.

```asm
vdp.startBatch
    vdp.enableDisplay
    vdp.enableVBlank
vdp.endBatch
```
