;====
; Defines a section at address 0 to initialise the system as well as any
; SMSLib modules that have been included. Once complete it will jump to an
; 'init' label that you must define in your code.
;
; This file should be included after including the other modules to ensure it
; knows which modules are active.
;====

;====
; Settings
;====

;===
; init.DISABLE_HANDLER
; If defined, disables the boot handler
;===

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
; Boot sequence
;====
.macro "init"
    di              ; disable interrupts
    im 1            ; interrupt mode 1
    ld sp, $dff0    ; set stack pointer

    ; Initialise the system
    call init.smslibModules

    ; Jump to init label, defined by user
    jp init
.endm

;====
; Boot sequence at ROM address 0
;====
.ifndef init.DISABLE_HANDLER
    .bank 0 slot 0
    .orga 0
    .section "init.bootHandler" force
        init
    .ends
.endif

;====
; Initialise any SMSLib modules that are activated
;====
.macro "init.smslibModules"
    ; initialise paging registers
    .ifdef mapper.ENABLED
        .ifeq mapper.ENABLED 1
            mapper.init
        .endif
    .endif

    ; initialise vdp registers
    .ifdef vdp.ENABLED
        .ifeq vdp.ENABLED 1
            vdp.init
        .endif
    .endif

    ; initialise pause handler
    .ifdef pause.ENABLED
        .ifeq pause.ENABLED 1
            pause.init
        .endif
    .endif

    ; initialise sprite buffer
    .ifdef sprites.ENABLED
        .ifeq sprites.ENABLED 1
            sprites.init
        .endif
    .endif

    ; initialise input handler
    .ifdef input.ENABLED
        .ifeq input.ENABLED 1
            input.init
        .endif
    .endif

    ; initialise interrupt handler
    .ifdef interrupts.ENABLED
        .ifeq interrupts.ENABLED 1
            interrupts.init
        .endif
    .endif
.endm

.section "init.smslibModules" free
    init.smslibModules:
        ; Initialise modules
        init.smslibModules

        ; Zeroes VRAM, then returns
        jp utils.vdp.clearVram
.ends
