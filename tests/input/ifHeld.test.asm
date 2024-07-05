.redefine utils.registers.AUTO_PRESERVE 1

; Each controller
.repeat 2 index controller
    describe { "input.ifHeld (controller {controller + 1}) should run the code block when the given button has been pressed for two frames" }
        .repeat 6 index button
            test.input.defineButtonData button  ; see helpers

            test { "{BUTTON_NAME} button" }
                test.input.mockController controller, FAKE_INPUT, 2

                zest.initRegisters

                input.ifHeld TEST_INPUT, +
                    expect.all.toBeUnclobbered
                    jp ++   ; pass test
                +:

                ; Otherwise, fail
                zest.fail

                ++:
        .endr

    describe { "input.ifHeld should jump over the code block if the button is was not pressed this frame or last frame (controller {controller + 1})" }
        .repeat 6 index button
            test.input.defineButtonData button  ; see helpers

            test { "{BUTTON_NAME} button" }
                test.input.mockController controller, ALL_BUTTONS_EXCEPT_CURRENT, 2

                zest.initRegisters

                input.ifHeld TEST_INPUT, +
                    zest.fail   ; this shouldn't run
                +:

                expect.all.toBeUnclobbered
        .endr

    describe { "input.ifHeld should jump over the code block if the button is not pressed this frame (controller {controller + 1})" }
        .repeat 6 index button
            test.input.defineButtonData button  ; see helpers

            test { "{BUTTON_NAME} button" }
                test.input.mockController controller, FAKE_INPUT                    ; last frame
                test.input.mockController controller, ALL_BUTTONS_EXCEPT_CURRENT    ; this frame

                zest.initRegisters

                input.ifHeld TEST_INPUT, +
                    zest.fail
                +:

                expect.all.toBeUnclobbered
        .endr

    describe { "input.ifHeld should jump over the code block if the button is was not pressed last frame (controller {controller + 1})" }
        .repeat 6 index button
            test.input.defineButtonData button  ; see helpers

            test { "{BUTTON_NAME} button" }
                test.input.mockController controller, ALL_BUTTONS_EXCEPT_CURRENT    ; last frame
                test.input.mockController controller, FAKE_INPUT                    ; this frame

                zest.initRegisters

                input.ifHeld TEST_INPUT, +
                    zest.fail   ; this shouldn't run
                +:

                expect.all.toBeUnclobbered
        .endr

    ;====
    ; When multiple buttons are given
    ;====

    describe { "input.ifHeld with multiple buttons given (controller {controller + 1})" }
        test { "should run the code block when all the given buttons have been pressed for two frames" }
            test.input.mockController controller, ALL_BUTTONS, 2

            zest.initRegisters

            input.ifHeld input.UP, input.DOWN, input.LEFT, input.RIGHT, input.BUTTON_1, input.BUTTON_2, +
                expect.all.toBeUnclobbered
                jp ++   ; pass test
            +:

            ; Otherwise, fail
            zest.fail

            ++:

    describe { "input.ifHeld should jump over the code block if not all given buttons were pressed last frame (controller {controller + 1})" }
        .repeat 6 index button
            test.input.defineButtonData button  ; see helpers

            test { "{BUTTON_NAME} button" }
                test.input.mockController controller, ALL_BUTTONS_EXCEPT_CURRENT    ; last frame
                test.input.mockController controller, ALL_BUTTONS                   ; this frame

                zest.initRegisters

                input.ifHeld input.UP, input.DOWN, input.LEFT, input.RIGHT, input.BUTTON_1, input.BUTTON_2, +
                    zest.fail   ; this shouldn't run
                +:

                expect.all.toBeUnclobbered
        .endr

    describe { "input.ifHeld should jump over the code block if not all given buttons are pressed this frame (controller {controller + 1})" }
        .repeat 6 index button
            test.input.defineButtonData button  ; see helpers

            test { "{BUTTON_NAME} button" }
                test.input.mockController controller, ALL_BUTTONS                   ; last frame
                test.input.mockController controller, ALL_BUTTONS_EXCEPT_CURRENT    ; this frame

                zest.initRegisters

                input.ifHeld input.UP, input.DOWN, input.LEFT, input.RIGHT, input.BUTTON_1, input.BUTTON_2, +
                    zest.fail   ; this shouldn't run
                +:

                expect.all.toBeUnclobbered
        .endr

    describe { "input.ifHeld should jump over the code block if not all given buttons are pressed this frame or last frame (controller {controller + 1})" }
        .repeat 6 index button
            test.input.defineButtonData button  ; see helpers

            test { "{BUTTON_NAME} button" }
                test.input.mockController controller, ALL_BUTTONS_EXCEPT_CURRENT, 2

                zest.initRegisters

                input.ifHeld input.UP, input.DOWN, input.LEFT, input.RIGHT, input.BUTTON_1, input.BUTTON_2, +
                    zest.fail   ; this shouldn't run
                +:

                expect.all.toBeUnclobbered
        .endr

.redefine utils.registers.AUTO_PRESERVE 0
