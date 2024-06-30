describe "tilemap.writeScrollBuffers"
    tilemap.reset

    ; Dummy tile data
    jp +
        -:
            .dsb 31 * 2, $00
    +:

    ; Initialise column buffer
    tilemap.loadDEColBuffer
    tilemap.loadBCColBytes
    ld hl, -    ; point to data
    ldir        ; write data

    ; Initialise row buffer
    tilemap.loadDERowBuffer
    tilemap.loadBCRowBytes
    ld hl, -    ; point to data
    ldir        ; write data

    it "preserves the registers when no scroll needed"
        zest.initRegisters

        utils.preserve
            tilemap.writeScrollBuffers
        utils.restore

        expect.all.toBeUnclobbered

    it "preserves the registers when left scroll needed"
        tilemap.reset
        ld a, -8
        tilemap.adjustXPixels
        tilemap.calculateScroll

        zest.initRegisters

        utils.preserve
            tilemap.writeScrollBuffers
        utils.restore

        expect.all.toBeUnclobbered

    it "preserves the registers when right scroll needed"
        tilemap.reset
        ld a, 8
        tilemap.adjustXPixels
        tilemap.calculateScroll

        zest.initRegisters

        utils.preserve
            tilemap.writeScrollBuffers
        utils.restore

        expect.all.toBeUnclobbered

    it "preserves the registers when up scroll needed"
        tilemap.reset
        ld a, -8
        tilemap.adjustYPixels
        tilemap.calculateScroll

        zest.initRegisters

        utils.preserve
            tilemap.writeScrollBuffers
        utils.restore

        expect.all.toBeUnclobbered

    it "preserves the registers when down scroll needed"
        tilemap.reset
        ld a, 8
        tilemap.adjustYPixels
        tilemap.calculateScroll

        zest.initRegisters

        utils.preserve
            tilemap.writeScrollBuffers
        utils.restore

        expect.all.toBeUnclobbered
