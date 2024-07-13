; Include Zest library
.define zest.SUITE_BANKS 5
.incdir "./zest"        ; point to zest directory
.include "zest.asm"     ; include the zest.asm library

; Import smslib (via smslib-zest helper)
.incdir ".."
    .define input.ENABLE_PORT_2
    .include "tests/smslib-zest.asm"

    .define scroll.metatiles.ENFORCE_BOUNDS
    .include "scroll/metatiles.asm"
    .include "scroll/tiles.asm"
.incdir "."

; Test helpers
.include "input/_helpers.asm"

; Append test files to zest.suite
.section "input tests (bank 1)" appendto zest.suite
    .include "input/if.test.asm"
    .include "input/ifHeld.test.asm"

    .include "input/ifXDir.test.asm"
    .include "input/ifXDirHeld.test.asm"
    .include "input/ifXDirPressed.test.asm"
    .include "input/ifXDirReleased.test.asm"
.ends

.section "input tests (bank 2)" appendto zest.suiteBank2
    .include "input/ifPressed.test.asm"
    .include "input/ifReleased.test.asm"

    .include "input/ifYDir.test.asm"
    .include "input/ifYDirHeld.test.asm"
.ends

.section "input tests (bank 3)" appendto zest.suiteBank3
    .include "input/ifYDirPressed.test.asm"
    .include "input/ifYDirReleased.test.asm"

    .include "input/loadADirX.test.asm"
    .include "input/loadADirY.test.asm"

    .include "input/init.test.asm"
    .include "input/readPort1.test.asm"
    .include "input/readPort2.test.asm"
.ends

; Register preservation
.include "utils/registers/_helpers.asm"

.section "utils/clobbers.asm tests" appendto zest.suiteBank4
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

    .include "utils/clobbers/clobbers.end.retz.test.asm"
    .include "utils/clobbers/clobbers.end.retnz.test.asm"

    .include "utils/clobbers/clobbers.end.retc.test.asm"
    .include "utils/clobbers/clobbers.end.retnc.test.asm"

    .include "utils/clobbers/clobbers.end.retpe.test.asm"
    .include "utils/clobbers/clobbers.end.retpo.test.asm"

    .include "utils/clobbers/clobbers.end.retm.test.asm"
    .include "utils/clobbers/clobbers.end.retp.test.asm"
.ends

.section "utils/registers.asm tests" appendto zest.suiteBank5
    .include "utils/registers/autoPreserve.test.asm"
    .include "utils/registers/iRegister.test.asm"
    .include "utils/registers/nestedPreserveScopes.test.asm"
    .include "utils/registers/registers.test.asm"
.ends

; Interrupts
.section "interrupts.asm tests" appendto zest.suiteBank5
    .include "interrupts/enable.test.asm"
    .include "interrupts/init.test.asm"
    .include "interrupts/setLineInterval.test.asm"
    .include "interrupts/waitForVBlank.test.asm"
.ends

; Palette
.section "palette.asm tests" appendto zest.suiteBank5
    .include "palette/setIndex.test.asm"
    .include "palette/writeBytes.test.asm"
    .include "palette/writeRgb.test.asm"
    .include "palette/writeSlice.test.asm"
.ends

; Patterns
.section "patterns.asm tests" appendto zest.suiteBank5
    .include "patterns/setIndex.test.asm"
    .include "patterns/writeBytes.test.asm"
    .include "patterns/writeSlice.test.asm"
.ends

; Pause
.section "pause.asm tests" appendto zest.suiteBank5
    .include "pause/callIfPaused.test.asm"
    .include "pause/init.test.asm"
    .include "pause/jpIfPaused.test.asm"
    .include "pause/waitIfPaused.test.asm"
.ends

; scroll/metatiles.asm
.include "scroll/metatiles/_helpers.asm"

.section "scroll/metatiles tests" appendto zest.suiteBank5
    .include "scroll/metatiles/init.test.asm"
    .include "scroll/metatiles/render.test.asm"
    .include "scroll/metatiles/update.test.asm"
.ends

; scroll/tiles.asm
.section "scroll/tiles tests" appendto zest.suiteBank5
    .include "scroll/tiles/init.test.asm"
    .include "scroll/tiles/render.test.asm"
    .include "scroll/tiles/update.test.asm"
.ends

; Sprites
.section "sprite.asm tests" appendto zest.suiteBank5
    .include "sprites/add.test.asm"
    .include "sprites/addGroup.test.asm"
    .include "sprites/copyToVram.test.asm"
    .include "sprites/init.test.asm"
.ends

; Tilemap
.section "tilemap.asm tests" appendto zest.suiteBank5
    .include "tilemap/adjustXPixels.test.asm"
    .include "tilemap/adjustYPixels.test.asm"
    .include "tilemap/calculateScroll.test.asm"
    .include "tilemap/ifColScroll.test.asm"
    .include "tilemap/ifColScrollElseRet.test.asm"
    .include "tilemap/ifRowScroll.test.asm"
    .include "tilemap/ifRowScrollElseRet.test.asm"
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
    .include "tilemap/writeScrollBuffers.test.asm"
    .include "tilemap/writeScrollRegisters.test.asm"
    .include "tilemap/writeTile.test.asm"
    .include "tilemap/writeTiles.test.asm"
.ends
