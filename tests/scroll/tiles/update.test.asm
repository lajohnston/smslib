describe "scroll.tiles.update does not clobber registers when:"

test "no row or col scroll needed"
    ; Setup
    scroll.tiles.init 0 64 64 0 0
    xor a
    scroll.tiles.adjustXPixels
    xor a
    scroll.tiles.adjustYPixels

    zest.initRegisters

    utils.preserve
        scroll.tiles.update
    utils.restore

    expect.all.toBeUnclobbered

test "row scroll needed"
    ; Setup
    scroll.tiles.init 0 64 64 0 0
    xor a
    scroll.tiles.adjustXPixels
    ld a, 8
    scroll.tiles.adjustYPixels

    zest.initRegisters

    utils.preserve
        scroll.tiles.update
    utils.restore

    expect.all.toBeUnclobbered

test "col scroll needed"
    ; Setup
    scroll.tiles.init 0 64 64 0 0
    ld a, 8
    scroll.tiles.adjustXPixels
    xor a
    scroll.tiles.adjustYPixels

    zest.initRegisters

    utils.preserve
        scroll.tiles.update
    utils.restore

    expect.all.toBeUnclobbered
