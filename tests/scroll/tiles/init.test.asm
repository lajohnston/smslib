describe "scroll/tiles init"

test "does not clobber registers when no macro args given"
    zest.initRegisters

    utils.preserve
        ld a, 0     ; mapCols
        ld b, 0     ; mapRows
        ld d, 0     ; colOffset
        ld e, 0     ; rowOffset
        ld hl, 0    ; topLeftPointer
        scroll.tiles.init
    utils.restore

    expect.all.toBeUnclobberedExcept "a", "b", "d", "e", "h", "l"
    expect.a.toBe 0
    expect.b.toBe 0
    expect.de.toBe 0
    expect.hl.toBe 0


test "does not clobber registers when macro args are given"
    zest.initRegisters

    utils.preserve
        scroll.tiles.init 0 64 64 0 0
    utils.restore

    expect.all.toBeUnclobbered
