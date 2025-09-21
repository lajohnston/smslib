.redefine utils.registers.AUTO_PRESERVE 1

.repeat 2 index controller
    describe { "input.loadDirY (pad {controller + 1}) with A register" }
        test "returns 0 if up or down aren't pressed"
            test.input.mockController controller, zest.NO_INPUT
            zest.initRegisters

            input.loadDirY "a"

            expect.all.toBeUnclobberedExcept "af"
            expect.a.toBe 0

        test "returns a negative value if up is pressed"
            test.input.mockController controller, zest.UP
            zest.initRegisters

            input.loadDirY "a", 5

            expect.all.toBeUnclobberedExcept "af"
            expect.a.toBe -5

        test "returns a positive value if down is pressed"
            test.input.mockController controller, zest.DOWN
            zest.initRegisters

            input.loadDirY "a", 8

            expect.all.toBeUnclobberedExcept "af"
            expect.a.toBe 8

    describe { "input.loadDirY (pad {controller + 1}) with other registers" }
        test "loads the register with 0 if up or down aren't pressed"
            test.input.mockController controller, zest.NO_INPUT
            zest.initRegisters

            input.loadDirY "b"

            expect.all.toBeUnclobberedExcept "b"
            expect.b.toBe 0

        test "returns a negative value if up is pressed"
            test.input.mockController controller, zest.UP
            zest.initRegisters

            input.loadDirY "de"

            expect.all.toBeUnclobberedExcept "de"
            expect.de.toBe -1

        test "returns a positive value if down is pressed"
            test.input.mockController controller, zest.DOWN
            zest.initRegisters

            input.loadDirY "hl"

            expect.all.toBeUnclobberedExcept "hl"
            expect.hl.toBe 1

.redefine utils.registers.AUTO_PRESERVE 0
