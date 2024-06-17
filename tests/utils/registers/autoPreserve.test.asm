describe "automatic register preservation"
    ; Activate AUTO_PRESERVE
    .redefine utils.registers.AUTO_PRESERVE 1

    test "preserves all clobbered registers"
        zest.initRegisters

        utils.clobbers "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'", "hl'"
            call suite.registers.clobberAll
        utils.clobbers.end

        expect.all.toBeUnclobbered

    test "only preserves clobbered registers"
        ld bc, $bc01
        ld de, $de01

        utils.clobbers "bc"
            expect.stack.size.toBe 1
            expect.stack.toContain $bc01
        utils.clobbers.end

        utils.clobbers "bc" "de"
            expect.stack.size.toBe 2
            expect.stack.toContain $de01
            expect.stack.toContain $bc01 1
        utils.clobbers.end

    test "only preserves registers once if there are nested preserve scopes"
        utils.clobbers "af"
            expect.stack.size.toBe 1

            utils.clobbers "af"
                expect.stack.size.toBe 1 "Expected stack size to still be 1"
            utils.clobbers.end
        utils.clobbers.end

    test "does not override existing preserve scopes"
        ld bc, $bc00

        ; Preserve scope already exists - this should not be overridden
        utils.registers.preserve "bc"
            ; Clobber scope clobbers all registers
            utils.clobbers "af", "bc", "de", "hl", "ix", "iy", "i", "af'", "bc'", "de'", "hl'"
                ; Only BC should have been preserved
                expect.stack.size.toBe 1
                expect.stack.toContain $bc00
            utils.clobbers.end
        utils.restore

        expect.bc.toBe $bc00
