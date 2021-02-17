# VDP Registers (vdpreg.asm)

Handles the VDP registers and settings.

Change register values using the provided macros. See vdpreg.asm for more details about each setting.

```
vdpreg.setBackgroundColorSlot 16
vdpreg.setScrollX 100
vdpreg.setScrollY 255

vdpreg.enableDisplay
vdpreg.disableDisplay

vdpreg.enableVBlank
vdpreg.disableVBlank

vdpreg.enableTallSprites
vdpreg.disableTallSprites

vdpreg.enableSpriteZoom
vdpreg.disableSpriteZoom

vdpreg.enableHBlank
vdpreg.disableHBlank

vdpreg.enableSpriteShift
vdpreg.disableSpriteShift

vdpreg.hideLeftColumn
vdpreg.showLeftColumn

vdpreg.lockHScroll
vdpreg.unlockHScroll

vdpreg.lockVScroll
vdpreg.unlockVScroll
```

## Batches

Many of the VDP's settings are stored within the same VDP registers, so if you are changing multiple settings then it's much more efficient to batch them together by wrapping them in calls to `vdpreg.startBatch` and `vdpreg.endBatch`:

```
vdpreg.startBatch
vdpreg.enableDisplay
vdpreg.enableVBlank
vdpreg.endBatch
```
