;====
; Integration for use with Zest (https://github.com/lajohnston/zest).
;====

; Disable the various handlers (boot, pause, interrupts), as Zest has its own
.define init.DISABLE_HANDLER
.define interrupts.DISABLE_HANDLER
.define pause.DISABLE_HANDLER

; Disable mapper, as Zest uses its own
.define mapper.ENABLED 0
.define mapper.RAM_SLOT zest.RAM_SLOT

; Use Zest's mapper's RAM SLOT
.define smslib.RAM_SLOT zest.RAM_SLOT

; Define a fake version of utils.port.read
.ifndef utils.port
    .define utils.port 1

    .macro "utils.port.read" args portNumber
        .if portNumber == $dc
            zest.loadFakePortDC
        .elif portNumber == $dd
            zest.loadFakePortDD
        .endif
    .endm
.endif

; Include the rest of the library
.include "smslib.asm"

;====
; Zest hooks
;====
.section "smslib-zest.preSuite" appendto zest.preSuite
    smslib-zest.preSuite:
        init.smslibModules
.ends
