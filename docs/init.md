# Initialise (init.asm)

Adds a code section at address 0 to initialise the system and any smslib modules you are using. When it is done it will jump to an `init` label that you must define in your code.

If you're using the individual libraries (rather than the full smslib.asm suite), `init.asm` should be included last to ensure if knows which libraries to initialise.
