describe "utils.vram._isActiveDisplay"
    it "returns 0 when ACTIVE_DISPLAY is not enabled"
        .redefine utils.vram.ACTIVE_DISPLAY 0
        utils.vram._isActiveDisplay

        ld a, utils.vram._isActiveDisplay.returnValue
        expect.a.toBe 0

    it "returns 1 when ACTIVE_DISPLAY is enabled"
        .redefine utils.vram.ACTIVE_DISPLAY 1
        utils.vram._isActiveDisplay

        ld a, utils.vram._isActiveDisplay.returnValue
        expect.a.toBe 1

describe "utils.vram._isActiveDisplay with ACTIVE_DISPLAY_NEXT"
    it "can override ACTIVE_DISPLAY to 0, only for the first call"
        .redefine utils.vram.ACTIVE_DISPLAY 1
        .redefine utils.vram.ACTIVE_DISPLAY_NEXT 0

        utils.vram._isActiveDisplay
        ld a, utils.vram._isActiveDisplay.returnValue
        expect.a.toBe 0 "Expected value to be overridden to 0"

        utils.vram._isActiveDisplay
        ld a, utils.vram._isActiveDisplay.returnValue
        expect.a.toBe 1 "Expected value to be back to 1"

    it "can override ACTIVE_DISPLAY to 1, only for the first call"
        .redefine utils.vram.ACTIVE_DISPLAY 0
        .redefine utils.vram.ACTIVE_DISPLAY_NEXT 1

        utils.vram._isActiveDisplay
        ld a, utils.vram._isActiveDisplay.returnValue
        expect.a.toBe 1 "Expected value to be overridden to 1"

        utils.vram._isActiveDisplay
        ld a, utils.vram._isActiveDisplay.returnValue
        expect.a.toBe 0 "Expected value to be back to 0"
