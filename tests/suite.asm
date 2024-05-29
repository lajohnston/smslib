; Include Zest library
.define zest.SUITE_BANKS 2
.incdir "./zest"        ; point to zest directory
.include "zest.asm"     ; include the zest.asm library

; Import smslib (via smslib-zest helper)
.incdir ".."
    .define input.ENABLE_PORT_2
    .include "tests/smslib-zest.asm"
.incdir "."

; Test helpers
.include "input/_helpers.asm"

; Append test files to zest.suite
.section "input tests (bank 1)" appendto zest.suite
    .include "input/if.test.asm"
    .include "input/ifHeld.test.asm"
    .include "input/ifPressed.test.asm"
    .include "input/ifReleased.test.asm"
.ends

; Register preservation
.section "registers.asm tests" appendto zest.suiteBank2
    jp +
        suite.setAllToA:
            ld b, a
            ld c, a
            ld d, a
            ld e, a
            ld h, a
            ld l, a
            ld ixl, a
            ld ixh, a
            ld iyl, a
            ld iyh, a
            ld i, a
            ret

        suite.clobberAll:
            ex af, af'  ; switch AF and AF' to clobber both
            exx         ; switch main registers with shadow to clobber both sets

            ; Clobber index registers
            ld ixl, a
            ld ixh, a
            ld iyl, a
            ld iyh, a
            ld i, a
            ret
    +:

    .include "registers/autoPreserve.test.asm"
    .include "registers/iRegister.test.asm"
    .include "registers/nestedPreserveScopes.test.asm"
    .include "registers/registers.test.asm"
    .include "registers/sequentialClobberScopes.test.asm"
.ends

; Palette
.section "palette.asm tests" appendto zest.suiteBank2
    .include "palette/setIndex.test.asm"
    .include "palette/writeSlice.test.asm"
.ends

; Sprites
.section "sprite.asm tests" appendto zest.suiteBank2
    .include "sprites/add.test.asm"
    .include "sprites/addGroup.test.asm"
    .include "sprites/copyToVram.test.asm"
    .include "sprites/init.test.asm"
.ends
