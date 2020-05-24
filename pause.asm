;====
; Pause handler
;====

.define pause.ENABLED 1

;====
; Dependencies
;====
.include "./utils/ram.asm"

;====
; RAM
;
; Flag is set when the pause button has been pressed
;====
.ramsection "pause.ram.pauseFlag" slot utils.ram.SLOT
    pause.ram.pauseFlag: db
.ends

;====
; Code
;====

;====
; Pause handler
;
; Toggles a flag in RAM whenever pause is pressed, which can be detected when
; appropriate
;====
.bank 0 slot 0
.orga $66
.section "pause.handler" force
    push af
    push hl
        ld hl, pause.ram.pauseFlag
        ld a, (hl)  ; read flag
        xor 1       ; toggle flag
        ld (hl), a  ; store
    pop hl
    pop af
    retn
.ends

;====
; Initialises the pause handler in RAM
;====
.macro "pause.init"
    xor a
    ld de, pause.ram.pauseFlag
    ld (de), a
.endm

;====
; If pause activated, waits until pause button is pressed again before
; continuing
;====
.macro "pause.waitIfPaused"
    -:
    ld de, pause.ram.pauseFlag
    ld a, (de)  ; read pauseFlag
    or a        ; analyse flag
    jp z, +     ; not paused; continue
        halt    ; wait for an interrupt (pause, vBlank, hBlank)
        jp -    ; check again
    +:
.endm

;====
; Check if the pause button has been pressed.
;
; @out  f   z flag will be reset if pause has been pressed, otherwise it will
;           be set
;====
.macro "pause.checkPause"
    ld hl, pause.ram.pauseFlag
    ld a, (hl)
    or a         ; analyse a
.endm

;====
; Jumps to the given address if the pause button has been pressed
;
; @in   addr    address to jump to
;====
.macro "pause.jpIfPaused" args addr
    pause.checkPause
    jp nz, addr
.endm

;====
; Calls the given address if the pause button has been pressed
;
; @in   addr    address to call
;====
.macro "pause.callIfPaused" args addr
    pause.checkPause
    call nz, addr
.endm
