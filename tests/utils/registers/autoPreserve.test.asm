describe "automatic register preservation"
    ; Activate AUTO_PRESERVE
    .redefine utils.registers.AUTO_PRESERVE 1

    test "preserves all clobbered registers"
        zest.initRegisters

        utils.registers.clobbers "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'", "hl'"
            call suite.registers.clobberAll
        utils.registers.clobberEnd

        expect.all.toBeUnclobbered

    test "only preserves clobbered registers"
        ld bc, $bc01
        ld de, $de01

        utils.registers.clobbers "bc"
            expect.stack.size.toBe 1
            expect.stack.toContain $bc01
        utils.registers.clobberEnd

        utils.registers.clobbers "bc" "de"
            expect.stack.size.toBe 2
            expect.stack.toContain $de01
            expect.stack.toContain $bc01 1
        utils.registers.clobberEnd

    test "only preserves registers once if there are nested preserve scopes"
        utils.registers.clobbers "af"
            expect.stack.size.toBe 1

            utils.registers.clobbers "af"
                expect.stack.size.toBe 1 "Expected stack size to still be 1"
            utils.registers.clobberEnd
        utils.registers.clobberEnd

    test "does not override existing preserve scopes"
        ld bc, $bc00

        ; Preserve scope already exists - this should not be overridden
        utils.registers.preserve "bc"
            ; Clobber scope clobbers all registers
            utils.registers.clobbers "af", "bc", "de", "hl", "ix", "iy", "i", "af'", "bc'", "de'", "hl'"
                ; Only BC should have been preserved
                expect.stack.size.toBe 1
                expect.stack.toContain $bc00
            utils.registers.clobberEnd
        utils.restore

        expect.bc.toBe $bc00
