.repeat 2 index controller
    describe { "input.ifXDir (pad {controller + 1})" }
        test "jps when neither left nor right are pressed"
            test.input.mockController controller, zest.NO_INPUT

            zest.initRegisters

            utils.preserve
                input.ifXDir +, ++, +++
            utils.restore
                +:
                    zest.fail "Left called"
                ++:
                    zest.fail "Right called"
                +++:
                    expect.all.toBeUnclobbered
            ++++:

        test "jps to left when left is pressed"
            test.input.mockController controller, zest.LEFT

            zest.initRegisters

            utils.preserve
                input.ifXDir +, ++, +++
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
            test.input.mockController controller, zest.RIGHT

            zest.initRegisters

            utils.preserve
                input.ifXDir +, ++, +++
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
