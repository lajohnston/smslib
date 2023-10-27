# smslib-zest.asm

The `tests/smslib-zest.asm` imports the full smslib library with a set of options to allow for testing your code with the [Zest](https://github.com/lajohnston/zest) testing framework. The aim is to only stub out/disable the minimal amount of functionality needed to provide an accurate simulation.

```asm
; Import Zest
.incdir "../zest"
.include "zest.asm"

; Import smslib-zest
.incdir "../smslib"                 ; point to the root of the smslib directory
.include "tests/smslib-zest.asm"

; Import your code and test suite
```

The file performs the following:

- Disables the smslib mapper and integrates the library with Zest's mapper
- Disables the boot, interrupt and pause handlers, as Zest has its own
- Creates a fake `utils.port.read` macro that uses Zest's input mocking
- Uses Zest's `preSuite` hook to initialise the smslib variables before the start of the suite
- Imports all the modules

An alternative approach if you wish to test your code in complete isolation would be to not import smslib at all and instead create fake macros and mocks for the routines you use. This may simplify some tests as you would just assert that the `smslib` routine were called with the correct parameters and trust the library to handle the hardware layer. It would however require lots of manual setup, so is perhaps better suited if you are only using a few routines.

## Input

You can utilise Zest's input mocking functionality to fake input values at the port level. SMSLib's `input` module itself isn't stubbed out so you can continue to use its API in your code.
