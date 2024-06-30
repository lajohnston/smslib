describe "utils.clobbers.end.retpe"
    .redefine utils.registers.AUTO_PRESERVE 1

    test "does not restore or return when parity/overflow is reset"
        zest.initRegisters
        call +
        zest.fail "Routine returned"

        +:
        utils.clobbers.withBranching utils.registers.ALL
            ; Set registers to 0 (inc flags)
            call suite.registers.setAllToZero

            ; Call macro
            utils.clobbers.end.retpe

            ; Expect everything to still be zero
            call suite.registers.expectAllToBeZero
        utils.clobbers.end

    test "restores and returns when parity/overflow is set"
        zest.initRegisters

        utils.preserve utils.registers.ALL
            jp +
                -:
                utils.clobbers.withBranching utils.registers.ALL
                    ; Set registers to 0; Reset flags
                    call suite.registers.setAllToZero
                    or a ; set parity/overflow

                    ; Call macro
                    utils.clobbers.end.retpe
                    zest.fail "Routine did not return"
                utils.clobbers.end
            +:

            call -
            expect.all.toBeUnclobbered
        utils.restore

describe "utils.clobbers.end.retpe with nothing to restore"
    .redefine utils.registers.AUTO_PRESERVE 0

    test "does not restore or return when parity/overflow is reset"
        zest.initRegisters
        call +
        zest.fail "Routine returned"

        +:
        utils.clobbers.withBranching utils.registers.ALL
            ; Set registers to 0 inc flags
            call suite.registers.setAllToZero

            ; Call macro
            utils.clobbers.end.retpe

            ; Expect everything to still be zero
            call suite.registers.expectAllToBeZero
        utils.clobbers.end

    test "restores and returns when parity/overflow is set"
        zest.initRegisters

        utils.preserve utils.registers.ALL
            jp +
                -:
                utils.clobbers.withBranching utils.registers.ALL
                    ; Set registers to 0; Reset flags
                    call suite.registers.setAllToZero
                    or a    ; set parity/overflow

                    ; Call macro
                    utils.clobbers.end.retpe
                    zest.fail "Routine did not return"
                utils.clobbers.end
            +:

            call -
            expect.all.toBeUnclobbered
        utils.restore
