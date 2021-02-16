;====
; Defines a section at address 0 to initialise the system as well as any
; SMSLib modules that have been included. Once complete it will jump to an
; 'init' label that you must define in your code.
;
; This file should be included after including the other modules to ensure it
; knows which modules are active.
;====

;====
; Dependencies
;====
.ifndef utils.vdp
    .include "utils/vdp.asm"
.endif

;====
; Code
;====

;====
; Boot sequence at ROM address 0
;====
.bank 0 slot 0
.orga 0
.section "main" force
    di              ; disable interrupts
    im 1            ; interrupt mode 1
    ld sp, $dff0    ; set stack pointer

    ; Initialise the system
    call boot.initSmslibModules

    ; Jump to init label, defined by user
    jp init
.ends

;====
; Initialise any SMSLib modules that are activated
;====
.section "boot.initSmslibModules" free
    boot.initSmslibModules:
        ; initialise paging registers
        .ifdef mapper.ENABLED
            mapper.init
        .endif

        ; initialise vdp registers
        .ifdef vdpreg.ENABLED
            vdpreg.init
        .endif

        ; initialise pause handler
        .ifdef pause.ENABLED
            pause.init
        .endif

        ; initialise sprite buffer
        .ifdef sprites.ENABLED
            sprites.init
        .endif

        ; initialise interrupt handler
        .ifdef interrupts.ENABLED
            interrupts.init
        .endif

        ; Zeroes VRAM, then returns
        jp utils.vdp.clearVram
.ends
