# Interrupts (interrupts.asm)

Handles VBlank and/or HBlank interrupts. When enabled, these will interrupt the current program flow when the VDP has finished drawing certain lines on the screen, allowing for screen effects such as changing the color palette for a portion of the screen. VBlank occurs when the last line has been drawn.

## Enabling interrupts in VDP

You will need to enable interrupts in both the VDP and Z80. After you initialise your game you can enable VBlanks and HBlanks in the VDP using registers 0 and 1, taking care not to overwrite any other flags that are also stored within these registers.

- Enable HBlank - VDP register 0, bit 4
- Enable VBlank - VDP register 1, bit 5

You can use [vdpSettings.asm](./vdpSettings.md) for this:

```asm
vdpSettings.enableVBlank    ; (already enabled by default)
vdpSettings.enableHBlank

## VBlanks (frame interrupts)

VBlanks occur each time the VDP has finished drawing the last/bottom line of a frame. They occur 50 times a second in PAL and 60 times a second in NTSC, providing a reliable means to time your game logic loop. The VBlank period is also a small window of opportunity to blast data to the VDP before it starts drawing the next frame, as sending data during 'active display' can result in missed writes and graphical corruption. The only other safe times to write to the VDP is when the display is off or by spacing each byte written with a 26-cycle.

The VBlank detection will need to be enabled in the VDP using register 1, bit 5. This is enabled by default by `vdpSettings.asm`.

Usually you would then use `ei` to enable interrupts on the Z80, causing it to jump to the interrupt handler at address `$0038` when a VBlank occurs. However, you won't need to use `ei` for VBlanks as `interrupts.asm` instead provides an `interrupts.waitForVBlank` mechanism that polls the VDP status flag to check for the VBlank flag.

```asm
gameLoop:
    ; Update game logic
    ...

    ; Wait for the next VBlank
    interrupts.waitForVBlank

    ; We're now in VBlank and it's safe to write to the VDP
    ...

    ; Run loop again
    jp gameLoop
```

The value returned in A will the be the VDP status flags:
Bit 7 - VBlank flag (will be set)
Bit 6 - Sprite overflow flag, set if more than 8 sprites were on one scanline
Bit 5 - Sprite collision flag, set if visible pixels from 2+ sprites overlapped

## HBlanks (line interrupts)

HBlanks occur when the line counter in the VDP falls below zero. This counter is set to the value stored in VDP Register 10 before the frame is drawn and each time a line is drawn (from top to bottom) it is decremented. Further documentation on this can be found in Richard Talbot-Watkins documentation on [VDP Register 10](https://www.smspower.org/uploads/Development/richard.txt).

Enable the HBlank handler by defining `interrupts.INTERRUPT_HBLANKS` setting before including `interrupts.asm`:

```asm
.define interrupts.INTERRUPT_HBLANKS
.include "interrupts.asm"
```

You will also need to define an `interrupts.onHBlank` label that the handler will jump to when an HBlank occurs. This handler must end with a macro call to `interrupts.endHBlank`:

```asm
interrupts.onHBlank:
    ...
    interrupts.endHBlank    ; return from HBlank
```

The HBlank won't trigger unless you've enabled them with `ei` and set a line interval. This takes a zero-based value:

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

Please note that if you change the interval during active screen time, the new interval won't take effect until the next HBlank has occurred. This means that each interval you specify will trigger at least 2 times. If you only intend it to trigger once you'll need to keep track of the state in RAM so you can ignore the second time.

You can read the current line being drawn. The value will be loaded into `a`. However, the value returned isn't a simple 0-192 number and requires some processing. Read Charles MacDonald's [VDP documentation](https://www.smspower.org/uploads/Development/msvdp-20021112.txt) for more information.

```asm
interrupts.getLine
```
