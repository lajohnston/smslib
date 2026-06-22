;====
; Returns if no column scroll is needed, otherwise jumps to the relevant
; 'left' or 'right' label depending on the column scroll direction
;
; @in   left    if scrolling left, will continue to this label
; @in   right   if scrolling right, will jump to this label
;====
.macro "tilemap.ifColScrollElseRet" args left, right
    utils.assert.equals NARGS 2 "\. requires 2 arguments (left and right)"

    utils.clobbers.withBranching "af"
        ld a, (tilemap.ram.flags)       ; load flags
        rlca                            ; set carry to 7th bit
        utils.clobbers.end.retnc        ; ret if no col to scroll (bit 7 was 0)

        ; Check right scroll flag
        rlca                            ; set carry to what was 6th bit
        utils.clobbers.end.jpnc right   ; jp if scrolling right (bit 6 was 0)
        jp nc, right
        ; ...otherwise continue to 'left' label
    utils.clobbers.end
.endm
