; Include Zest library
.incdir "../lib/zest"       ; point to zest directory
    .include "zest.asm"     ; include the zest.asm library
.incdir "."                 ; return to current directory

; Import smslib (via smslib-zest helper)
.incdir ".."
    .define input.ENABLE_PORT_2
    .include "tests/smslib-zest.asm"
.incdir "."

; Test helpers
.include "input/_helpers.asm"

; Append test files to zest.suite
.section "suite" appendto zest.suite
    .include "input/if.test.asm"
.ends
