;====
; SMSLib common functionality
;
; Include this file along with any of the additional modules you require.
; See README.md for more instructions
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
; Initialises the system. Should be called at orga 0.
;
; Clears vram
; If a mapper is being used it will initialise the paging registers
; If vdpreg is being used it will initialise the VDP registers
;
; @in   then    (optional) label to jump to when complete
;====
.macro "smslib.init" args then
    di              ; disable interrupts
    im 1            ; interrupt mode 1
    ld sp, $dff0    ; set stack pointer

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

    call utils.vdp.clearVram

    .ifdef then
        jp then         ; jump to init section
    .endif
.endm
