describe "scroll/metatiles init"

test "does not clobber registers"
    zest.initRegisters

    utils.preserve
        ld a, 64    ; the map's width in metatiles
        ld b, 0     ; the column offset in metatiles
        ld c, 0     ; the row offset in metatiles
        ld d, 64    ; the map's height in metatiles
        scroll.metatiles.init
    utils.restore

    expect.all.toBeUnclobberedExcept "a", "b", "c", "d"
    expect.a.toBe 64
    expect.b.toBe 0
    expect.c.toBe 0
    expect.d.toBe 64
