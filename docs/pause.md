# Pause (pause.asm)

Provides a pause handler that toggles a flag in RAM whenever the pause button is pressed. This flag can be detected at a safe position in your code such as at the start of the game loop.

Basic pause functionality can be provided by simply waiting until the pause button is pressed again:

```
pause.waitIfPaused
```

If you wish to jp or call a label based on the pause state, you can use the following:

```
pause.jpIfPaused myPauseState
pause.callIfPaused myPauseState

myPauseState:
    ...
```
