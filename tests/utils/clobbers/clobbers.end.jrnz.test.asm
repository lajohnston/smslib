describe "utils.clobbers.end.jrnz"
    test "when Z - does not jump or restore"
        jr +
            -:
            zest.fail "Unexpected jump"
        +:

        ; Set all registers to $FF
        ld a, $ff
        call suite.registers.setAllToA

        utils.preserve "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
            utils.clobbers.withBranching "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
                ; Set all registers to zero
                call suite.registers.setAllToZero
                call suite.registers.setAllFlags  ; set Z

                ; This shouldn't jump
                utils.clobbers.end.jrnz -

                ; Expect everything to still be zero
                call suite.registers.expectAllToBeZero
            utils.clobbers.end
        utils.restore

    test "when NZ - restores and jumps"
        zest.initRegisters

        utils.preserve "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
            utils.clobbers.withBranching "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
                ; Zero registers but reset Z flag
                call suite.registers.setAllToZero
                call suite.registers.resetAllFlags

                ; Expect this to jump
                utils.clobbers.end.jrnz +
                zest.fail "Did not jump"
            utils.clobbers.end

            +:
            expect.all.toBeUnclobbered
        utils.restore

describe "utils.clobbers.end.jrnz with nothing to restore"
    test "when Z - does not jump or restore"
        jr +
            -:
            zest.fail "Unexpected jump"
        +:

        zest.initRegisters

        utils.preserve "hl"
            ; Doesn't clobber scope doesn't affect HL - nothing to preserve
            utils.clobbers.withBranching "af"
                ; Set all registers to zero
                call suite.registers.setAllToZero
                call suite.registers.setAllFlags

                ; This shouldn't jump
                utils.clobbers.end.jrnz -

                ; Expect everything to still be zero
                call suite.registers.expectAllToBeZero
            utils.clobbers.end
        utils.restore

    test "when NZ - jumps but doesn't restore"
        zest.initRegisters

        utils.preserve "hl"
            ; Doesn't clobber scope doesn't affect HL - nothing to preserve
            utils.clobbers.withBranching "af"
                ; Set all registers to zero, but set Z flag
                call suite.registers.setAllToZero
                call suite.registers.resetAllFlags

                ; Expect this to jump
                utils.clobbers.end.jrnz +
                zest.fail "Did not jump"
            utils.clobbers.end

            +:
            ; Expect values to still be zero
            call suite.registers.expectAllToBeZero
        utils.restore
