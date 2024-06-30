describe "utils.clobbers.endBranch"
    test "restores protected registers that are being clobbered"
        zest.initRegisters

        utils.preserve "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
            utils.clobbers.withBranching "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
                call suite.registers.clobberAll

                utils.clobbers.endBranch

                expect.all.toBeUnclobbered

                jp +
            utils.clobbers.end

            +:
        utils.restore

    test "only restores the protected registers"
        ld bc, $bc01

        utils.preserve "bc"
            utils.clobbers.withBranching "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
                ; Zero all registers
                call suite.registers.setAllToZero

                utils.clobbers.endBranch

                ; Expect BC to be restored
                expect.bc.toBe $bc01

                ; Expect the rest to be 0
                expect.a.toBe 0
                expect.de.toBe 0
                expect.hl.toBe 0
                expect.ix.toBe 0
                expect.iy.toBe 0
                expect.i.toBe 0

                ex af, af'
                exx

                expect.a.toBe 0
                expect.bc.toBe 0
                expect.de.toBe 0
                expect.hl.toBe 0

                jp +
            utils.clobbers.end

            +:
        utils.restore
