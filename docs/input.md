# Input (input.asm)

Interprets input from the controller pads.

## Read input

Use `input.readPort1` or `input.readPort2` to capture the input from joypad 1 and joypad 2 respectively. The comparison functions will work based on the last of these to have been called.

Note: Each of these should only be called once per frame.

### input.if

Allows an if-like syntax for detecting when certain buttons have been pressed. If the given button has been pressed, the code inside the 'block' will run, otherwise it will be skipped.

```
input.readPort1 ; you can also use input.readPort2

input.if input.LEFT, +
    ; Left has been pressed
+:

input.if input.BUTTON_1, +
    ; Button 1 has been pressed
+:
```

The following buttons can be checked:

```
input.UP
input.DOWN
input.LEFT
input.RIGHT
input.BUTTON_1
input.BUTTON_2
```

## input.ifPressed

Detects if a button was pressed this frame.

```
input.ifPressed, input.BUTTON_1, +
    ; BUTTON_1 was just pressed this frame
+:
```

## input.ifXDirPressed / input.ifYDirPressed

Detects if a direction on the given axis has just been pressed this frame, i.e. the button was released last frame but is now pressed. Jumps to the relevant label if it has.

```
input.ifXDirPressed, left, right, +
    left:
        ; Left has just been pressed
        jp +    ; (remember to skip over right label)
    right:
        ; Right has just been pressed
+:

input.ifYDirPressed, up, down, +
    up:
        ; Up has just been pressed
        jp +    ; (remember to skip over down label)
    down:
        ; Down has just been pressed
+:
```

### input.loadADirX

Loads register A with the directional x-axis: -1 = left, 1 = right, none = 0. An optional multiplier multiplies this result at assemble time.

```
input.readPort1

input.loadADirX     ; left = -1, right =  1, none = 0
input.loadADirX 5   ; left = -5, right =  5, none = 0

; Reverse with a negative multiplier
input.loadADirX -1  ; left =  1, right = -1, none = 0
```

### input.loadADirY

Loads register A with the directional y-axis: -1 = up, 1 = down, none = 0. An optional multiplier multiplies this result at assemble time.

```
input.readPort1

input.loadADirX     ; up = -1, down = 1, none = 0
input.loadADirX 4   ; up = -4, down = 4, none = 0

; Reverse with a negative multiplier
input.loadADirX -1  ; up =  1, down = -1, none = 0
```