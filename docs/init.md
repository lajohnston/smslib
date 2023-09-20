# Initialise (init.asm)

Adds a code section at address 0 to initialise the system and any smslib modules you are using. When it is done it will jump to an `init` label that you must define in your code.

If you're using the individual libraries (rather than the full smslib.asm suite), `init.asm` should be included last to ensure if knows which libraries to initialise.

## Settings

The following constants can be set before including this module or smslib.asm:

```asm
; Disables the boot handler at address 0
.define init.DISABLE_HANDLER
```

## init

Defines the boot handler code at the current location.

```asm
init
```

## init.smslibModules

Initialise all active smslib modules, which happens automatically at boot (unless `init.DISABLE_HANDLER` is defined). Note: the modules must have been `.included` before this is called.

```asm
init.smslibModules
```