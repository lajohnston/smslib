.section "tests.scroll.metatiles.init" free
    tests.scroll.metatiles.init:
        ld a, 64    ; the map's width in metatiles
        ld b, 0     ; the column offset in metatiles
        ld c, 0     ; the row offset in metatiles
        ld d, 64    ; the map's height in metatiles
        scroll.metatiles.init

        ret
.ends
