describe "tilemap.writeScrollRegisters"
    tilemap.reset

    it "preserves the registers"
        zest.initRegisters

        utils.preserve
            tilemap.writeScrollRegisters
        utils.restore

        expect.all.toBeUnclobbered