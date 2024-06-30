.redefine utils.registers.AUTO_PRESERVE 1

.repeat 2 index controller
    describe { "input.if should run the code block if the given button is pressed (controller {controller + 1})" }
        .repeat 6 index buttonNumber
            test.input.defineButtonData buttonNumber ; set constants (see helpers)

            test { "{BUTTON_NAME} button" }
                test.input.mockController controller, FAKE_INPUT

                zest.initRegisters

                input.if TEST_INPUT, +
                    expect.all.toBeUnclobbered
                    jp ++   ; pass test
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

                zest.initRegisters

                input.if TEST_INPUT, +
                    ; Fail test
                    zest.fail
                +:

                expect.all.toBeUnclobbered
        .endr

    describe { "input.if when multiple buttons are given (controller {controller + 1})" }
        it { "should run the code block when all buttons are pressed" }
            test.input.mockController controller, $ff   ; all buttons pressed

            zest.initRegisters

            ; Check if all buttons are pressed
            input.if input.UP, input.DOWN, input.LEFT, input.RIGHT, input.BUTTON_1, input.BUTTON_2, +
                expect.all.toBeUnclobbered
                jp ++   ; pass test
            +:

            ; Otherwise, fail
            zest.fail

            ++:

    describe { "input.if should jump over the code block if multiple buttons are given but not all are pressed (controller {controller + 1})" }
        .repeat 6 index buttonNumber
            test { "{BUTTON_NAME} button" }
                test.input.defineButtonData buttonNumber ; set constants (see helpers)
                test.input.mockController controller, ALL_BUTTONS_EXCEPT_CURRENT

                zest.initRegisters

                ; Check if all buttons are pressed
                input.if input.UP, input.DOWN, input.LEFT, input.RIGHT, input.BUTTON_1, input.BUTTON_2, +
                    zest.fail   ; fail test
                +:

                expect.all.toBeUnclobbered
        .endr
.endr

.redefine utils.registers.AUTO_PRESERVE 0