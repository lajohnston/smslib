# Interrupts (interrupts.asm)

Handles VBlank and/or HBlank interrupts. When enabled, these will interrupt the current program flow when the VDP has finished drawing certain lines on the screen, allowing for screen effects such as changing the color palette for a portion of the screen. VBlank occurs when the last line has been drawn.

## Enabling interrupts in VDP

You will need to enable interrupts in both the VDP and Z80. After you initialise your game you can enable VBlanks and HBlanks in the VDP using registers 0 and 1, taking care not to overwrite any other flags that are also stored within these registers.

- Enable HBlank - VDP register 0, bit 4
- Enable VBlank - VDP register 1, bit 5

You can use [vdp.asm](./vdp.md) for this:

```asm
vdp.enableVBlank    ; (already enabled by default)
vdp.enableHBlank
```

## Enabling interrupts in the Z80

After your initialisation code you can use the following to enable interrupts on the Z80 from the next interrupt onwards. If the VDP flagged one prior to this (such as during your initialisation code) it will be ignored, unlike `ei` by itself which would trigger a 'late' interrupt straightaway.

```asm
interrupts.enable
```

## VBlanks (frame interrupts)

VBlanks occur each time the VDP has finished drawing a frame. They occur 50 times a second in PAL and 60 times a second in NTSC, providing a reliable means to time your game logic loop. The VBlank period is also a small window of opportunity to blast data to the VDP before it starts drawing the next frame, as sending data during 'active display' can result in missed writes and graphical corruption. The only other safe times to write to the VDP is when the display is off or by spacing each byte written with a 26-cycle.

Enable the VBlank handler by defining `interrupts.HANDLE_VBLANK` setting before including `interrupts.asm`:

```asm
.define interrupts.HANDLE_VBLANK 1
.include "interrupts.asm"
```

You will also need to define an `interrupts.onVBlank` label that the handler will jump to when a VBlank occurs. This handler must end with a macro call to `interrupts.endVBlank`:

```asm
interrupts.onVBlank:
    ...                     ; write data to VRAM
    interrupts.endVBlank    ; return from VBlank
```

### interrupts.waitForVBlank

Waits for the `interrupts.onVBlank` handler to return before continuing the code flow. This is useful for timing your game loop.

```asm
gameLoop:
    interrupts.waitForVBlank
    ; resume after the onVBlank handler has returned
    ; update logic
    jp gameLoop         ; run loop again
```

## HBlanks (line interrupts)

HBlanks occur when the line counter in the VDP falls below zero. This counter is set to the value stored in VDP Register 10 before the frame is drawn and each time a line is drawn (from top to bottom) it is decremented. Further documentation on this can be found in Richard Talbot-Watkins documentation on [VDP Register 10](https://www.smspower.org/uploads/Development/richard.txt).

Enable the HBlank handler by defining `interrupts.HANDLE_HBLANK` setting before including `interrupts.asm`:

```asm
; Note: you can also enable interrupts.HANDLE_VBLANK alongside this if you wish
.define interrupts.HANDLE_HBLANK 1
.include "interrupts.asm"
```

You will also need to define an `interrupts.onHBlank` label that the handler will jump to when an HBlank occurs. This handler must end with a macro call to `interrupts.endHBlank`:

```asm
interrupts.onHBlank:
    ...
    interrupts.endHBlank    ; return from HBlank
```

The HBlank won't trigger unless the line interval has been set. This takes a zero-based value:

```asm
interrupts.setLineInterval 1    ; trigger HBlank every line (lines 0, 1, 2...)
interrupts.setLineInterval 10   ; trigger every 10th line (lines 9, 19, 29...)
```

This can also be set dynamically from `a` by omitting the argument. When using this method the value in `a` must be 0-based:

```asm
; Trigger every 20th line
ld a, 19
interrupts.setLineInterval
```

Please note that if you change the interval during active screen time, the new interval won't take effect until the next HBlank has occurred. This means that each interval you specify will trigger a minimum of 2 times, i.e. an interval every 10 lines will trigger for lines 9 (0-based) and line 19 even if you change it after line 9.

You can read the current line being drawn. The value will be loaded into `a`. However, the value returned isn't a simple 0-192 number and requires some processing. Read Charles MacDonald's [VDP documentation](https://www.smspower.org/uploads/Development/msvdp-20021112.txt) for more information.

```asm
interrupts.getLine
```
