;====
; Helper macros for the input tests
;====

; Unrolled macros, to save some ROM space
.section "test.input.unrolledMacros" free
    test.input.readPort1:
        input.readPort1
        ret
.ends

;====
; Defines button variables for use in the input tests
;
; @in   buttonNumber    0-6 (UP, DOWN, LEFT, RIGHT, 1, 2 respectively)
;
; @out  the following defines:
;           BUTTON_NAME   = the name of the button
;           FAKE_INPUT    = the fake controller input, to pass to zest.mockController1/2
;           ALL_BUTTONS_EXCEPT_CURRENT    = FAKE_INPUT inverted
;           TEST_INPUT    = the fake value to past to the input.if* macros
;====
.macro "test.input.defineButtonData" args buttonNumber
    .if buttonNumber == 0
        .redefine BUTTON_NAME "U"
        .redefine FAKE_INPUT zest.UP
        .redefine TEST_INPUT input.UP
    .elif buttonNumber == 1
        .redefine BUTTON_NAME "D"
        .redefine FAKE_INPUT zest.DOWN
        .redefine TEST_INPUT input.DOWN
    .elif buttonNumber == 2
        .redefine BUTTON_NAME "L"
        .redefine FAKE_INPUT zest.LEFT
        .redefine TEST_INPUT input.LEFT
    .elif buttonNumber == 3
        .redefine BUTTON_NAME "R"
        .redefine FAKE_INPUT zest.RIGHT
        .redefine TEST_INPUT input.RIGHT
    .elif buttonNumber == 4
        .redefine BUTTON_NAME "1"
        .redefine FAKE_INPUT zest.BUTTON_1
        .redefine TEST_INPUT input.BUTTON_1
    .elif buttonNumber == 5
        .redefine BUTTON_NAME "2"
        .redefine FAKE_INPUT zest.BUTTON_2
        .redefine TEST_INPUT input.BUTTON_2
    .endif

    .redefine ALL_BUTTONS_EXCEPT_CURRENT FAKE_INPUT ~ $ff
    .redefine ALL_BUTTONS %00111111
.endm

;====
; Mocks the input for the given controller
;
; @in   controller  0 = controller 1, 1 = controller 2
; @in   input       the input data to pass to zest.mockController1/2
; @in   [frames]    the number of input frames to mock (defaults to 1)
;====
.macro "test.input.mockController" args controller input frames
    .if NARGS == 2
        .define frames 1
    .endif

    .if controller == 0
        zest.mockController1 input

        .repeat frames
            call test.input.readPort1
        .endr
    .else
        zest.mockController2 input

        .repeat frames
            input.readPort2
        .endr
    .endif
.endm
