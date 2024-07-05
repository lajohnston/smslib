.repeat 2 index controller
    describe { "input.ifXDirHeld (pad {controller + 1})" }
        test "jps to else when neither left nor right are pressed"
            test.input.mockController controller, zest.NO_INPUT 2

            zest.initRegisters

            utils.preserve
                input.ifXDirHeld +, ++, +++
            utils.restore
                +:
                    zest.fail "Left called"
                ++:
                    zest.fail "Right called"
                +++:
                    expect.all.toBeUnclobbered
            ++++:

        test "jps to else when left was pressed last frame but not this frame"
            test.input.mockController controller, zest.LEFT
            test.input.mockController controller, zest.NO_INPUT

            zest.initRegisters

            utils.preserve
                input.ifXDirHeld +, ++, +++
            utils.restore
                +:
                    zest.fail "Left called"
                ++:
                    zest.fail "Right called"
                +++:
                    expect.all.toBeUnclobbered
            ++++:

        test "jps to else when right was pressed last frame but not this frame"
            test.input.mockController controller, zest.RIGHT
            test.input.mockController controller, zest.NO_INPUT

            zest.initRegisters

            utils.preserve
                input.ifXDirHeld +, ++, +++
            utils.restore
                +:
                    zest.fail "Left called"
                ++:
                    zest.fail "Right called"
                +++:
                    expect.all.toBeUnclobbered
            ++++:

        test "jps to else when left was pressed this frame but not last frame"
            test.input.mockController controller, zest.NO_INPUT
            test.input.mockController controller, zest.LEFT

            zest.initRegisters

            utils.preserve
                input.ifXDirHeld +, ++, +++
            utils.restore
                +:
                    zest.fail "Left called"
                ++:
                    zest.fail "Right called"
                +++:
                    expect.all.toBeUnclobbered
            ++++:

        test "jps to else when right was pressed this frame but not last frame"
            test.input.mockController controller, zest.NO_INPUT
            test.input.mockController controller, zest.RIGHT

            zest.initRegisters

            utils.preserve
                input.ifXDirHeld +, ++, +++
            utils.restore
                +:
                    zest.fail "Left called"
                ++:
                    zest.fail "Right called"
                +++:
                    expect.all.toBeUnclobbered
            ++++:

        test "jps to left when left is held"
            test.input.mockController controller, zest.LEFT 2

            zest.initRegisters

            utils.preserve
                input.ifXDirHeld +, ++, +++
            utils.restore
                +:
                    expect.all.toBeUnclobbered
                    jp ++++ ; pass
                ++:
                    zest.fail "Right called"
                +++:
                    zest.fail "Else called"
            ++++:

        test "jps to right when right is pressed"
            test.input.mockController controller, zest.RIGHT 2

            zest.initRegisters

            utils.preserve
                input.ifXDirHeld +, ++, +++
            utils.restore
                +:
                    zest.fail "Left called"
                ++:
                    expect.all.toBeUnclobbered
                    jp ++++ ; pass
                +++:
                    zest.fail "Else called"
            ++++:
.endr
