;====
; Pause handler
;====

.define pause.ENABLED 1

;====
; Dependencies
;====
.ifndef utils.ram
    .include "utils/ram.asm"
    utils.ram.assertRamSlot
.endif

.ifndef utils.assert
    .include "utils/assert.asm"
.endif

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
; Toggles a flag in RAM which can be detected when appropriate
;====
.macro "pause.handler"
    push af
        ld a, (pause.ram.pauseFlag) ; read flag
        xor 1                       ; toggle flag
        ld (pause.ram.pauseFlag), a ; store
    pop af

    retn
.endm

;====
; Pause handler sequence at ROM address $66. The SMS will jump to this location
; when the pause button is pressed
;====
.ifndef pause.DISABLE_HANDLER
    .bank 0 slot 0
    .orga $66
    .section "pause.handler" force
        pause.handler
    .ends
.endif

;====
; Initialises the pause handler in RAM
;====
.macro "pause.init"
    xor a
    ld (pause.ram.pauseFlag), a
.endm

;====
; If pause activated, waits until pause button is pressed again before
; continuing
;====
.macro "pause.waitIfPaused" isolated
    -:
    ld a, (pause.ram.pauseFlag) ; read pauseFlag
    or a        ; analyse flag
    jp z, +     ; jp if not paused
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
    ld a, (pause.ram.pauseFlag)
    or a         ; analyse a
.endm

;====
; Jumps to the given address if the pause button has been pressed
;
; @in   address     address to jump to
;====
.macro "pause.jpIfPaused" args address
    utils.assert.label address "pause.asm \.: Invalid address argument"

    pause.checkPause
    jp nz, address
.endm

;====
; Calls the given address if the pause button has been pressed
;
; @in   address    address to call
;====
.macro "pause.callIfPaused" args address
    utils.assert.label address "pause.asm \.: Invalid address argument"

    pause.checkPause
    call nz, address
.endm
