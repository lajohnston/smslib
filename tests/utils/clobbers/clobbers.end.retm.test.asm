describe "utils.clobbers.end.retm"
    .redefine utils.registers.AUTO_PRESERVE 1

    test "does not restore or return when sign is reset"
        zest.initRegisters
        call +
        zest.fail "Routine returned"

        +:
        utils.clobbers.withBranching utils.registers.ALL
            ; Set registers to 0 (including flags)
            call suite.registers.setAllToZero

            ; Call macro
            utils.clobbers.end.retm

            ; Expect everything to still be zero
            call suite.registers.expectAllToBeZero
        utils.clobbers.end

    test "restores and returns when sign is set"
        zest.initRegisters

        utils.preserve utils.registers.ALL
            jp +
                -:
                utils.clobbers.withBranching utils.registers.ALL
                    ; Set registers to 0; Reset flags
                    call suite.registers.setAllToZero
                    dec a
                    or a ; set sign

                    ; Call macro
                    utils.clobbers.end.retm
                    zest.fail "Routine did not return"
                utils.clobbers.end
            +:

            call -
            expect.all.toBeUnclobbered
        utils.restore

describe "utils.clobbers.end.retm with nothing to restore"
    .redefine utils.registers.AUTO_PRESERVE 0

    test "does not restore or return when sign is reset"
        zest.initRegisters
        call +
        zest.fail "Routine returned"

        +:
        utils.clobbers.withBranching utils.registers.ALL
            ; Set registers to 0 including flags
            call suite.registers.setAllToZero

            ; Call macro
            utils.clobbers.end.retm

            ; Expect everything to still be zero
            call suite.registers.expectAllToBeZero
        utils.clobbers.end

    test "restores and returns when sign is set"
        zest.initRegisters

        utils.preserve utils.registers.ALL
            jp +
                -:
                utils.clobbers.withBranching utils.registers.ALL
                    ; Set registers to 0; Reset flags
                    call suite.registers.setAllToZero
                    dec a
                    or a    ; set sign

                    ; Call macro
                    utils.clobbers.end.retm
                    zest.fail "Routine did not return"
                utils.clobbers.end
            +:

            call -
            expect.all.toBeUnclobbered
        utils.restore
