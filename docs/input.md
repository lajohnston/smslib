# Input (input.asm)

Interprets input from the controller pads.

```
input.readPort1

input.if input.LEFT, +
    ; Left has been pressed
+:

input.if input.BUTTON_1, +
    ; Button 1 has been pressed
+:

; Available buttons
input.UP
input.DOWN
input.LEFT
input.RIGHT
input.BUTTON_1
input.BUTTON_2

```

If needed you can change the register that holds the input value (default is `b`):

```
input.useRegister "d"
input.readPort1     ; result stored in register d

; This will check input value in register d
input.if input.LEFT, +
    ; Left has been pressed
+:
```
