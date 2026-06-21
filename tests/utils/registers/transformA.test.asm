describe "utils.registers.transformA"
    test "transform A to the expected value"
        ; 5 to 0 (xor)
        ld a, 5
        utils.registers.transformA 5, 0
        expect.a.toBe 0

        ; 0 to 1 (inc)
        ld a, 0
        utils.registers.transformA 0, 1
        expect.a.toBe 1

        ; 2 to 1 (dec)
        ld a, 2
        utils.registers.transformA 2, 1
        expect.a.toBe 1

        ; Rotate left
        ld a, %00000010
        utils.registers.transformA %00000010, %00000100
        expect.a.toBe %00000100

        ; Rotate right
        ld a, %00000001
        utils.registers.transformA %00000001, %10000000
        expect.a.toBe %10000000

        ; Underflow
        ld a, 0
        utils.registers.transformA 0, 255
        expect.a.toBe 255

        ; Overflow
        ld a, 255
        utils.registers.transformA 255, 0
        expect.a.toBe 0

        ; Completely different value
        ld a, 1
        utils.registers.transformA 1, 102
        expect.a.toBe 102
