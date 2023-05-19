;===
; Input
;
; Reads and interprets joypad inputs
;====

.define input.ENABLED 1

; Dependencies
.ifndef utils.assert
    .include "./utils/assert.asm"
.endif

.include "./utils/ramSlot.asm"

; Constants
.define input.UP        %00000001
.define input.DOWN      %00000010
.define input.LEFT      %00000100
.define input.RIGHT     %00001000
.define input.BUTTON_1  %00010000
.define input.BUTTON_2  %00100000

.define input.UP_BIT        0
.define input.DOWN_BIT      1
.define input.LEFT_BIT      2
.define input.RIGHT_BIT     3
.define input.BUTTON_1_BIT  4
.define input.BUTTON_2_BIT  5

.define input.PORT_1    $dc
.define input.PORT_2    $dd

;====
; RAM section storing the last port that was read with either input.readPort1
; or input.readPort2
;====
.ramsection "input.ram.activePort" slot utils.ramSlot
    input.ram.activePort.current:   db
    input.ram.activePort.previous:  db
.ends

;====
; RAM section to store the previous input values for each port
;====
.ramsection "input.ram.previous" slot utils.ramSlot
    input.ram.previous.port1:    db
    input.ram.previous.port2:    db
.ends

;====
; Initialises the input handler in RAM
;====
.macro "input.init"
    ; Initialise all buttons to released
    xor a
    ld (input.ram.activePort.current), a
    ld (input.ram.activePort.previous), a
    ld (input.ram.previous.port1), a
    ld (input.ram.previous.port2), a
.endm

;====
; Reads the input from controller port 1 into the ram buffer
;
; The reset bits represent the buttons currently pressed
;
;       xx000000
;       |||||||*- Up
;       ||||||*-- Down
;       |||||*--- Left
;       ||||*---- Right
;       |||*----- Button 1
;       ||*------ Button 2
;       ** junk
;====
.macro "input.readPort1"
    ; Copy previous value of port 1 to activePort.previous
    ld a, (input.ram.previous.port1)        ; load previous.port1
    ld (input.ram.activePort.previous), a   ; store in activePort.previous

    ; Load current port 1 input and store in activePort.current
    in a, input.PORT_1                      ; load input
    xor $ff                                 ; invert so 1 = pressed and 0 = released
    ld (input.ram.activePort.current), a    ; store in activePort.current
    ld (input.ram.previous.port1), a        ; store in previous.port1 for next time
.endm

;====
; Reads the input from controller port 2 into the RAM buffer
; See input.readPort1 documentation for details
;====
.section "input._readPort2" free
    input._readPort2:
        ; Copy previous value of port 2 to activePort.previous
        ld a, (input.ram.previous.port2)        ; load previous.port1
        ld (input.ram.activePort.previous), a   ; store in activePort.previous

        ; Retrieve up and down buttons, which are stored within the PORT_1 byte
        in a, input.PORT_1
        and %11000000                           ; clear port 1 buttons
        ld b, a                                 ; store in B (DU------)

        ; Read remaining buttons from PORT_2
        in a, input.PORT_2
        and %00001111                           ; reset misc. bits (----21RL)

        ; Combine into 1 byte (DU--21RL)
        or b

        ; Rotate left twice to match port 1 format
        rlca    ; rotate DU--21RL to U--21RLD
        rlca    ; rotate U--21RLD to --21RLDU

        ; Invert so 1 = pressed and 0 = released
        xor $ff

        ; Store in ram buffer
        ld (input.ram.activePort.current), a
        ld (input.ram.previous.port2), a        ; store in previous.port2 for next time

        ret
.ends

;====
; Alias for input._readPort2
;====
.macro "input.readPort2"
    call input._readPort2
.endm

;====
; Load A with buttons that are pressed down this frame and were pressed down
; in the last frame
;
; @out  a   held buttons (--21RLDU)
;====
.macro "input.loadAHeld"
    ; Load current input into L and previous into H
    ld hl, (input.ram.activePort.current)
    ld a, l     ; load current into A
    and h       ; AND with previous
.endm

;====
; Sets A with buttons that were released last frame but are now pressed
;
; @out  a   the just-pressed buttons (--21RLDU)
;====
.macro "input.loadAPressed"
    ; Load L with current input value and H with previous
    ld hl, (input.ram.activePort.current)
    ld a, l ; load current into A
    xor h   ; XOR with previous. The set bits are now buttons that have changed
    and l   ; AND with current; Set bits have changed AND are currently pressed
.endm

;====
; Load A with buttons that were pressed in the previous frame but are now released
;
; @out  a   released buttons (--21RLDU)
;====
.macro "input.loadAReleased"
    ; Load L with current input value and H with previous
    ld hl, (input.ram.activePort.current)
    ld a, l ; load current into A
    xor h   ; XOR with previous. The set bits are now buttons that have changed
    and h   ; AND with previous; Set bits have changed AND are not currently pressed
.endm

;====
; Check if one or more buttons are currently pressed
;
; @in   ...buttons  the button(s) to check (input.UP, input.BUTTON_1 etc)
; @in   else        the address to jump to if the button(s) are not pressed
;====
.macro "input.if"
    .if NARGS == 2
        utils.assert.range \1, input.UP, input.BUTTON_2, "input.asm \.: Invalid button argument"
        utils.assert.label \2, "input.asm \.: Invalid else argument"

        ld a, (input.ram.activePort.current)
        and \1      ; check button bit
        jp z, \2    ; jp to else if the bit was not set
    .else
        ;===
        ; Check if multiple buttons are pressed
        ;===

        ; OR button masks together to create a single mask
        .define mask\.\@ 0

        .repeat NARGS - 1
            utils.assert.range \1, input.UP, input.BUTTON_2, "input.asm \.: Invalid button argument"
            .redefine mask\.\@ mask\.\@ | \1
            .shift  ; shift arguments so \2 becomes \1
        .endr

        ; Assert remaining \1 argument is the else label
        utils.assert.label \1, "input.asm \.: Expected last argument to be a label"

        ld a, (input.ram.activePort.current)
        and mask\.\@    ; clear other buttons
        cp mask\.\@     ; compare result with mask
        jp nz, \1       ; jp to else if not all buttons are pressed
    .endif
.endm

;====
; Check if one or more buttons have been pressed in both this frame and the
; previous frame
;
; @in   ...buttons  the button(s) to check (input.UP, input.BUTTON_1 etc)
; @in   else        the address to jump to if the button has not been held
;====
.macro "input.ifHeld"
    .if NARGS == 2
        utils.assert.range \1, input.UP, input.BUTTON_2, "input.asm \.: Invalid button argument"
        utils.assert.label \2, "input.asm \.: Invalid else argument"

        input.loadAHeld ; load A with held buttons
        and \1          ; check button bit
        jp z, \2        ; jp to else if the bit was not set
    .else
        ;===
        ; Check if multiple buttons are pressed
        ;===

        ; OR button masks together to create a single mask
        .define mask\.\@ 0

        .repeat NARGS - 1
            utils.assert.range \1, input.UP, input.BUTTON_2, "input.asm \.: Invalid button argument"
            .redefine mask\.\@ mask\.\@ | \1
            .shift  ; shift arguments so \2 becomes \1
        .endr

        ; Assert remaining \1 argument is the else label
        utils.assert.label \1, "input.asm \.: Expected last argument to be a label"

        input.loadAHeld ; load A with held buttons
        and mask\.\@    ; clear other buttons
        cp mask\.\@     ; compare result with mask
        jp nz, \1       ; jp to else if not all buttons are held
    .endif
.endm

;====
; Check if the given button(s) have just been pressed this frame
;
; @in   ...buttons  one or more button(s) to check (input.UP, input.BUTTON_1 etc)
; @in   else        the address to jump to if the button(s) are either not
;                   pressed, or were already pressed last frame
;====
.macro "input.ifPressed"
    .if NARGS == 2
        utils.assert.range \1, input.UP, input.BUTTON_2, "input.asm \.: Invalid button argument"
        utils.assert.label \2, "input.asm \.: Invalid label argument"

        ; Load input that was released last frame but is now pressed
        input.loadAPressed
        and \1      ; check button bit
        jp z, \2    ; jp to else if the bit was not set
    .else
        ;===
        ; Check if all buttons are pressed, and that not all of them were pressed
        ; last frame. This is a little more complex so the buttons don't all
        ; have to have been pressed down in a single frame
        ;===

        ; OR button masks together to create a single mask
        .define mask\.\@ 0

        .repeat NARGS - 1
            utils.assert.range \1, input.UP, input.BUTTON_2, "input.asm \.: Invalid button argument"
            .redefine mask\.\@ mask\.\@ | \1
            .shift  ; shift arguments so \2 becomes \1
        .endr

        ; Assert remaining \1 argument is the else label
        utils.assert.label \1, "input.asm \.: Expected last argument to be a label"

        ; Load H with previous and L with current
        ld hl, (input.ram.activePort.current)

        ; If all given buttons are currently pressed
        ld a, l         ; load current into A
        ld l, mask\.\@  ; load buttons mask into L
        and l           ; filter out other buttons
        cp l            ; check if all given buttons are currently pressed
        jp nz, \1       ; jump if all given buttons aren't currently pressed

        ; All given buttons are pressed; Check if they were pressed last frame
        ld a, h         ; load previous input
        and l           ; filter out other buttons
        cp l            ; check if all given buttons are currently pressed
        jp z, \1        ; jp to else if all were already pressed last frame
    .endif
.endm

;====
; Check if the given button(s) have just been released this frame
;
; @in   ...buttons  one or more button(s) to check (input.UP, input.BUTTON_1 etc)
; @in   else        the address to jump to if the button(s) are either not
;                   pressed, or were already pressed last frame
;====
.macro "input.ifReleased"
    .if NARGS == 2
        utils.assert.range \1, input.UP, input.BUTTON_2, "input.asm \.: Invalid button argument"
        utils.assert.label \2, "input.asm \.: Invalid label argument"

        ; Load input that was released last frame but is now pressed
        input.loadAReleased
        and \1      ; check button bit
        jp z, \2    ; jp to else if the bit was not set
    .else
        ; OR button masks together to create a single mask
        .define mask\.\@ 0

        .repeat NARGS - 1
            utils.assert.range \1, input.UP, input.BUTTON_2, "input.asm \.: Invalid button argument"
            .redefine mask\.\@ mask\.\@ | \1
            .shift  ; shift arguments so \2 becomes \1
        .endr

        ; Assert remaining \1 argument is the else label
        utils.assert.label \1, "input.asm \.: Expected last argument to be a label"

        ;===
        ; Check if all buttons had been pressed last frame, but not all are now
        ;===

        ; Load H with previous and L with current
        ld hl, (input.ram.activePort.current)

        ; If all given buttons were pressed
        ld a, h         ; load previous into A
        ld h, mask\.\@  ; load buttons mask into H
        and h           ; filter out other buttons
        cp h            ; check if all given buttons were pressed
        jp nz, \1       ; jump if all given buttons weren't pressed last frame

        ; All given buttons were pressed; Check if any are now released
        ld a, l         ; load current input
        and h           ; filter out other buttons
        cp h            ; check if all given buttons are currently pressed
        jp z, \1        ; jp to else if all are still pressed
    .endif
.endm

;====
; Checks if either direction on an axis is pressed and jumps to the relevant
; label. If the negative direction (left or up) on the axis is pressed, it
; will continue the code flow without jumping
;
; @in   a               input value to check (--21RLDU)
;
; @in   negativeDir     negative direction on the axis (input.LEFT or input.UP)
; @in   positiveDir     positive direction on the axis (input.RIGHT or input.DOWN)
; @in   negativeLabel   will continue to this label if the negative direction is
;                       pressed
; @in   positiveLabel   label to jump to if the positive direction is pressed
; @in   else            label to jump to if neither direction is pressed
;====
.macro "input._jpIfDirection" args negativeDir positiveDir negativeLabel positiveLabel elseLabel
    utils.assert.equals NARGS 5 "input.asm \.: Invalid number of arguments given"

    utils.assert.oneOf negativeDir, input.LEFT, input.UP, "input.asm \.: Invalid 'negativeDir' argument"
    utils.assert.oneOf positiveDir, input.RIGHT, input.DOWN, "input.asm \.: Invalid 'positiveDir' argument"

    utils.assert.label negativeLabel "input.asm \.: Invalid 'negativeLabel' argument"
    utils.assert.label positiveLabel "input.asm \.: Invalid 'positiveLabel' argument"
    utils.assert.label elseLabel "input.asm \.: Invalid 'elseLabel' argument"

    and negativeDir | positiveDir   ; check if either direction is pressed
    jp z, elseLabel                 ; jump to else label if neither are pressed

    and positiveDir                 ; check positive direction
    jp nz, positiveLabel            ; jump if positive direction pressed

    ; ...continue to the negativeLabel handler
.endm

;====
; Jumps to the relevant label if either left or right are currently pressed
;
; @in   left    the label to continue to if LEFT is currently pressed
; @in   right   the label to jp to if RIGHT is currently pressed
; @in   else    the label to jp to if neither LEFT nor RIGHT are currently pressed
;====
.macro "input.ifXDir" args left right else
    utils.assert.equals NARGS 3 "input.asm \.: Invalid number of arguments given"
    utils.assert.label left "input.asm \.: Invalid 'left' argument"
    utils.assert.label right "input.asm \.: Invalid 'right' argument"
    utils.assert.label else "input.asm \.: Invalid 'else' argument"

    ; Load currently pressed input and jump to relevant label
    ld a, (input.ram.activePort.current)
    input._jpIfDirection input.LEFT input.RIGHT left right else
.endm

;====
; Jumps to the relevant label if either left or right have been pressed for
; both this frame and the previous frame
;
; @in   left    the label to continue to if LEFT is held
; @in   right   the label to jp to if RIGHT is held
; @in   else    the label to jp to if neither LEFT nor RIGHT are held
;====
.macro "input.ifXDirHeld" args left right else
    utils.assert.equals NARGS 3 "input.asm \.: Invalid number of arguments given"
    utils.assert.label left "input.asm \.: Invalid 'left' argument"
    utils.assert.label right "input.asm \.: Invalid 'right' argument"
    utils.assert.label else "input.asm \.: Invalid 'else' argument"

    ; Load held input and jump to relevant label
    input.loadAHeld
    input._jpIfDirection input.LEFT input.RIGHT left right else
.endm

;====
; Jumps to the relevant label if either left or right have just been pressed
; this frame
;
; @in   left    the label to continue to if LEFT has just been pressed
; @in   right   the label to jp to if RIGHT had just been pressed
; @in   else    the label to jp to if neither LEFT nor RIGHT have just been pressed
;====
.macro "input.ifXDirPressed" args left right else
    utils.assert.equals NARGS 3 "input.asm \.: Invalid number of arguments given"
    utils.assert.label left "input.asm \.: Invalid 'left' argument"
    utils.assert.label right "input.asm \.: Invalid 'right' argument"
    utils.assert.label else "input.asm \.: Invalid 'else' argument"

    ; Load input that was released last frame but is now pressed
    input.loadAPressed

    ; Jump to the relevant label
    input._jpIfDirection input.LEFT input.RIGHT left right else
.endm

;====
; Jumps to the relevant label if either left or right were pressed but have
; just been released
;
; @in   left    the label to continue to if LEFT has just been released
; @in   right   the label to jp to if RIGHT had just been released
; @in   else    the label to jp to if neither LEFT nor RIGHT have just been released
;====
.macro "input.ifXDirReleased" args left right else
    utils.assert.equals NARGS 3 "input.asm \.: Invalid number of arguments given"
    utils.assert.label left "input.asm \.: Invalid 'left' argument"
    utils.assert.label right "input.asm \.: Invalid 'right' argument"
    utils.assert.label else "input.asm \.: Invalid 'else' argument"

    ; Load input that was pressed last frame but has just been released
    input.loadAReleased

    ; Jump to the relevant label
    input._jpIfDirection input.LEFT input.RIGHT left right else
.endm

;====
; Jumps to the relevant label if either up or down are currently pressed
;
; @in   up      the label to continue to if UP is currently pressed
; @in   down    the label to jp to if DOWN is currently pressed
; @in   else    the label to jp to if neither UP nor DOWN are currently pressed
;====
.macro "input.ifYDir" args up down else
    utils.assert.equals NARGS 3 "input.asm \.: Invalid number of arguments given"
    utils.assert.label up "input.asm \.: Invalid 'up' argument"
    utils.assert.label down "input.asm \.: Invalid 'down' argument"
    utils.assert.label else "input.asm \.: Invalid 'else' argument"

    ; Load currently pressed direction and jump to the relevant label
    ld a, (input.ram.activePort.current)
    input._jpIfDirection input.UP input.DOWN up down else
.endm

;====
; Jumps to the relevant label if either up or down have been pressed for this
; frame and the previous frame
;
; @in   up      the label to continue to if UP is held
; @in   down    the label to jp to if DOWN is held
; @in   else    the label to jp to if neither UP nor DOWN are held
;====
.macro "input.ifYDirHeld" args up down else
    utils.assert.equals NARGS 3 "input.asm \.: Invalid number of arguments given"
    utils.assert.label up "input.asm \.: Invalid 'up' argument"
    utils.assert.label down "input.asm \.: Invalid 'down' argument"
    utils.assert.label else "input.asm \.: Invalid 'else' argument"

    ; Load held buttons and jump to the relevant label
    input.loadAHeld
    input._jpIfDirection input.UP input.DOWN up down else
.endm

;====
; Jumps to the relevant label if either up or down have just been pressed this
; frame.
;
; @in   up      the label to continue to if UP has just been pressed
; @in   down    the label to jp to if DOWN had just been pressed
; @in   else    the label to jp to if neither UP or DOWN have just been pressed
;====
.macro "input.ifYDirPressed" args up down else
    utils.assert.equals NARGS 3 "input.asm \.: Invalid number of arguments given"
    utils.assert.label up "input.asm \.: Invalid 'up' argument"
    utils.assert.label down "input.asm \.: Invalid 'down' argument"
    utils.assert.label else "input.asm \.: Invalid 'else' argument"

    ; Load input that was released last frame but is now pressed
    input.loadAPressed

    ; Jump to the relevant label
    input._jpIfDirection input.UP input.DOWN up down else
.endm

;====
; Jumps to the relevant label if either up or down were pressed last frame but
; have now been released
;
; @in   up      the label to continue to if UP has just been released
; @in   down    the label to jp to if DOWN had just been released
; @in   else    the label to jp to if neither UP or DOWN have just been released
;====
.macro "input.ifYDirReleased" args up down else
    utils.assert.equals NARGS 3 "input.asm \.: Invalid number of arguments given"
    utils.assert.label up "input.asm \.: Invalid 'up' argument"
    utils.assert.label down "input.asm \.: Invalid 'down' argument"
    utils.assert.label else "input.asm \.: Invalid 'else' argument"

    ; Load input that was pressed but has just been released
    input.loadAReleased

    ; Jump to the relevant label
    input._jpIfDirection input.UP input.DOWN up down else
.endm

;====
; Load the X direction (left/right) into register A. By default, -1 = left,
; 1 = right, 0 = none. The result is multiplied by the optional multiplier
; at assemble time
;
; Ensure you have called input.readPort1 or input.readPort2
;
; @in   [multiplier]    optional multiplier for the result (default 1)
; @out  a               -1 = left, 1 = right, 0 = none. This value will be
;                       multiplied by the multiplier at assemble time
;====
.macro "input.loadADirX" isolated args multiplier
    .ifndef multiplier
        .redefine multiplier 1
    .endif

    utils.assert.number multiplier, "input.asm \.: Expected multiplier to be a number"

    ; Read current input data
    ld a, (input.ram.activePort.current)

    ; Check if left is being pressed
    bit input.LEFT_BIT, a
    jp z, +
        ; Left is pressed
        ld a, -1 * multiplier
        jp \.\@end
    +:

    ; Check if right is being pressed
    bit input.RIGHT_BIT, a
    jp z, +
        ; Right is pressed
        ld a, 1 * multiplier
        jp \.\@end
    +:

    ; Nothing pressed
    xor a   ; a = 0

    \.\@end:
.endm

;====
; Load the Y direction (up/down) into register A. By default, -1 = up,
; 1 = down, 0 = none. The result is multiplied by the optional multiplier
; at assemble time
;
; Ensure you have called input.readPort1 or input.readPort2
;
; @in   [multiplier]    optional multiplier for the result (default 1)
; @out  a               -1 = up, 1 = down, 0 = none. This will be multiplied
;                       by the multiplier at assemble time
;====
.macro "input.loadADirY" isolated args multiplier
    .ifndef multiplier
        .redefine multiplier 1
    .endif

    utils.assert.number multiplier, "input.asm \.: Expected multiplier to be a number"

    ; Read current input data
    ld a, (input.ram.activePort.current)

    ; Check if up is being pressed
    bit input.UP_BIT, a
    jp z, +
        ; Up is pressed
        ld a, -1 * multiplier
        jp \.\@end
    +:

    ; Check if down is being pressed
    bit input.DOWN_BIT, a
    jp z, +
        ; Down is pressed
        ld a, 1 * multiplier
        jp \.\@end
    +:

    ; Nothing pressed
    xor a   ; a = 0

    \.\@end:
.endm
