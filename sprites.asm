;====
; Sprite Buffer
; Manages a sprite table buffer in RAM and transfers it to VRAM
;====
.define sprites.ENABLED 1

;====
; Settings
;
; Define these before including this file if you wish to override the defaults
;====

; The maximum screen y coordinate a sprite can be. Defaults to 192
.ifndef sprites.MAX_Y_POSITION
    .define sprites.MAX_Y_POSITION 192
.endif

; The sprite table's address in VRAM. Defaults to $3f00
.ifndef sprites.VRAM_ADDRESS
    .define sprites.VRAM_ADDRESS $3f00
.endif

;====
; Dependencies
;====
.ifndef utils.ram
    .include "utils/ram.asm"
.endif

.ifndef utils.clobbers
    .include "utils/clobbers.asm"
.endif

.ifndef utils.outiBlock
    .include "utils/outiBlock.asm"
.endif

.ifndef utils.vdp
    .include "utils/vdp.asm"
.endif

;====
; Constants and variables
;====
.define sprites.TABLE_OFFSET $40
.define sprites.GROUP_TERMINATOR 255  ; terminates list of sprites.Sprite instances
.define sprites.Y_TERMINATOR $D0
.define sprites.MAX_SPRITES 64

; If 1 a batch is in progress, otherwise it is 0
.define sprites.batchInProgress 0

;====
; Sprite buffer
;
; An instance should be placed in RAM at a $xx3F offset and named
; 'sprites.ram.buffer'
;====
.struct "sprites.Buffer"
    nextIndex:      DSB 1   ; the low byte address of the next free y index
    yPos:           DSB 64  ; screen yPos for each of the 64 sprites
    xPosAndPattern: DSB 128 ; { 1 byte xPos, 1 byte pattern } * 64 sprites
.endst

;====
; RAM
;====

;====
; The sprite table buffer in RAM. The y coordinates are aligned to the table
; offset $40 to make use of performance optimisations. This technique is
; described by user gvx32 in:
; https://www.smspower.org/forums/15794-AFewHintsOnCodingAMediumLargeSizedGameUsingWLADX
;====
.ramsection "sprites.ram.buffer" slot utils.ram.SLOT align 256 offset sprites.TABLE_OFFSET - sprites.Buffer.yPos
    sprites.ram.buffer: instanceof sprites.Buffer
.ends

;====
; Represents a single sprite. If using sprites.addGroup, more than one can be
; defined in a list terminated with a sprites.GROUP_TERMINATOR byte
;====
.struct "sprites.Sprite"
    relativeX:  db
    relativeY:  db
    pattern:    db
.endst

;====
; Define data for a sprites.Sprite instance
;
; @in   pattern     the pattern number
; @in   relativeX   the relativeX position
; @in   relativeY   the relativeY position
;====
.macro "sprites.sprite" args pattern, relX, relY
    .db relX relY pattern
.endm

;====
; Marks the start of a group of sprites. Doesn't currently do anything but is
; provided for semantics
;====
.macro "sprites.startGroup"
    ; do nothing - macro provided for semantics
.endm

;====
; Marks the end of a group of sprites
;====
.macro "sprites.endGroup"
    .db sprites.GROUP_TERMINATOR
.endm

;====
; (Private) Loads the next available sprite index (y position) into DE
;
; @out  de  the address of the next available sprite index
;====
.macro "sprites._getNextIndex"
    utils.clobbers "af"
        ld de, sprites.ram.buffer.nextIndex
        ld a, (de)
        ld e, a
    utils.clobbers.end
.endm

;====
; Stores the current index
;
; @in   de  the address of the current sprite index (y position)
;====
.macro "sprites._storeNextIndex"
    ; Store next index
    utils.clobbers "af"
        ld a, e
        ld (sprites.ram.buffer.nextIndex), a
    utils.clobbers.end
.endm

;====
; (Private) Adds a sprite to the buffer. See sprites.add macro for public
; macro
;====
.section "sprites._add" free
    ;====
    ; Add sprite to the next available index
    ;
    ; @in  a  screen yPos
    ; @in  b  screen xPos
    ; @in  c  pattern number
    ;
    ; @out de pointer to next available y slot in sprite buffer
    ;====
    sprites._addToNextIndex:
        ; Retrieve next slot
        ld iyl, a               ; preserve yPos
        sprites._getNextIndex
        ld a, iyl               ; restore yPos
                                ; continue to sprites.add

    ;====
    ; Set a sprite in the currently selected slot
    ;
    ; @in  de pointer to next available y slot in sprite buffer
    ; @in  a  screen yPos
    ; @in  b  screen xPos
    ; @in  c  pattern number
    ;
    ; @out de pointer to next available y slot in sprite buffer
    ;====
    sprites._add:
        ; Set ypos
        ld (de), a

        ; xPos
        rlc e   ; Switch to xPos (e = e * 2; works because of $xx40 offset)
        ld a, b
        ld (de), a

        ; Pattern
        inc e
        ld a, c
        ld (de), a

        ; Restore de to point back to yPos
        rr e    ; (e - 1) / 2
        inc e   ; point to next free index
        ret
.ends

;====
; Add a sprite to the buffer
;
; @in  a    screen yPos
; @in  b    screen xPos
; @in  c    pattern number
;
; @in  de   (optional) pointer to next available index (yPos) in sprite buffer
;           Only required if a batch is in progress
;
; @out de   (if batch in progress) pointer to next available index (yPos) in
;           sprite buffer
;====
.macro "sprites.add"
    .if sprites.batchInProgress == 1
        utils.clobbers "af"
            call sprites._add
        utils.clobbers.end
    .else
        utils.clobbers "af", "de", "iy"
            call sprites._addToNextIndex
            sprites._storeNextIndex
        utils.clobbers.end
    .endif
.endm

;====
; Starts a 'batch' of sprites. If adding multiple sprites and sprite groups it
; is more efficient to wrap the multiple calls in sprites.startBatch and
; sprites.endBatch; This ensures the nextIndex value is only read and updated
; once rather than for each sprite or spriteGroup
;====
.macro "sprites.startBatch"
    .ifeq sprites.batchInProgress 1
        .print "\. called but batch already in progress."
        .print " Ensure you also call sprites.endBatch\n"
        .fail
    .endif

    .redefine sprites.batchInProgress 1
    sprites._getNextIndex
.endm

;====
; Ends a sprite batch
;====
.macro "sprites.endBatch"
    .ifeq sprites.batchInProgress 0
        .print "\. called but no batch is in progress\n"
        .fail
    .else
        .redefine sprites.batchInProgress 0
        sprites._storeNextIndex
    .endif
.endm

;====
; Initialises a sprite buffer in RAM
;====
.macro "sprites.init"
    utils.clobbers "af"
        ; Set nextIndex to index 0
        ld a, <(sprites.ram.buffer) + sprites.Buffer.yPos   ; low byte of index 0
        ld (sprites.ram.buffer.nextIndex), a                ; store in nextIndex
    utils.clobbers.end
.endm

;====
; Reset sprite buffer back to default. Alias for sprites.init
;====
.macro "sprites.reset"
    sprites.init
.endm

;====
; (Private) Copies the sprite buffer from RAM to VRAM. This should be performed while the
; display is off or during VBlank
;====
.section "sprites._copyToVram"
    sprites._copyToVram:
        ; Set VDP write address to y positions
        utils.vdp.prepWrite sprites.VRAM_ADDRESS

        ; Load number of sprites set
        ld hl, sprites.ram.buffer.nextIndex
        ld a, (hl)                      ; read nextIndex value
        sub sprites.TABLE_OFFSET        ; sub table offset to get sprite count
        jp z, _noSprites                ; jump if no sprites
        ld ixl, a                       ; preserve counter in IXL

        ; Copy y positions to VRAM
        ld b, ixl                       ; load size into B
        inc l                           ; point to y positions in buffer
        utils.outiBlock.writeUpTo128Bytes   ; write data

        ; Output sprite terminator at end of y positions
        ld a, ixl                       ; load counter into A
        cp sprites.MAX_SPRITES          ; compare with max sprites
        jp nc, +                        ; skip if counter == max sprites
            ld a, sprites.Y_TERMINATOR  ; load y terminator into A
            out (c), a                  ; write y terminator
        +:

        ; Point to x positions in VRAM and buffer
        utils.vdp.prepWrite (sprites.VRAM_ADDRESS + 128) 0  ; vram
        ld l, <(sprites.ram.buffer.xPosAndPattern)          ; buffer

        ; Copy x positions and patterns from buffer to VRAM
        ld b, ixl                       ; restore sprite count
        rlc b                           ; double to get xPos + pattern
        utils.outiBlock.writeUpTo128BytesThenReturn ; write bytes, then ret

    ; No sprites in buffer - cap table with sprite terminator then return
    ; VRAM address must be set
    _noSprites:
        ld a, sprites.Y_TERMINATOR      ; load y terminator into A
        out (c), a                      ; write y terminator
        ret
.ends

;====
; Copies the sprite buffer from RAM to VRAM. This should be performed while the
; display is off or during VBlank
;====
.macro "sprites.copyToVram"
    utils.clobbers "af", "bc", "hl", "ix", "iy"
        call sprites._copyToVram
    utils.clobbers.end
.endm

;====
; (Private) See sprites.addGroup
;====
.section "sprites._addGroup" free
    ;====
    ; Gets the next free sprite index and adds a sprite group from there onwards
    ;
    ; @in   b   anchor x position (left-most)
    ; @in   c   anchor y position (top-most)
    ; @in   hl  pointer to sprites.Sprite instances terminated by
    ;           sprites.GROUP_TERMINATOR
    ;
    ; @out  de  next free sprite index
    ;====
    sprites._addGroupFromNextIndex:
        sprites._getNextIndex
        jp sprites._addGroup

    ;====
    ; Add a group of sprites from the currently selected slot
    ;
    ; @in   b   anchor x position (left-most)
    ; @in   c   anchor y position (top-most)
    ; @in   de  pointer to next free sprite slot
    ; @in   hl  pointer to sprites.Sprite instances terminated by
    ;           sprites.GROUP_TERMINATOR
    ;
    ; @out  de  next free sprite slot
    ;====
    _xOffScreen:
        inc hl  ; point to relY
    _yOffScreen:
        inc hl  ; point to pattern
    _nextSprite:
        inc hl  ; point to next item

    sprites._addGroup:
        ld a, (hl)          ; load relX
        cp sprites.GROUP_TERMINATOR
        ret z               ; end of group

        ; Add relative x
        add a, b            ; relX + anchorX
        jr c, _xOffScreen   ; off screen; next sprite
        ld ixh, a           ; store result x for later

        ; Add relative y
        inc hl              ; point to relY
        ld a, (hl)          ; load relY
        add a, c            ; relY + anchorY
        cp sprites.MAX_Y_POSITION   ; compare with max y allowed
        jr nc, _yOffScreen  ; off screen; next sprite

        ; Output sprite to sprite buffer
        ld (de), a          ; set sprite y in buffer
        rlc e               ; point to sprite x; works because of $xx40 offset
        ld a, ixh           ; restore x
        ld (de), a          ; set sprite x in buffer
        inc hl              ; point to pattern number in group
        inc e               ; point to pattern number in buffer
        ld a, (hl)          ; load pattern number
        ld (de), a          ; set pattern number in buffer
        rr e                ; return to y in buffer
        inc e               ; point to next sprite slot in buffer
        jp _nextSprite
.ends

;====
; Adds a group of sprites relative to an anchor position. Sprites within the
; group that fall off-screen are not added.
;
; Limitation: Once the anchorX position falls off screen the entire group will
; disappear, meaning the group cannot move smoothly off the left edge of the
; screen. This can be partially obscured by setting the VDP registers to hide
; the left column
;
; @in   hl  pointer to sprites.Sprite instances terminated by
;           sprites.GROUP_TERMINATOR
;====
.macro "sprites.addGroup"
    .if sprites.batchInProgress == 1
        utils.clobbers "af", "hl", "ix"
            call sprites._addGroup
        utils.clobbers.end
    .else
        utils.clobbers "af", "de", "hl", "ix"
            call sprites._addGroupFromNextIndex
            sprites._storeNextIndex
        utils.clobbers.end
    .endif
.endm
