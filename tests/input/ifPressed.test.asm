.repeat 2 index controller
    describe { "input.ifPressed should run the code block if the given button wasn't pressed last frame but is now (controller {controller + 1})" }
        .repeat 6 index buttonNumber
            test.input.defineButtonData buttonNumber ; set constants (see helpers)

            test { "{BUTTON_NAME} button" }
                test.input.mockController controller, ALL_BUTTONS_EXCEPT_CURRENT    ; last frame
                test.input.mockController controller, FAKE_INPUT                    ; this frame

                input.ifPressed TEST_INPUT, +
                    ; Pass test
                    jp ++
                +:

                ; Otherwise, fail
                zest.fail

                ++:
        .endr

    describe { "input.ifPressed should jump over the code block if the given button is not pressed (controller {controller + 1})" }
        .repeat 6 index buttonNumber
            test.input.defineButtonData buttonNumber ; set constants (see helpers)

            test { "{BUTTON_NAME} button" }
                test.input.mockController controller, ALL_BUTTONS_EXCEPT_CURRENT

                input.ifPressed TEST_INPUT, +
                    ; Fail test
                    zest.fail
                +:
        .endr

    describe { "input.ifPressed should jump over the code block if the given button was pressed last frame but not this frame (controller {controller + 1})" }
        .repeat 6 index buttonNumber
            test.input.defineButtonData buttonNumber ; set constants (see helpers)

            test { "{BUTTON_NAME} button" }
                test.input.mockController controller, FAKE_INPUT                    ; was pressed
                test.input.mockController controller, ALL_BUTTONS_EXCEPT_CURRENT    ; isn't now

                input.ifPressed TEST_INPUT, +
                    ; Fail test
                    zest.fail
                +:
        .endr

    ;====
    ; Multiple buttons
    ;====

    describe { "input.ifPressed should run the code block when all given buttons are pressed this frame but weren't last frame (controller {controller + 1})" }
        .repeat 6 index buttonNumber
            test.input.defineButtonData buttonNumber ; set constants (see helpers)

            test { "{BUTTON_NAME} button" }
                test.input.mockController controller, ALL_BUTTONS_EXCEPT_CURRENT    ; last frame
                test.input.mockController controller, ALL_BUTTONS                   ; this frame

                input.ifPressed input.UP, input.DOWN, input.LEFT, input.RIGHT, input.BUTTON_1, input.BUTTON_2, +
                    ; Pass test
                    jp ++
                +:

                ; Otherwise, fail
                zest.fail

                ++:
        .endr

    describe { "input.ifPressed should jp over the code block if multiple buttons are given but not all are pressed this frame (controller {controller + 1})" }
        .repeat 6 index buttonNumber
            test.input.defineButtonData buttonNumber ; set constants (see helpers)

            test { "{BUTTON_NAME} button" }
                test.input.mockController controller, ALL_BUTTONS_EXCEPT_CURRENT

                ; Check if all buttons are pressed
                input.ifPressed input.UP, input.DOWN, input.LEFT, input.RIGHT, input.BUTTON_1, input.BUTTON_2, +
                    zest.fail   ; fail test
                +:
        .endr

    describe { "input.ifPressed when multiple buttons are given (controller {controller + 1})" }
        test { "should jp over the code block if all given buttons were pressed but were already pressed last frame" }
            test.input.mockController controller, ALL_BUTTONS, 2

            ; Check if all buttons are pressed
            input.ifPressed input.UP, input.DOWN, input.LEFT, input.RIGHT, input.BUTTON_1, input.BUTTON_2, +
                zest.fail   ; fail test
            +:
.endr
