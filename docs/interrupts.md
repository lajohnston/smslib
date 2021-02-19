# Interrupts (interrupts.asm)

Handles VBlank and/or HBlank interrupts. When enabled, these interrupts allow the VDP to send a signal to the Z80 processor when it has finished drawing certain lines on the screen (HBlanks) and each time it's finished drawing the whole screen/frame (VBlanks). You can use these to time your game logic or add screen effects, such as changing the color palette for a portion of the screen.

## Enabling interrupts

You will need to enable interrupts in both the VDP and Z80. After you initialise your game you can enable VBlanks and HBlanks in the VDP using registers 0 and 1:

- Enable HBlank - VDP register 0, bit 4
- Enable VBlank - VDP register 1, bit 5

You can use [vdpreg.asm](./vdpreg) for this, taking care not to overwrite any other flags that are also stored within these registers (see vdpreg.asm file for documentation):

```
vdpreg.enableHBlank
vdpreg.enableVBlank
```

You also need to enable interrupts within the Z80 CPU:

```
interrupts.enable
```

## VBlanks (frame interrupts)

VBlanks occur each time the VDP has finished drawing a frame (50 times a second in PAL, 60 times a second in NTSC). It's a small window of opportunity to blast data to the VDP before it starts drawing the next frame. Sending data to the VDP outside this window can result in missed writes and graphical corruption. The only other safe time to write to the VDP is when the display is off.

Enable the VBlank handler by defining `interrupts.handleVBlanks` setting before including `interrupts.asm`:

```
.define interrupts.handleVBlanks 1
.include "interrupts.asm"
```

You will also need to define an `interrupts.onVBlank` label that the handler will jump to when a VBlank occurs. This handler must end with a macro call to `interrupts.endVBlank`:

```
interrupts.onVBlank:
    ...                     ; send data to VDP
    interrupts.endVBlank    ; return from VBlank
```

VBlanks can also be used to regulate the speed of your game logic. Place `interrupts.waitForVBlank` in your game loop to ensure the logic doesn't update too quickly.

```
gameLoop:
    interrupts.waitForVBlank
    ... update logic
    jp gameLoop         ; run loop again
```

## HBlanks (line interrupts)

HBlanks occur when the line counter in the VDP falls below zero. This counter is set to the value stored in VDP Register 10 before the frame is drawn and each time a line is drawn (from top to bottom) it is decremented. Further documentation on this can be found in Richard Talbot-Watkins documentation on [VDP Register 10](https://www.smspower.org/uploads/Development/richard.txt).

Enable the HBlank handler by defining `interrupts.handleHBlanks` setting before including `interrupts.asm`:

```
; Note: you can also enable interrupts.handleVBlanks alongside this if you wish
.define interrupts.handleHBlanks 1
.include "interrupts.asm"
```

You will also need to define an `interrupts.onHBlank` label that the handler will jump to when an HBlank occurs. This handler must end with a macro call to `interrupts.endHBlank`:

```
interrupts.onHBlank:
    ...
    interrupts.endHBlank    ; return from HBlank
```

The HBlank won't trigger unless the line interval has been set. This takes a zero-based value:

```
interrupts.setLineInterval 1    ; trigger HBlank every line (lines 0, 1, 2...)
interrupts.setLineInterval 10   ; trigger every 10th line (lines 9, 19, 29...)
```

This can also be set dynamically from `a` by omitting the argument. When using this method the value in `a` must be 0-based:

```
; Trigger every 20th line
ld a, 19
interrupts.setLineInterval
```

Please note that if you change the interval during active screen time, the new interval won't take effect until the next HBlank has occurred. This means that each interval you specify will trigger a minimum of 2 times, i.e. an interval every 10 lines will trigger for lines 9 (0-based) and line 19 even if you change it after line 9.

You can read the current line being drawn. The value will be loaded into `a`

```
interrupts.getLine
```
