describe "scroll.metatiles.render does not clobber registers when:"

test "no row or col scroll needed"
    ; Setup
    call tests.scroll.metatiles.init
    xor a
    scroll.metatiles.adjustXPixels
    xor a
    scroll.metatiles.adjustYPixels
    scroll.metatiles.update

    zest.initRegisters

    utils.preserve
        scroll.metatiles.render
    utils.restore

    expect.all.toBeUnclobbered

test "row scroll needed"
    ; Setup
    call tests.scroll.metatiles.init
    xor a
    scroll.metatiles.adjustXPixels
    ld a, 8
    scroll.metatiles.adjustYPixels
    scroll.metatiles.update

    zest.initRegisters

    utils.preserve
        scroll.metatiles.render
    utils.restore

    expect.all.toBeUnclobbered

test "col scroll needed"
    ; Setup
    call tests.scroll.metatiles.init
    ld a, 8
    scroll.metatiles.adjustXPixels
    xor a
    scroll.metatiles.adjustYPixels
    scroll.metatiles.update

    zest.initRegisters

    utils.preserve
        scroll.metatiles.render
    utils.restore

    expect.all.toBeUnclobbered
