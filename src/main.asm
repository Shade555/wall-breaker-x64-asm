; =============================================================================
; main.asm - Win64 Entry Point, Window Setup, DIB Presentation & Game Loop
; Assembler: GoAsm /x64    Linker: GoLink
; =============================================================================

#include constants.inc

CONST SECTION
ALIGN 16
fFrameStep      DQ 0.0166666666666667
fMaxFrameDelta  DQ 0.05

CODE SECTION

; -----------------------------------------------------------------------------
; PresentBuffer(hdc): Blits 960x720 DIB pixels to window client area
; -----------------------------------------------------------------------------
PresentBuffer FRAME hdc
USES RBX, R12, R13

    CMP Q[gPixels], 0
    JE >>.done

    XOR R12D, R12D              ; shakeX = 0
    XOR R13D, R13D              ; shakeY = 0
    CMP D[gScreenShake], 0
    JLE >.no_shake
    INVOKE RandRange, 9
    SUB EAX, 4
    MOV R12D, EAX
    INVOKE RandRange, 9
    SUB EAX, 4
    MOV R13D, EAX
.no_shake:

    INVOKE SetStretchBltMode, [hdc], COLORONCOLOR
    MOV RBX, [gPixels]
    INVOKE StretchDIBits, [hdc], R12D, R13D, [gClientW], [gClientH], \
           0, 0, SCREEN_W, SCREEN_H, RBX, ADDR gBmi, DIB_RGB_COLORS, SRCCOPY

.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; WndProc(hwnd, uMsg, wParam, lParam): Win64 Window Callback
; -----------------------------------------------------------------------------
WndProc FRAME hwnd, uMsg, wParam, lParam
USES RBX, RSI, RDI

    MOV EAX, [uMsg]
    CMP EAX, WM_PAINT
    JE >>.on_paint
    CMP EAX, WM_ERASEBKGND
    JE >>.on_erase
    CMP EAX, WM_SIZE
    JE >>.on_size
    CMP EAX, WM_MOUSEMOVE
    JE >>.on_mousemove
    CMP EAX, WM_KEYDOWN
    JE >>.on_keydown
    CMP EAX, WM_KEYUP
    JE >>.on_keyup
    CMP EAX, WM_LBUTTONDOWN
    JE >>.on_lbtn_down
    CMP EAX, WM_LBUTTONUP
    JE >>.on_lbtn_up
    CMP EAX, WM_KILLFOCUS
    JE >>.on_killfocus
    CMP EAX, WM_DESTROY
    JE >>.on_destroy
    CMP EAX, WM_CLOSE
    JE >>.on_close

    INVOKE DefWindowProcA, [hwnd], [uMsg], [wParam], [lParam]
    RET

.on_erase:
    MOV RAX, 1
    RET

.on_size:
    MOV EAX, [lParam]
    AND EAX, 0FFFFh
    CMP EAX, 1
    JGE >.cw_ok
    MOV EAX, 1
.cw_ok:
    MOV [gClientW], EAX

    MOV EAX, [lParam]
    SHR EAX, 16
    AND EAX, 0FFFFh
    CMP EAX, 1
    JGE >.ch_ok
    MOV EAX, 1
.ch_ok:
    MOV [gClientH], EAX
    XOR RAX, RAX
    RET

.on_mousemove:
    MOV EAX, [lParam]
    MOVSX EAX, AX               ; signed client X
    IMUL EAX, SCREEN_W
    CDQ
    IDIV D[gClientW]
    CMP EAX, 0
    JGE >.mx_min_ok
    XOR EAX, EAX
.mx_min_ok:
    CMP EAX, SCREEN_W
    JLE >.mx_max_ok
    MOV EAX, SCREEN_W
.mx_max_ok:
    MOV [gMouseX], EAX
    MOV D[gUseMouse], 1
    XOR RAX, RAX
    RET

.on_keydown:
    MOV RAX, [wParam]
    CMP RAX, 255
    JA >.kd_chk_esc
    LEA RCX, [gKeyDown]
    MOV B[RCX + RAX], 1
.kd_chk_esc:
    MOV EAX, [wParam]
    CMP EAX, VK_ESCAPE
    JNE >.key_def
    MOV ECX, [gState]
    CMP ECX, STATE_PLAYING
    JNE >.esc_not_play
    MOV D[gState], STATE_PAUSED
    XOR RAX, RAX
    RET
.esc_not_play:
    CMP ECX, STATE_PAUSED
    JNE >.esc_quit
    MOV D[gState], STATE_PLAYING
    XOR RAX, RAX
    RET
.esc_quit:
    INVOKE DestroyWindow, [hwnd]
    XOR RAX, RAX
    RET
.key_def:
    INVOKE DefWindowProcA, [hwnd], [uMsg], [wParam], [lParam]
    RET

.on_keyup:
    MOV RAX, [wParam]
    CMP RAX, 255
    JA >.ku_done
    LEA RCX, [gKeyDown]
    MOV B[RCX + RAX], 0
.ku_done:
    XOR RAX, RAX
    RET

.on_lbtn_down:
    MOV B[gKeyDown + VK_LBUTTON], 1
    XOR RAX, RAX
    RET

.on_lbtn_up:
    MOV B[gKeyDown + VK_LBUTTON], 0
    XOR RAX, RAX
    RET

.on_killfocus:
    LEA RDI, [gKeyDown]
    XOR EAX, EAX
    MOV ECX, 64
    REP STOSD
    XOR RAX, RAX
    RET

.on_paint:
    INVOKE BeginPaint, [hwnd], ADDR gPs
    INVOKE PresentBuffer, RAX
    INVOKE EndPaint, [hwnd], ADDR gPs
    XOR RAX, RAX
    RET

.on_close:
    MOV D[gRunning], 0
    INVOKE DestroyWindow, [hwnd]
    XOR RAX, RAX
    RET

.on_destroy:
    MOV D[gRunning], 0
    INVOKE PostQuitMessage, 0
    XOR RAX, RAX
    RET
ENDF

; -----------------------------------------------------------------------------
; GameMain: Initializes subsystems, creates window, and runs 60Hz loop
; -----------------------------------------------------------------------------
GameMain FRAME
USES RBX, RSI, RDI, R12, R13
LOCAL rcAdj:RECT, curTick, winX, winY, winW, winH, hdc

    ; Enable DPI awareness so laptop scaling doesn't blur or overflow
    INVOKE SetProcessDPIAware

    INVOKE GetModuleHandleA, 0
    MOV [gHInst], RAX

    ; Seed PRNG with performance counter
    INVOKE QueryPerformanceCounter, ADDR gLastTick
    MOV RAX, [gLastTick]
    OR RAX, 1
    XOR [gPrngState], RAX

    ; Initialize Audio WAVs, DIB Framebuffer & Static Background Cache
    CALL InitAudio

    MOV D[gBmi + BITMAPINFOHEADER.biSize], SIZEOF BITMAPINFOHEADER
    MOV D[gBmi + BITMAPINFOHEADER.biWidth], SCREEN_W
    MOV D[gBmi + BITMAPINFOHEADER.biHeight], -SCREEN_H
    MOV W[gBmi + BITMAPINFOHEADER.biPlanes], 1
    MOV W[gBmi + BITMAPINFOHEADER.biBitCount], 32
    MOV D[gBmi + BITMAPINFOHEADER.biCompression], BI_RGB

    INVOKE CreateDIBSection, 0, ADDR gBmi, DIB_RGB_COLORS, ADDR gPixels, 0, 0
    TEST RAX, RAX
    JZ >>.exit_err
    MOV [gDIB], RAX

    CALL InitBackgroundCache

    ; Load Level 0 data for clean background preview behind Title Screen
    INVOKE LoadLevel, 0
    MOV D[gState], STATE_TITLE

    ; Register Window Class
    MOV D[gWc + WNDCLASSEXA.cbSize], SIZEOF WNDCLASSEXA
    MOV D[gWc + WNDCLASSEXA.style], CS_HREDRAW + CS_VREDRAW + CS_OWNDC
    LEA RAX, [WndProc]
    MOV [gWc + WNDCLASSEXA.lpfnWndProc], RAX
    MOV RAX, [gHInst]
    MOV [gWc + WNDCLASSEXA.hInstance], RAX
    INVOKE LoadIconA, 0, IDI_APPLICATION
    MOV [gWc + WNDCLASSEXA.hIcon], RAX
    MOV [gWc + WNDCLASSEXA.hIconSm], RAX
    INVOKE LoadCursorA, 0, IDC_ARROW
    MOV [gWc + WNDCLASSEXA.hCursor], RAX
    MOV Q[gWc + WNDCLASSEXA.hbrBackground], 0
    LEA RAX, [szClassName]
    MOV [gWc + WNDCLASSEXA.lpszClassName], RAX

    INVOKE RegisterClassExA, ADDR gWc
    TEST AX, AX
    JZ >>.exit_err

    ; Calculate window dimensions fitting inside desktop work area
    INVOKE SystemParametersInfoA, SPI_GETWORKAREA, 0, ADDR gRcWork, 0
    MOV D[rcAdj + RECT.left], 0
    MOV D[rcAdj + RECT.top], 0
    MOV D[rcAdj + RECT.right], SCREEN_W
    MOV D[rcAdj + RECT.bottom], SCREEN_H
    INVOKE AdjustWindowRect, ADDR rcAdj, WS_OVERLAPPEDWINDOW, 0

    MOV EAX, [rcAdj + RECT.right]
    SUB EAX, [rcAdj + RECT.left]
    MOV [winW], EAX

    MOV ECX, [rcAdj + RECT.bottom]
    SUB ECX, [rcAdj + RECT.top]
    MOV [winH], ECX

    ; Clamp if laptop work area height/width is smaller than 960x720 + frame
    MOV R12D, [gRcWork + RECT.right]
    SUB R12D, [gRcWork + RECT.left]
    MOV R13D, [gRcWork + RECT.bottom]
    SUB R13D, [gRcWork + RECT.top]

    CMP [winH], R13D
    JLE >.fit_w
    MOV EAX, R13D
    SUB EAX, 24
    MOV [winH], EAX
    ; Maintain 4:3 aspect roughly: winW = winH * 4 / 3
    IMUL EAX, EAX, 4
    XOR EDX, EDX
    MOV ECX, 3
    DIV ECX
    MOV [winW], EAX
.fit_w:
    CMP [winW], R12D
    JLE >.center_win
    MOV EAX, R12D
    SUB EAX, 24
    MOV [winW], EAX

.center_win:
    MOV EAX, R12D
    SUB EAX, [winW]
    SAR EAX, 1
    ADD EAX, [gRcWork + RECT.left]
    MOV [winX], EAX

    MOV EAX, R13D
    SUB EAX, [winH]
    SAR EAX, 1
    ADD EAX, [gRcWork + RECT.top]
    MOV [winY], EAX

    INVOKE CreateWindowExA, 0, ADDR szClassName, ADDR szWindowTitle, \
           10CF0000h, \
           [winX], [winY], [winW], [winH], 0, 0, [gHInst], 0
    TEST RAX, RAX
    JZ >>.exit_err
    MOV [gHwnd], RAX

    INVOKE ShowWindow, RAX, SW_SHOWNORMAL
    INVOKE UpdateWindow, [gHwnd]

    ; Setup high-res timing
    INVOKE timeBeginPeriod, 1
    INVOKE QueryPerformanceFrequency, ADDR gFreq
    INVOKE QueryPerformanceCounter, ADDR gLastTick

    CALL RenderFrame

; --- Main Message & Fixed-Timestep Game Loop ---
.main_loop:
    CMP D[gRunning], 0
    JE >>.cleanup

.msg_pump:
    INVOKE PeekMessageA, ADDR gMsg, 0, 0, 0, PM_REMOVE
    TEST EAX, EAX
    JZ >.after_msgs
    CMP D[gMsg + MSGSTRUCT.message], WM_QUIT
    JE >>.cleanup
    INVOKE TranslateMessage, ADDR gMsg
    INVOKE DispatchMessageA, ADDR gMsg
    JMP <.msg_pump

.after_msgs:
    INVOKE QueryPerformanceCounter, ADDR curTick
    MOV RAX, [curTick]
    SUB RAX, [gLastTick]
    MOV RCX, [curTick]
    MOV [gLastTick], RCX

    CVTSI2SD XMM0, RAX
    CVTSI2SD XMM1, Q[gFreq]
    DIVSD XMM0, XMM1            ; elapsed seconds

    UCOMISD XMM0, [fMaxFrameDelta]
    JBE >.dt_ok
    MOVSD XMM0, [fMaxFrameDelta]
.dt_ok:
    ADDSD XMM0, [gAccumSec]
    MOVSD [gAccumSec], XMM0

    XOR EBX, EBX                ; updated flag
.step_loop:
    MOVSD XMM0, [gAccumSec]
    UCOMISD XMM0, [fFrameStep]
    JB >.after_steps
    SUBSD XMM0, [fFrameStep]
    MOVSD [gAccumSec], XMM0
    CALL UpdateGame
    MOV EBX, 1
    JMP <.step_loop

.after_steps:
    TEST EBX, EBX
    JZ >.idle_sleep
    CALL RenderFrame
    INVOKE GetDC, [gHwnd]
    TEST RAX, RAX
    JZ >.idle_sleep
    MOV [hdc], RAX
    INVOKE PresentBuffer, RAX
    INVOKE ReleaseDC, [gHwnd], [hdc]
    JMP <.main_loop

.idle_sleep:
    INVOKE Sleep, 1
    JMP <<.main_loop

.cleanup:
    INVOKE timeEndPeriod, 1
    INVOKE PlaySoundA, 0, 0, 0
    CMP Q[gDIB], 0
    JE >.no_dib
    INVOKE DeleteObject, [gDIB]
.no_dib:
    INVOKE UnregisterClassA, ADDR szClassName, [gHInst]
    XOR EAX, EAX
    RET

.exit_err:
    MOV EAX, 1
    RET
ENDF

; -----------------------------------------------------------------------------
; Process Entry Point (Win64 ABI aligned call to GameMain)
; -----------------------------------------------------------------------------
START:
    SUB RSP, 28h
    CALL GameMain
    ADD RSP, 28h
    INVOKE ExitProcess, EAX
