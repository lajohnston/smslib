describe "automatic register preservation"
    ; Activate AUTO_PRESERVE
    .redefine registers.AUTO_PRESERVE 1

    test "preserves all clobbered registers"
        zest.initRegisters

        registers.clobbers "af" "bc" "de" "hl" "ix" "iy" "i" "af'" "bc'" "de'", "hl'"
            call suite.registers.clobberAll
        registers.clobberEnd

        expect.all.toBeUnclobbered

    test "only preserves clobbered registers"
        ld bc, $bc01
        ld de, $de01

        registers.clobbers "bc"
            expect.stack.size.toBe 1
            expect.stack.toContain $bc01
        registers.clobberEnd

        registers.clobbers "bc" "de"
            expect.stack.size.toBe 2
            expect.stack.toContain $de01
            expect.stack.toContain $bc01 1
        registers.clobberEnd

    test "only preserves registers once if there are nested preserve scopes"
        registers.clobbers "af"
            expect.stack.size.toBe 1

            registers.clobbers "af"
                expect.stack.size.toBe 1 "Expected stack size to still be 1"
            registers.clobberEnd
        registers.clobberEnd

    test "does not override existing preserve scopes"
        ld bc, $bc00

        ; Preserve scope already exists - this should not be overridden
        registers.preserve "bc"
            ; Clobber scope clobbers all registers
            registers.clobbers "af", "bc", "de", "hl", "ix", "iy", "i", "af'", "bc'", "de'", "hl'"
                ; Only BC should have been preserved
                expect.stack.size.toBe 1
                expect.stack.toContain $bc00
            registers.clobberEnd
        registers.restore

        expect.bc.toBe $bc00
