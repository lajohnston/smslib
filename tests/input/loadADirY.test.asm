.redefine utils.registers.AUTO_PRESERVE 1

.repeat 2 index controller
    describe { "input.loadADirY (pad {controller + 1})" }
        test "returns 0 if up or down aren't pressed"
            test.input.mockController controller, zest.NO_INPUT
            zest.initRegisters

            input.loadADirY

            expect.all.toBeUnclobberedExcept "af"
            expect.a.toBe 0

        test "returns -1 if up is pressed"
            test.input.mockController controller, zest.UP
            zest.initRegisters

            input.loadADirY

            expect.all.toBeUnclobberedExcept "af"
            expect.a.toBe -1

        test "returns 1 if down is pressed"
            test.input.mockController controller, zest.DOWN
            zest.initRegisters

            input.loadADirY

            expect.all.toBeUnclobberedExcept "af"
            expect.a.toBe 1

.redefine utils.registers.AUTO_PRESERVE 0
