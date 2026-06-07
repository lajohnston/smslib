# Visual Display Processor (vdp.asm)

Handles the general VDP (graphics chip) registers and settings. More specific aspects controlled by the VDP have been separated into their own modules, such as `sprites.asm`, `palette.asm`, `patterns.asm` and `tilemap.asm`.

Change register values using the provided macros. See vdp.asm for more details about each setting.

```asm
vdp.setBorderColorIndex 16

vdp.enableDisplay
vdp.disableDisplay      ; default

; Sets VDP status flag when last line is drawn
vdp.enableVBlank        ; default
vdp.disableVBlank

; Makes all sprites 8x16 instead of 8x8
vdp.enableTallSprites
vdp.disableTallSprites  ; default

; Zooms sprites by 2x, making them 16x16 or 16x32. Buggy on SMS1
vdp.enableSpriteZoom
vdp.disableSpriteZoom   ; default

; Trigger an interrupt when certain lines are drawn
vdp.enableHBlank
vdp.disableHBlank       ; default

vdp.setLineInterrupt 5

vdp.enableSpriteShift
vdp.disableSpriteShift  ; default

vdp.showLeftColumn      ; default
vdp.hideLeftColumn

; If parameter omitted, the value in register A is used
vdp.setScrollX 100
vdp.setScrollY 255

; Don't scroll top 2 rows
vdp.lockHScroll
vdp.unlockHScroll       ; default

; Don't vertical scroll right-most 8 columns (these can still scroll horizontally though)
vdp.lockVScroll
vdp.unlockVScroll       ; default
```

## Batches

Many of the VDP's settings are stored within the same VDP registers, so if you are changing multiple settings then it's much more efficient to batch them together by wrapping them in calls to `vdp.startBatch` and `vdp.endBatch`. `vdp.asm` knows which ones belong within the same register and so only updates that register once.

```asm
vdp.startBatch
    vdp.enableDisplay
    vdp.hideLeftColumn
vdp.endBatch
```
