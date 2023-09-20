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
.section "init.smslibModules" free
    init.smslibModules:
        ; initialise paging registers
        .ifdef mapper.ENABLED
            mapper.init
        .endif

        ; initialise vdp registers
        .ifdef vdp.ENABLED
            vdp.init
        .endif

        ; initialise pause handler
        .ifdef pause.ENABLED
            pause.init
        .endif

        ; initialise sprite buffer
        .ifdef sprites.ENABLED
            sprites.init
        .endif

        ; initialise input handler
        .ifdef input.ENABLED
            input.init
        .endif

        ; initialise interrupt handler
        .ifdef interrupts.ENABLED
            interrupts.init
        .endif

        ; Zeroes VRAM, then returns
        jp utils.vdp.clearVram
.ends

;====
; Alias to call init.smslibModules
;====
.macro "init.smslibModules"
    call init.smslibModules
.endm