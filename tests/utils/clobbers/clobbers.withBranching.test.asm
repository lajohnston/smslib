describe "utils.clobbers.withBranching"
    test "preserves the registers it clobbers"
        zest.initRegisters

        utils.preserve
            utils.clobbers.withBranching "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'", "hl'"
                call suite.registers.clobberAll
            utils.clobbers.end

            expect.all.toBeUnclobbered
        utils.restore

    test "doesn't preserve registers that aren't marked for preservation"
        utils.preserve "af"
            utils.clobbers.withBranching "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'", "hl'"
                expect.stack.size.toBe 1
            utils.clobbers.end
        utils.restore

    test "doesn't preserve any registers if no preserve scopes are in progress"
        utils.clobbers.withBranching "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'", "hl'"
            expect.stack.size.toBe 0
        utils.clobbers.end

    test "doesn't preserve registers that aren't marked as clobbered"
        utils.preserve "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'", "hl'"
            utils.clobbers.withBranching "af"
                expect.stack.size.toBe 1
            utils.clobbers.end
        utils.restore

    test "preserves registers even if a previous withBranching scope has already done so"
        ld bc, $bc00
        ld de, $de00

        utils.preserve "bc"
            utils.clobbers.withBranching "bc"
                expect.stack.size.toBe 1
                ld bc, $bc02
            utils.clobbers.end

            utils.clobbers.withBranching "bc"
                expect.stack.size.toBe 1
                ld bc, $bc02
            utils.clobbers.end
        utils.restore

        expect.stack.size.toBe 0
        expect.bc.toBe $bc00

    test "preserves registers even if a previous clobbers scope has already done so"
        ld bc, $bc00
        ld de, $de00

        utils.preserve "bc"
            utils.clobbers "bc"
                ld bc, $bc01
            utils.clobbers.end

            utils.clobbers.withBranching "bc"
                expect.stack.size.toBe 2
                ld bc, $bc02
            utils.clobbers.end

            expect.stack.size.toBe 1
            expect.bc.toBe $bc01
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

    test "endBranch restores the registers without closing the clobber scope"
        zest.initRegisters

        utils.preserve "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
            utils.clobbers.withBranching "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
                call suite.registers.clobberAll

                utils.clobbers.endBranch

                expect.all.toBeUnclobbered
                expect.stack.size.toBe 0

                ld a, utils.clobbers.index
                expect.a.toBe 0 "Expected clobber scope to remain in progress"
            utils.clobbers.closeBranch
        utils.restore

    test "closeBranch ends the clobber scope without restoring the registers"
        zest.initRegisters

        utils.preserve "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
            utils.clobbers.withBranching "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
                call suite.registers.setAllToZero
            utils.clobbers.closeBranch

            ; Expect nothing to have been restored
            call suite.registers.expectAllToBeZero

            ; Expect clobber scope to have been closed
            ld a, utils.clobbers.index
            expect.a.toBe -1 "Expected no clobber scopes to be in progress"
        utils.restore