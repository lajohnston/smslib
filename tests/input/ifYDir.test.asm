.repeat 2 index controller
    describe { "input.ifYDir (pad {controller + 1})" }
        test "jps to else when neither up nor down are pressed"
            test.input.mockController controller, zest.NO_INPUT

            zest.initRegisters

            utils.preserve
                input.ifYDir +, ++, +++
            utils.restore
                +:
                    zest.fail "Up called"
                ++:
                    zest.fail "Down called"
                +++:
                    expect.all.toBeUnclobbered
            ++++:

        test "jps to up when up is pressed"
            test.input.mockController controller, zest.UP

            zest.initRegisters

            utils.preserve
                input.ifYDir +, ++, +++
            utils.restore
                +:
                    expect.all.toBeUnclobbered
                    jp ++++ ; pass
                ++:
                    zest.fail "Down called"
                +++:
                    zest.fail "Else called"
            ++++:

        test "jps to down when down is pressed"
            test.input.mockController controller, zest.DOWN

            zest.initRegisters

            utils.preserve
                input.ifYDir +, ++, +++
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
