;====
; SMSLib
;
; Includes the full suite of SMSLib modules. Each module can be included
; inidividually if desired, but ensure you call their respective init macros
; (if they exist). You can also use boot.asm to do this for you.
;
; Usage:
;
; .incdir "./lib/smslib"    ; path to SMSLib directory
; .include "smslib.asm"     ; import this file
;
; See README.md for documentation regarding each module
;====

; Use basic mapper if none defined
.ifndef mapper.ENABLED
    .include "mapper/basic.asm"
.endif

.include "input.asm"        ; handles input
.include "interrupts.asm"   ; handles line and frame interrupts
.include "palette.asm"      ; handles colors
.include "patterns.asm"     ; handles patterns (tile images)
.include "pause.asm"        ; handles pause button
.include "sprites.asm"      ; handles sprites
.include "tilemap.asm"      ; handles tilemap
.include "vdpreg.asm"       ; handles vdp settings

.include "boot.asm"         ; initialises system and smslib modules
