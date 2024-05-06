describe "register preservation: sequential (unnested) clobber scopes"
    test "the second scope shouldn't preserve the same registers"
        ld bc, $bc00

        ; Preserve scope
        registers.preserve "BC"
            ; First clobber scope clobbers BC
            registers.clobbers "BC"
                expect.stack.size.toBe 1
                expect.stack.toContain $bc00
                ld bc, $bc01
            registers.clobberEnd

            ; Second clobber scope also clobbers BC, but shouldn't push to stack again
            registers.clobbers "BC"
                expect.stack.size.toBe 1 "Expected stack size to still be 1"
                expect.stack.toContain $bc00 0 "Expected stack to still contain original BC value"
                ld bc, $bc02
            registers.clobberEnd
        registers.restore

        expect.bc.toBe $bc00

    test "the second scope should preserve the registers the first hasn't"
        ld bc, $bc00
        ld de, $de00

        ; Preserve scope preserves BC and DE
        registers.preserve "BC" "DE"
            ; First clobber scope clobbers DE
            registers.clobbers "DE"
                expect.stack.toContain $de00
                ld de, $de01
            registers.clobberEnd

            ; Second clobber scope clobbers BC
            registers.clobbers "BC"
                expect.stack.toContain $bc00
                ld bc, $bc02
            registers.clobberEnd
        registers.restore

        expect.bc.toBe $bc00
        expect.de.toBe $de00
