describe "utils.clobbers.end.jpm"
    test "does not jump or restore when sign is reset"
        ; Set all registers to $FF
        ld a, $ff
        call suite.registers.setAllToA

        utils.preserve "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
            utils.clobbers.withBranching "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
                ; Set all registers to zero
                call suite.registers.setAllToZero
                call suite.registers.resetAllFlags  ; reset sign

                ; This shouldn't jump
                utils.clobbers.end.jpm suite.registers.unexpectedJump

                ; Expect everything to still be zero
                call suite.registers.expectAllToBeZero
            utils.clobbers.end
        utils.restore

    test "restores and jumps when sign is set"
        zest.initRegisters

        utils.preserve "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
            utils.clobbers.withBranching "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'" "hl'"
                ; Zero registers
                call suite.registers.setAllToZero
                call suite.registers.setAllFlags    ; set sign flag

                ; Expect this to jump
                utils.clobbers.end.jpm +
                zest.fail "Did not jump"
            utils.clobbers.end

            +:
            expect.all.toBeUnclobbered
            expect.stack.size.toBe 0
        utils.restore

describe "utils.clobbers.end.jpm with nothing to restore"
    test "does not jump or restore when sign is reset"
        zest.initRegisters

        utils.preserve "hl"
            ; Doesn't clobber scope doesn't affect HL - nothing to preserve
            utils.clobbers.withBranching "af"
                ; Set all registers to zero
                call suite.registers.setAllToZero
                call suite.registers.resetAllFlags  ; set sign

                ; This shouldn't jump
                utils.clobbers.end.jpm suite.registers.unexpectedJump

                ; Expect everything to still be zero
                call suite.registers.expectAllToBeZero
            utils.clobbers.end

            expect.stack.size.toBe 0
        utils.restore

    test "jumps but doesn't restore when sign is set"
        zest.initRegisters

        utils.preserve "hl"
            ; Doesn't clobber scope doesn't affect HL - nothing to preserve
            utils.clobbers.withBranching "af"
                ; Set all registers to zero
                call suite.registers.setAllToZero
                call suite.registers.setAllFlags

                ; Expect this to jump
                utils.clobbers.end.jpm +
                zest.fail "Did not jump"
            utils.clobbers.end

            +:
            ; Expect values to still be zero
            call suite.registers.expectAllToBeZero
            expect.stack.size.toBe 0
        utils.restore
