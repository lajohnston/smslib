# Input (input.asm)

Interprets input from the controller pads.

```
input.readPort1 ; you can also use input.readPort2

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
