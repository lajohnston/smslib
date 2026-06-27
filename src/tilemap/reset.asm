;====
; Initialises the RAM buffers and scroll values to their starting state
;====
.macro "tilemap.reset"
    \@_\.:

    utils.clobbers "af"
        call tilemap._reset
    utils.clobbers.end
.endm

;====
; (Private) Initialises the RAM buffers and scroll values to their starting state
;====
.section "tilemap._reset" free
    tilemap._reset:
        xor a   ; set A to 0
        ld (tilemap.ram.flags), a
        ld (tilemap.ram.yScrollBuffer), a

        ld (tilemap.ram.vramRowWrite), a
        ld (tilemap.ram.vramRowWrite + 1), a

        ld (tilemap.ram.colWriteIndex), a

        ; Set the VDP SCROLL_Y_REGISTER to 0
        utils.vdpCommand.setRegister tilemap.SCROLL_Y_REGISTER

        ; Set the xScrollBuffer to the starting X_OFFSET value
        ld a, tilemap.X_OFFSET
        ld (tilemap.ram.xScrollBuffer), a

        ; Write xScrollBuffer to the VDP SCROLL_X_REGISTER (needs to be negated)
        ld a, -tilemap.X_OFFSET
        utils.vdpCommand.setRegister tilemap.SCROLL_X_REGISTER

        ret
.ends
