.repeat 2 index controller
    describe { "input.ifReleased should run the code block if the given button was pressed last frame but isn't now (controller {controller + 1})" }
        .repeat 6 index buttonNumber
            test.input.defineButtonData buttonNumber ; set constants (see helpers)

            test { "{BUTTON_NAME} button" }
                test.input.mockController controller, FAKE_INPUT                    ; was pressed
                test.input.mockController controller, ALL_BUTTONS_EXCEPT_CURRENT    ; isn't now

                input.ifReleased TEST_INPUT, +
                    ; Pass test
                    jp ++
                +:

                ; Otherwise, fail
                zest.fail

                ++:
        .endr

    describe { "input.ifReleased should jump over the code block if the given button is still pressed (controller {controller + 1})" }
        .repeat 6 index buttonNumber
            test.input.defineButtonData buttonNumber ; set constants (see helpers)

            test { "{BUTTON_NAME} button" }
                test.input.mockController controller, FAKE_INPUT

                input.ifReleased TEST_INPUT, +
                    ; Fail test
                    zest.fail
                +:
        .endr

    describe { "input.ifReleased should jump over the code block if the given button wasn't pressed last frame (controller {controller + 1})" }
        .repeat 6 index buttonNumber
            test.input.defineButtonData buttonNumber ; set constants (see helpers)

            test { "{BUTTON_NAME} button" }
                test.input.mockController controller, ALL_BUTTONS_EXCEPT_CURRENT, 2

                input.ifReleased TEST_INPUT, +
                    ; Fail test
                    zest.fail
                +:
        .endr

    ;====
    ; Multiple buttons
    ;====

    describe { "input.ifReleased should run the code block when all given buttons were pressed but now aren't (controller {controller + 1})" }
        .repeat 6 index buttonNumber
            test.input.defineButtonData buttonNumber ; set constants (see helpers)

            test { "{BUTTON_NAME} button" }
                test.input.mockController controller, ALL_BUTTONS                   ; this frame
                test.input.mockController controller, ALL_BUTTONS_EXCEPT_CURRENT    ; last frame

                input.ifReleased input.UP, input.DOWN, input.LEFT, input.RIGHT, input.BUTTON_1, input.BUTTON_2, +
                    ; Pass test
                    jp ++
                +:

                ; Otherwise, fail
                zest.fail

                ++:
        .endr

    describe { "input.ifReleased should jp over the code block if not all given buttons were pressed last frame (controller {controller + 1})" }
        .repeat 6 index buttonNumber
            test.input.defineButtonData buttonNumber ; set constants (see helpers)

            test { "{BUTTON_NAME} button" }
                test.input.mockController controller, ALL_BUTTONS_EXCEPT_CURRENT    ; last frame
                test.input.mockController controller, NO_BUTTONS                    ; this frame

                ; Check if all buttons are pressed
                input.ifReleased input.UP, input.DOWN, input.LEFT, input.RIGHT, input.BUTTON_1, input.BUTTON_2, +
                    zest.fail   ; fail test
                +:
        .endr
.endr
