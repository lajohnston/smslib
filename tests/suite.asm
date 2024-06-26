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
.include "utils/registers/_helpers.asm"

.section "utils/registers.asm tests" appendto zest.suiteBank2
    .include "utils/clobbers/clobbers.withBranching.test.asm"
    .include "utils/clobbers/clobbers.endBranch.test.asm"

    .include "utils/clobbers/clobbers.end.jpc.test.asm"
    .include "utils/clobbers/clobbers.end.jpnc.test.asm"

    .include "utils/clobbers/clobbers.end.jrc.test.asm"
    .include "utils/clobbers/clobbers.end.jrnc.test.asm"

    .include "utils/clobbers/clobbers.end.jppo.test.asm"
    .include "utils/clobbers/clobbers.end.jppe.test.asm"

    .include "utils/clobbers/clobbers.end.jpp.test.asm"
    .include "utils/clobbers/clobbers.end.jpm.test.asm"

    .include "utils/clobbers/clobbers.end.jpz.test.asm"
    .include "utils/clobbers/clobbers.end.jpnz.test.asm"

    .include "utils/clobbers/clobbers.end.jrz.test.asm"
    .include "utils/clobbers/clobbers.end.jrnz.test.asm"

    .include "utils/clobbers/sequentialClobberScopes.test.asm"

    .include "utils/registers/autoPreserve.test.asm"
    .include "utils/registers/iRegister.test.asm"
    .include "utils/registers/nestedPreserveScopes.test.asm"
    .include "utils/registers/registers.test.asm"
.ends

; Palette
.section "palette.asm tests" appendto zest.suiteBank2
    .include "palette/setIndex.test.asm"
    .include "palette/writeBytes.test.asm"
    .include "palette/writeRgb.test.asm"
    .include "palette/writeSlice.test.asm"
.ends

; Patterns
.section "patterns.asm tests" appendto zest.suiteBank2
    .include "patterns/setIndex.test.asm"
    .include "patterns/writeBytes.test.asm"
    .include "patterns/writeSlice.test.asm"
.ends

; Sprites
.section "sprite.asm tests" appendto zest.suiteBank2
    .include "sprites/add.test.asm"
    .include "sprites/addGroup.test.asm"
    .include "sprites/copyToVram.test.asm"
    .include "sprites/init.test.asm"
.ends

; Tilemap
.section "tilemap.asm tests" appendto zest.suiteBank2
    .include "tilemap/adjustXPixels.test.asm"
    .include "tilemap/adjustYPixels.test.asm"
    .include "tilemap/calculateScroll.test.asm"
    .include "tilemap/ifColScroll.test.asm"
    .include "tilemap/loadHLWriteAddress.test.asm"
    .include "tilemap/reset.test.asm"
    .include "tilemap/setColRow.test.asm"
    .include "tilemap/setIndex.test.asm"
    .include "tilemap/stopDownRowScroll.test.asm"
    .include "tilemap/stopLeftColScroll.test.asm"
    .include "tilemap/stopRightColScroll.test.asm"
    .include "tilemap/stopUpRowScroll.test.asm"
    .include "tilemap/writeBytes.test.asm"
    .include "tilemap/writeBytesUntil.test.asm"
    .include "tilemap/writeRow.test.asm"
    .include "tilemap/writeRows.test.asm"
    .include "tilemap/writeTile.test.asm"
    .include "tilemap/writeTiles.test.asm"
.ends
