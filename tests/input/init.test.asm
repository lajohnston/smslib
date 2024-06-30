describe "input.init (with port 2 disabled)"
    .undefine input.ENABLE_PORT_2

    test "preserves registers"
        zest.initRegisters

        utils.preserve
            input.init
        utils.restore

        expect.all.toBeUnclobbered

describe "input.init (with port 2 enabled)"
    .define input.ENABLE_PORT_2

    test "preserves registers"
        zest.initRegisters

        utils.preserve
            input.init
        utils.restore

        expect.all.toBeUnclobbered
