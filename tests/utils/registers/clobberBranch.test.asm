describe "utils.clobbers.withBranching"
    test "preserves the registers it clobbers"
        zest.initRegisters

        utils.preserve
            utils.clobbers.withBranching "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'", "hl'"
                call suite.registers.clobberAll
            utils.clobbers.end
        utils.restore

        expect.all.toBeUnclobbered

    test "doesn't preserve registers that aren't marked for preservation"
        utils.preserve "af"
            utils.clobbers.withBranching "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'", "hl'"
                expect.stack.size.toBe 1
            utils.clobbers.end
        utils.restore

    test "doesn't preserve registers that aren't marked as clobbered"
        utils.preserve "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'", "hl'"
            utils.clobbers.withBranching "af"
                expect.stack.size.toBe 1
            utils.clobbers.end
        utils.restore

    test "preserves registers even if a previous sibling has already done so"
        ld bc, $bc00
        ld de, $de00

        utils.preserve "bc"
            utils.clobbers.withBranching "bc"
                expect.stack.size.toBe 1
                expect.stack.toContain $bc00
                ld bc, $bc01
            utils.clobbers.end

            utils.clobbers.withBranching "bc"
                expect.stack.size.toBe 2
                expect.stack.toContain $bc01
            utils.clobbers.end
        utils.restore

        expect.stack.size.toBe 0
        expect.bc.toBe $bc00

    test "preserves registers even if an ancestor has done so"
        ld bc, $bc00
        ld de, $de00

        utils.preserve "bc"
            utils.clobbers.withBranching "bc"
                expect.stack.size.toBe 1
                expect.stack.toContain $bc00
                ld bc, $bc01

                utils.clobbers.withBranching "bc"
                    expect.stack.size.toBe 2
                    expect.stack.toContain $bc01
                utils.clobbers.end
            utils.clobbers.end
        utils.restore

        expect.stack.size.toBe 0
        expect.bc.toBe $bc00
