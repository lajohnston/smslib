describe "register preservation: sequential (unnested) clobber scopes"
    test "the second scope shouldn't preserve the same registers"
        ld bc, $bc00

        ; Preserve scope
       utils.preserve "bc"
            ; First clobber scope clobbers BC
           utils.clobbers "bc"
                expect.stack.size.toBe 1
                expect.stack.toContain $bc00
                ld bc, $bc01
           utils.clobbers.end

            ; Second clobber scope also clobbers BC, but shouldn't push to stack again
           utils.clobbers "bc"
                expect.stack.size.toBe 1 "Expected stack size to still be 1"
                expect.stack.toContain $bc00 0 "Expected stack to still contain original BC value"
                ld bc, $bc02
           utils.clobbers.end
       utils.restore

        expect.bc.toBe $bc00

    test "the second scope should preserve the registers the first hasn't"
        ld bc, $bc00
        ld de, $de00

        ; Preserve scope preserves BC and DE
       utils.preserve "bc" "de"
            ; First clobber scope clobbers DE
           utils.clobbers "de"
                expect.stack.toContain $de00
                ld de, $de01
           utils.clobbers.end

            ; Second clobber scope clobbers BC
           utils.clobbers "bc"
                expect.stack.toContain $bc00
                ld bc, $bc02
           utils.clobbers.end
       utils.restore

        expect.bc.toBe $bc00
        expect.de.toBe $de00

    test "restores the correct registers (random order)"
        zest.initRegisters

       utils.preserve "af", "bc", "de", "hl", "ix", "iy", "i", "af'", "bc'", "de'", "hl'"
           utils.clobbers "hl"
                ld h, a
                ld l, a
           utils.clobbers.end

           utils.clobbers "ix", "bc"
                ld b, a
                ld c, a
                ld ixh, a
                ld ixl, a
           utils.clobbers.end
       utils.restore

        expect.all.toBeUnclobbered