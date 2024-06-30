.redefine utils.registers.AUTO_PRESERVE 1

.repeat 2 index controller
    describe { "input.loadADirX (pad {controller + 1})" }
        test "returns 0 if left or right aren't pressed"
            test.input.mockController controller, zest.NO_INPUT
            zest.initRegisters

            input.loadADirX

            expect.all.toBeUnclobberedExcept "af"
            expect.a.toBe 0

        test "returns -1 if left is pressed"
            test.input.mockController controller, zest.LEFT
            zest.initRegisters

            input.loadADirX

            expect.all.toBeUnclobberedExcept "af"
            expect.a.toBe -1

        test "returns 1 if right is pressed"
            test.input.mockController controller, zest.RIGHT
            zest.initRegisters

            input.loadADirX

            expect.all.toBeUnclobberedExcept "af"
            expect.a.toBe 1

.redefine utils.registers.AUTO_PRESERVE 0
