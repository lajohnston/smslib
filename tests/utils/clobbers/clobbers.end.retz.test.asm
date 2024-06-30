describe "utils.clobbers.end.retc"
    .redefine utils.registers.AUTO_PRESERVE 1

    test "does not restore or return when carry is reset"
        zest.initRegisters
        call +
        zest.fail "Routine returned"

        +:
        utils.clobbers.withBranching utils.registers.ALL
            ; Set registers to 0
            call suite.registers.setAllToZero
            or a    ; reset carry

            ; Call macro
            utils.clobbers.end.retc

            ; Expect everything to still be zero
            call suite.registers.expectAllToBeZero
        utils.clobbers.end

    test "restores and returns when carry is set"
        zest.initRegisters

        utils.preserve utils.registers.ALL
            jp +
                -:
                utils.clobbers.withBranching utils.registers.ALL
                    ; Set registers to 0; Reset flags
                    call suite.registers.setAllToZero
                    scf ; set carry

                    ; Call macro
                    utils.clobbers.end.retc
                    zest.fail "Routine did not return"
                utils.clobbers.end
            +:

            call -
            expect.all.toBeUnclobbered
        utils.restore

describe "utils.clobbers.end.retc with nothing to restore"
    .redefine utils.registers.AUTO_PRESERVE 0

    test "does not restore or return when carry is reset"
        zest.initRegisters
        call +
        zest.fail "Routine returned"

        +:
        utils.clobbers.withBranching utils.registers.ALL
            ; Set registers to 0
            call suite.registers.setAllToZero
            or a    ; reset carry

            ; Call macro
            utils.clobbers.end.retc

            ; Expect everything to still be zero
            call suite.registers.expectAllToBeZero
        utils.clobbers.end

    test "restores and returns when carry is set"
        zest.initRegisters

        utils.preserve utils.registers.ALL
            jp +
                -:
                utils.clobbers.withBranching utils.registers.ALL
                    ; Set registers to 0; Reset flags
                    call suite.registers.setAllToZero
                    scf ; set carry

                    ; Call macro
                    utils.clobbers.end.retc
                    zest.fail "Routine did not return"
                utils.clobbers.end
            +:

            call -
            expect.all.toBeUnclobbered
        utils.restore
