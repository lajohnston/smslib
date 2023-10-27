.repeat 2 index controller
    describe { "input.if should run the code block if the given button is pressed (controller {controller + 1})" }
        .repeat 6 index buttonNumber
            test.input.defineButtonData buttonNumber ; set constants (see helpers)

            test { "{BUTTON_NAME} button" }
                test.input.mockController controller, FAKE_INPUT

                input.if TEST_INPUT, +
                    ; Pass test
                    jp ++
                +:

                ; Otherwise, fail
                zest.fail

                ++:
        .endr

    describe { "input.if should jump over the code block if the given button is not pressed (controller {controller + 1})" }
        .repeat 6 index buttonNumber
            test.input.defineButtonData buttonNumber ; set constants (see helpers)

            test { "{BUTTON_NAME} button" }
                test.input.mockController controller, ALL_BUTTONS_EXCEPT_CURRENT

                input.if TEST_INPUT, +
                    ; Fail test
                    zest.fail
                +:
        .endr

    describe { "input.if when multiple buttons are given (controller {controller + 1})" }
        it { "should run the code block when all buttons are pressed" }
            test.input.mockController controller, $ff   ; all buttons pressed

            ; Check if all buttons are pressed
            input.if input.UP, input.DOWN, input.LEFT, input.RIGHT, input.BUTTON_1, input.BUTTON_2, +
                ; Pass test
                jp ++
            +:

            ; Otherwise, fail
            zest.fail

            ++:

    describe { "input.if should jump over the code block if multiple buttons are given but not all are pressed (controller {controller + 1})" }
        .repeat 6 index buttonNumber
            test { "{BUTTON_NAME} button" }
                test.input.defineButtonData buttonNumber ; set constants (see helpers)
                test.input.mockController controller, ALL_BUTTONS_EXCEPT_CURRENT

                ; Check if all buttons are pressed
                input.if input.UP, input.DOWN, input.LEFT, input.RIGHT, input.BUTTON_1, input.BUTTON_2, +
                    zest.fail   ; fail test
                +:
        .endr
.endr
