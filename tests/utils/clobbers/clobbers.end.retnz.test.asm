describe "utils.clobbers.end.retnz"
    .redefine utils.registers.AUTO_PRESERVE 1

    test "does not restore or return when zero is set"
        zest.initRegisters
        call +
        zest.fail "Routine returned"

        +:
        utils.clobbers.withBranching utils.registers.ALL
            ; Set registers to 0
            call suite.registers.setAllToZero
            or a    ; set zero

            ; Call macro
            utils.clobbers.end.retnz

            ; Expect everything to still be zero
            call suite.registers.expectAllToBeZero
        utils.clobbers.end

    test "restores and returns when zero is reset"
        zest.initRegisters

        utils.preserve utils.registers.ALL
            jp +
                -:
                utils.clobbers.withBranching utils.registers.ALL
                    ; Set registers to 0; Reset flags
                    call suite.registers.setAllToZero
                    inc a
                    or a    ; reset zero

                    ; Call macro
                    utils.clobbers.end.retnz
                    zest.fail "Routine did not return"
                utils.clobbers.end
            +:

            call -
            expect.all.toBeUnclobbered
        utils.restore

describe "utils.clobbers.end.retnz with nothing to restore"
    .redefine utils.registers.AUTO_PRESERVE 0

    test "does not restore or return when zero is set"
        zest.initRegisters
        call +
        zest.fail "Routine returned"

        +:
        utils.clobbers.withBranching utils.registers.ALL
            ; Set registers to 0
            call suite.registers.setAllToZero
            or a    ; set zero

            ; Call macro
            utils.clobbers.end.retnz

            ; Expect everything to still be zero
            call suite.registers.expectAllToBeZero
        utils.clobbers.end

    test "restores and returns when zero is reset"
        zest.initRegisters

        utils.preserve utils.registers.ALL
            jp +
                -:
                utils.clobbers.withBranching utils.registers.ALL
                    ; Set registers to 0; Reset flags
                    call suite.registers.setAllToZero
                    inc a
                    or a    ; reset zero

                    ; Call macro
                    utils.clobbers.end.retnz
                    zest.fail "Routine did not return"
                utils.clobbers.end
            +:

            call -
            expect.all.toBeUnclobbered
        utils.restore
