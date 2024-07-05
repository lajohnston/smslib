.repeat 2 index controller
    describe { "input.ifYDirPressed (pad {controller + 1})" }
        test "jps to else when neither up nor down are pressed"
            test.input.mockController controller, zest.NO_INPUT

            zest.initRegisters

            utils.preserve
                input.ifYDirPressed +, ++, +++
            utils.restore
                +:
                    zest.fail "Up called"
                ++:
                    zest.fail "Down called"
                +++:
                    expect.all.toBeUnclobbered
            ++++:

        test "jps to else when up was pressed last frame and this frame"
            test.input.mockController controller, zest.UP, 2

            zest.initRegisters

            utils.preserve
                input.ifYDirPressed +, ++, +++
            utils.restore
                +:
                    zest.fail "Up called"
                ++:
                    zest.fail "Down called"
                +++:
                    expect.all.toBeUnclobbered
            ++++:

        test "jps to else when down was pressed last frame and this frame"
            test.input.mockController controller, zest.DOWN, 2

            zest.initRegisters

            utils.preserve
                input.ifYDirPressed +, ++, +++
            utils.restore
                +:
                    zest.fail "Up called"
                ++:
                    zest.fail "Down called"
                +++:
                    expect.all.toBeUnclobbered
            ++++:

        test "jps to else when up was pressed last frame but not this frame"
            test.input.mockController controller, zest.UP
            test.input.mockController controller, zest.NO_INPUT

            zest.initRegisters

            utils.preserve
                input.ifYDirPressed +, ++, +++
            utils.restore
                +:
                    zest.fail "Up called"
                ++:
                    zest.fail "Down called"
                +++:
                    expect.all.toBeUnclobbered
            ++++:

        test "jps to else when down was pressed last frame but not this frame"
            test.input.mockController controller, zest.DOWN
            test.input.mockController controller, zest.NO_INPUT

            zest.initRegisters

            utils.preserve
                input.ifYDirPressed +, ++, +++
            utils.restore
                +:
                    zest.fail "Up called"
                ++:
                    zest.fail "Down called"
                +++:
                    expect.all.toBeUnclobbered
            ++++:

        test "jps to up when up was not pressed last frame but is this frame"
            test.input.mockController controller, zest.NO_INPUT
            test.input.mockController controller, zest.UP

            zest.initRegisters

            utils.preserve
                input.ifYDirPressed +, ++, +++
            utils.restore
                +:
                    expect.all.toBeUnclobbered
                    jp ++++ ; pass
                ++:
                    zest.fail "Down called"
                +++:
                    zest.fail "Else called"
            ++++:

        test "jps to down when down was not pressed last frame but is this frame"
            test.input.mockController controller, zest.NO_INPUT
            test.input.mockController controller, zest.DOWN

            zest.initRegisters

            utils.preserve
                input.ifYDirPressed +, ++, +++
            utils.restore
                +:
                    zest.fail "Up called"
                ++:
                    expect.all.toBeUnclobbered
                    jp ++++ ; pass
                +++:
                    zest.fail "Else called"
            ++++:
.endr
