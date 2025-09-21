.redefine utils.registers.AUTO_PRESERVE 1

.repeat 2 index controller
    describe { "input.loadDirX (pad {controller + 1}) with A register" }
        test "returns 0 if left or right aren't pressed"
            test.input.mockController controller, zest.NO_INPUT
            zest.initRegisters

            input.loadDirX "a"

            expect.all.toBeUnclobberedExcept "af"
            expect.a.toBe 0

        test "returns a negative value if left is pressed"
            test.input.mockController controller, zest.LEFT
            zest.initRegisters

            input.loadDirX "a", 5

            expect.all.toBeUnclobberedExcept "af"
            expect.a.toBe -5

        test "returns a positive value if right is pressed"
            test.input.mockController controller, zest.RIGHT
            zest.initRegisters

            input.loadDirX "a", 8

            expect.all.toBeUnclobberedExcept "af"
            expect.a.toBe 8

    describe { "input.loadDirX (pad {controller + 1}) with other registers" }
        test "loads the register with 0 if left or right aren't pressed"
            test.input.mockController controller, zest.NO_INPUT
            zest.initRegisters

            input.loadDirX "b"

            expect.all.toBeUnclobberedExcept "b"
            expect.b.toBe 0

        test "returns a negative value if left is pressed"
            test.input.mockController controller, zest.LEFT
            zest.initRegisters

            input.loadDirX "de"

            expect.all.toBeUnclobberedExcept "de"
            expect.de.toBe -1

        test "returns a positive value if right is pressed"
            test.input.mockController controller, zest.RIGHT
            zest.initRegisters

            input.loadDirX "hl"

            expect.all.toBeUnclobberedExcept "hl"
            expect.hl.toBe 1

.redefine utils.registers.AUTO_PRESERVE 0
