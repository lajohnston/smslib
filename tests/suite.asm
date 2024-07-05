; Include Zest library
.define zest.SUITE_BANKS 5
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
