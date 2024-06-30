# Register preservation (utils.clobbers, utils.preserve, utils.restore)

These utility modules provide a system for efficiently preserving Z80 register states between macro calls, ensuring only the needed registers are preserved.

1. Macros can utilise [utils.clobbers](#utilsclobbers) to declare which registers they clobber (in lieu of push/pop calls)
2. The caller can utilise [utils.preserve](#utilspreserve) to wrap the calls and declare which registers should not be clobbered
3. The utilities will work together to ensure only the clobbered AND protected registers get preserved

This provides the following advantages:

1. vs the macros manually preserving everything they clobber

- The utilities ensure only the necessary registers are preserved. If the caller doesn't care about them (and they often don't) they won't be push/popped, saving 21-28 cycles for each

2. vs the caller manually preserving the registers it cares about

- The utilities ensure the caller doesn't need to know which registers will get clobbered
- If the macros being called are updated and the clobber list ever changes, the new push/pops will be auto-generated without the caller needing to be updated

3. Allows an [auto-preserve](#automatic-registers-preseveration) mode makes this process easier (at the cost of efficiency)

## Automatic registers preseveration

To automatically preserve all registers by default, consider setting the `utils.registers.AUTO_PRESERVE` value. When a clobber scope is encountered it will then automatically preserve all registers that get clobbered.

```asm
.redefine utils.registers.AUTO_PRESERVE 0 ; deactivate (default)
.redefine utils.registers.AUTO_PRESERVE 1 ; activate
```

You can opt-out of this on a per-call basis using `utils.preserve` to create more-specific preserve scopes for particular calls.

## utils.clobbers

Macros that clobber registers can utilise `utils.clobbers` and `utils.clobbers.end` in place of the `push`/`pop` calls they would normally make. This is referred to as a 'clobber scope'.

```asm
.macro "normal way"
    push af
    push de
    push hl
        ...
    pop hl  ; pop in reverse order
    pop de
    pop af
.endm

.macro "with utils/clobbers.asm"
    utils.clobbers "af" "de" "hl"
        ... ; code
    utils.clobbers.end
.endm
```

Acceptable arguments are (case-insensitive):

- Main registers: `"af"`, `"bc"`, `"de"`, `"hl"`, `"ix"`, `"iy"`, `"i"`
- Shadow registers: `"af'"`, `"bc'"`, `"de'"`, `"hl'"`

Clobber scopes can be nested within one another, so when calling other macros it's possible for these to define their own clobber scopes. If you need to call a macro that isn't clobber scope aware, the calling macro will need to take responsibility to wrap the call.

Using `utils.clobbers` directly inside `sections` could produce unpredictable results as they won't be aware of the context they're `call`ed in. You'll instead just need to wrap the `call` in its own macro that defines the clobber scopes.

```asm
.section "someRoutine" free
    someRoutine:
        ... ; code that clobbers af and hl
        ret
.ends

.macro "someRoutine"    ; WLA-DX allows you to use the same name if you wish
    utils.clobbers "af" "hl"
        call someRoutine
    utils.clobbers.end
.endm
```

### utils.clobbers.withBranching

If the macro produces code with multiple exit points (i.e. jumps that skip over `utils.clobbers.end`), you can use `utils.clobbers.withBranching` with special jump instructions to ensure relevant registers are restored before the jumps. If there are no registers to restore these will just perform their vanilla jump instructions.

Care should be taken to ensure the jumps don't jump outside of multiple clobber scopes and preserve scopes. The macros don't know where the jump locations are so aren't able to determine if multiple scopes should be restored.

```asm
utils.clobbers.withBranching "af"
    utils.clobbers.endBranch            ; call before unconditional jp or jr

    utils.clobbers.end.jrz, _someLabel  ; if Z, restore and jr
    utils.clobbers.end.jrnz _someLabel  ; if NZ, restore and jr
    utils.clobbers.end.jrc, _someLabel  ; if carry set, restore and jr
    utils.clobbers.end.jrnc, _someLabel ; if carry is reset, restore and jr

    utils.clobbers.end.jpz  _someLabel  ; if Z, restore and jp
    utils.clobbers.end.jpnz _someLabel  ; if NZ, restore and jp
    utils.clobbers.end.jpc  _someLabel  ; if carry, restore and jp
    utils.clobbers.end.jpnc _someLabel  ; if not carry, restore and jp
    utils.clobbers.end.jppe _someLabel  ; if parity/overflow, restore and jp
    utils.clobbers.end.jppo _someLabel  ; if not parity/overflow, restore and jp
    utils.clobbers.end.jpm  _someLabel  ; if sign, restore and jp
    utils.clobbers.end.jpp  _someLabel  ; if not sign, restore and jp

    utils.clobbers.end.retc             ; return if carry set
    utils.clobbers.end.retnc            ; return if carry is reset
utils.clobbers.end
```

In most cases `utils.clobbers.withBranching` results in the same performance as `utils.clobbers`, but in certain edge cases it knows to opt out of some optimisations to ensure there isn't a mismatch between the registers that get pushed and popped onto the stack.

If using conditional jumps, `utils.clobbers.end` is still needed to mark the end of the clobber scope and restore the registers if the jumps don't occur.

#### utils.clobbers.closeBranch

If the restore instructions aren't needed (i.e. there's an unconditional jump at the end that will always jump over it) you can use `utils.clobbers.closeBranch` to close off the branching clobber scope without generating the uneeded restore instructions.

```asm
utils.clobbers.withBranching "af"
    utils.clobbers.endBranch    ; restore registers
    jp +                        ; unconditional jump
utils.clobbers.closeBranch      ; close off branching clobber scope without restoring
```

## utils.preserve

Callers that rely on register states to be preserved can wrap the macro invokation with `utils.preserve` and `utils.restore`. This is referred to as a 'preserve scope'.

```asm
.macro "myMacro"
    ld bc, $1234

    registers.preserve "bc"
        macroThatClobsThings
    utils.restore

    ; bc will still be $1234
.endm
```

Acceptable arguments are (case-insensitive):

- Main registers: `"af"`, `"bc"`, `"de"`, `"hl"`, `"ix"`, `"iy"`, `"i"`
- Shadow registers: `"af'"`, `"bc'"`, `"de'"`, `"hl'"`

As each clobber scope is encountered in the macro chain, it will now be aware which registers the caller wishes to preserve and so preserves any that match. If the call passes through multiple nested clobber scopes that clobber the same particular register, only the first-encountered (outer) scope will preserve the register rather than it being preserved multiple times.

Calling `utils.preserve` with no arguments will default to ensuring all registers that get clobbered are preserved.

Like clobber scopes, it's possible to nest preserve scopes. Inner scopes are aware of what registers the outer scope needs preserving.

`utils.preserve` can be used within a `section` that calls macros.
