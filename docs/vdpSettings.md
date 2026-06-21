# Visual Display Processor Settings (vdpSettings.asm)

Handles the general VDP (graphics chip) registers and settings.

Change register values using the provided macros. See vdpSettings.asm for more details about each setting.

```asm
vdpSettings.setBorderColorIndex 16

vdpSettings.enableDisplay
vdpSettings.disableDisplay      ; default

; Sets VDP status flag when last line is drawn
vdpSettings.enableVBlank        ; default
vdpSettings.disableVBlank

; Makes all sprites 8x16 instead of 8x8
vdpSettings.enableTallSprites
vdpSettings.disableTallSprites  ; default

; Zooms sprites by 2x, making them 16x16 or 16x32. Buggy on SMS1
vdpSettings.enableSpriteZoom
vdpSettings.disableSpriteZoom   ; default

; Trigger an interrupt when certain lines are drawn
vdpSettings.enableHBlank
vdpSettings.disableHBlank       ; default

vdpSettings.setLineInterrupt 5

vdpSettings.enableSpriteShift
vdpSettings.disableSpriteShift  ; default

vdpSettings.showLeftColumn      ; default
vdpSettings.hideLeftColumn

; If parameter omitted, the value in register A is used
vdpSettings.setScrollX 100
vdpSettings.setScrollY 255

; Don't scroll top 2 rows
vdpSettings.lockHScroll
vdpSettings.unlockHScroll       ; default

; Don't vertical scroll right-most 8 columns (these can still scroll horizontally though)
vdpSettings.lockVScroll
vdpSettings.unlockVScroll       ; default
```

## Batches

Many of the VDP's settings are stored within the same VDP registers, so if you are changing multiple settings then it's much more efficient to batch them together by wrapping them in calls to `vdpSettings.startBatch` and `vdpSettings.endBatch`. `vdpSettings.asm` knows which ones belong within the same register and so only updates that register once.

```asm
vdpSettings.startBatch
    vdpSettings.enableDisplay
    vdpSettings.hideLeftColumn
vdpSettings.endBatch
```
