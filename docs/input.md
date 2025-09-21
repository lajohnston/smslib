# Input (input.asm)

Interprets input from the controller pads.

## Read input

Use `input.readPort1` or `input.readPort2` to capture the input from joypad 1 and joypad 2 respectively. The comparison functions will work based on the last of these to have been called. Each of these should only be called once per frame, otherwise they will overwrite the previous input state and break the `pressed` and `held` detection.

In order to use `input.readPort2` you will need to enable the `input.ENABLE_PORT_2` setting.

```asm
.define input.ENABLE_PORT_2
; ... .include smslib or this module
```


### input.if

Allows an if-like syntax for detecting when certain buttons have been pressed. If the given button has been pressed, the code inside the 'block' will run, otherwise it will be skipped.

```asm
input.readPort1 ; you can also use input.readPort2

input.if input.LEFT, +
    ; Left has been pressed
+:

input.if input.BUTTON_1, +
    ; Button 1 has been pressed
+:
```

The following buttons can be checked:

```asm
input.UP
input.DOWN
input.LEFT
input.RIGHT
input.BUTTON_1
input.BUTTON_2
```

You can also pass multiple buttons to check if all are currently pressed.

```asm
input.if input.BUTTON_1, input.BUTTON_2, +
    ; Both button 1 and button 2 are pressed
+:

input.if input.UP, input.BUTTON_1, input.BUTTON_2, +
    ; Up, button 1 and button 2 are all pressed
+:
```

## input.ifHeld

Detects if a button has been pressed for both this frame and the previous frame.

```asm
input.ifHeld, input.BUTTON_1, +
    ; BUTTON_1 has been pressed for both frames
+:
```

You can also pass multiple buttons to check if all have been held since the previous frame.

```asm
input.ifHeld input.BUTTON_1, input.BUTTON_2, +
    ; Both button 1 and button 2 are held
+:

input.ifHeld input.UP, input.BUTTON_1, input.BUTTON_2, +
    ; Up, button 1 and button 2 are all held
+:
```

## input.ifPressed

Detects if a button was pressed this frame. This will only occur once every time the button is pressed.

```asm
input.ifPressed, input.BUTTON_1, +
    ; BUTTON_1 was just pressed this frame
+:
```

You can provide multiple buttons to detect when all are pressed. This will occur on the first frame in which all buttons are pressed, then not again until any of the buttons are released and pressed again. Note: the buttons don't all have to be pressed on the exact same frame.

```asm
input.ifPressed, input.BUTTON_1, input.BUTTON_2, +
    ; Both buttons have been pressed
+:

input.ifPressed, input.UP, input.BUTTON_1, input.BUTTON_2, +
    ; UP and both buttons have been pressed
+:
```

## input.ifReleased

Detects if a button was pressed last frame but is now released. This will only occur once every time the button is released.

```asm
input.ifReleased, input.BUTTON_1, +
    ; BUTTON_1 was pressed but was just released this frame
+:
```

You can provide multiple buttons to detect when multiple buttons were pressed down last time, but now not all of them are. This will occur for one frame.

```asm
input.ifReleased, input.BUTTON_1, input.BUTTON_2, +
    ; Both buttons were pressed last frame, but now one or both aren't
+:

input.ifPressed, input.UP, input.BUTTON_1, input.BUTTON_2, +
    ; UP and both buttons were pressed last frame, but now one or more are released
+:
```

## input.ifXDir / input.ifYDir

These detect if a direction on the given axis is currently pressed and jumps to the relevant label if it has.

This is more efficient that checking each button on the axis individually as the input only needs to be read from the buffer once, and if one is confirmed to be pressed the other check can be skipped.

```asm
input.ifXDir left, right, +
    left:
        ; Left is currently pressed
        jp +    ; skip right label
    right:
        ; Right is currently pressed
+:

input.ifYDir up, down, +
    up:
        ; Up is currently pressed
        jp +    ; skip down label
    down:
        ; Down is currently pressed
+:
```

## input.ifXDirHeld / input.ifXDirHeld

These detect if a direction on the given axis was pressed in the last frame and is still pressed in this frame.

This is more efficient that checking each button on the axis individually as the input only needs to be read from the buffer once, and if one is confirmed to be pressed the other check can be skipped.

```asm
input.ifXDirHeld left, right, +
    left:
        ; Left is currently held
        jp +    ; skip right label
    right:
        ; Right is currently held
+:

input.ifXDirHeld up, down, +
    up:
        ; Up is currently held
        jp +    ; skip down label
    down:
        ; Down is currently held
+:
```

## input.ifXDirPressed / input.ifYDirPressed

These detect if a direction on the given axis has just been pressed this frame, i.e. the button was released last frame but is now pressed. Jumps to the relevant label if it has.

This is more efficient that checking each button on the axis individually as the input only needs to be read from the buffer once, and if one is confirmed to be pressed the other check can be skipped.

```asm
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

## input.ifXDirReleased / input.ifYDirReleased

These detect if a direction on the given axis has just been released this frame, and jump to the relevant label if it has. This is more efficient that checking each button on the axis individually as the input only needs to be read from the buffer once.

```asm
input.ifXDirReleased, left, right, +
    left:
        ; Left has just been released
        jp +    ; (remember to skip over right label)
    right:
        ; Right has just been released
+:

input.ifYDirReleased, up, down, +
    up:
        ; Up has just been released
        jp +    ; (remember to skip over down label)
    down:
        ; Down has just been released
+:
```

### input.loadDirX

Loads the given register with the directional x-axis: -1 = left, 1 = right, none = 0. An optional multiplier multiplies this result at assemble time.

```asm
input.readPort1

input.loadDirX "a"      ; left = -1, right =  1, none = 0
input.loadDirX "a", 5   ; left = -5, right =  5, none = 0

; Reverse with a negative multiplier
input.loadDirX "a" -1   ; left =  1, right = -1, none = 0

; Load a different register
input.loadDirX "b"
input.loadDirX "c"
input.loadDirX "bc"
input.loadDirX "de"
input.loadDirX "hl", 6
; etc.
```

### input.loadDirY

Loads the given register with the directional y-axis: -1 = up, 1 = down, none = 0. An optional multiplier multiplies this result at assemble time.

```asm
input.readPort1

input.loadDirY "a"      ; up = -1, down = 1, none = 0
input.loadDirY "a", 4   ; up = -4, down = 4, none = 0

; Reverse with a negative multiplier
input.loadDirY "a", -1  ; up =  1, down = -1, none = 0

; Load a different register
input.loadDirY "b"
input.loadDirY "c"
input.loadDirY "bc"
input.loadDirY "de", 10
; etc.
```
