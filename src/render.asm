; =============================================================================
; render.asm - 32-bpp Software Framebuffer, Pixel Font & Arcade GFX (GoAsm x64)
; =============================================================================

#include constants.inc

CODE SECTION

; -----------------------------------------------------------------------------
; PutPixel(x, y, color): Clipped single pixel write to gPixels
; -----------------------------------------------------------------------------
PutPixel FRAME px, py, col
    MOV EAX, [px]
    CMP EAX, 0
    JL >>.done
    CMP EAX, SCREEN_W
    JGE >>.done
    MOV ECX, [py]
    CMP ECX, 0
    JL >>.done
    CMP ECX, SCREEN_H
    JGE >.done

    MOVSXD RDX, ECX
    IMUL RDX, RDX, SCREEN_W
    MOVSXD RAX, EAX
    ADD RDX, RAX
    SHL RDX, 2
    ADD RDX, [gPixels]
    MOV EAX, [col]
    MOV [RDX], EAX
.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; FillRectBuf(pBuf, x, y, w, h, color): Clipped filled rectangle into pBuf
; -----------------------------------------------------------------------------
FillRectBuf FRAME pBuf, rx, ry, rw, rh, col
USES RDI, RBX, R12, R13

    MOV R8D, [rx]
    MOV R9D, [ry]
    MOV R10D, [rw]
    MOV R11D, [rh]
    ADD R10D, R8D               ; x1
    ADD R11D, R9D               ; y1

    ; Clip to [0..SCREEN_W] x [0..SCREEN_H]
    CMP R8D, 0
    JGE >.x0_ok
    XOR R8D, R8D
.x0_ok:
    CMP R9D, 0
    JGE >.y0_ok
    XOR R9D, R9D
.y0_ok:
    CMP R10D, SCREEN_W
    JLE >.x1_ok
    MOV R10D, SCREEN_W
.x1_ok:
    CMP R11D, SCREEN_H
    JLE >.y1_ok
    MOV R11D, SCREEN_H
.y1_ok:
    SUB R10D, R8D               ; clipped width
    CMP R10D, 0
    JLE >>.done
    SUB R11D, R9D               ; clipped height
    CMP R11D, 0
    JLE >>.done

    MOV EAX, [col]
    MOVSXD R12, R9D
    IMUL R12, R12, SCREEN_W
    MOVSXD RBX, R8D
    ADD R12, RBX
    SHL R12, 2
    ADD R12, [pBuf]             ; R12 = row start pointer

    MOV R13D, SCREEN_W * 4

.row_loop:
    MOV RDI, R12
    MOV ECX, R10D
    REP STOSD
    ADD R12, R13
    DEC R11D
    JNZ <.row_loop

.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; FillRect(x, y, w, h, color): Draws clipped solid rect to gPixels
; -----------------------------------------------------------------------------
FillRect FRAME rx, ry, rw, rh, col
    INVOKE FillRectBuf, [gPixels], [rx], [ry], [rw], [rh], [col]
    RET
ENDF

; -----------------------------------------------------------------------------
; DrawRectOutline(x, y, w, h, color)
; -----------------------------------------------------------------------------
DrawRectOutline FRAME rx, ry, rw, rh, col
USES RBX, RDI, R12, R13, R14, R15
    MOV R12D, [rx]
    MOV R13D, [ry]
    MOV R14D, [rw]
    MOV R15D, [rh]
    MOV EBX, [col]

    INVOKE FillRect, R12D, R13D, R14D, 1, EBX
    MOV EAX, R13D
    ADD EAX, R15D
    DEC EAX
    INVOKE FillRect, R12D, EAX, R14D, 1, EBX
    INVOKE FillRect, R12D, R13D, 1, R15D, EBX
    MOV EAX, R12D
    ADD EAX, R14D
    DEC EAX
    INVOKE FillRect, EAX, R13D, 1, R15D, EBX
    RET
ENDF

; -----------------------------------------------------------------------------
; FillBevelRectBuf(pBuf, x, y, w, h, mainCol, lightCol, darkCol)
; -----------------------------------------------------------------------------
FillBevelRectBuf FRAME pBuf, rx, ry, rw, rh, mainCol, lightCol, darkCol
USES RBX, RDI, R12, R13, R14, R15

    MOV R12D, [rx]
    MOV R13D, [ry]
    MOV R14D, [rw]
    MOV R15D, [rh]
    MOV RBX, [pBuf]

    ; Outer dark border
    INVOKE FillRectBuf, RBX, R12D, R13D, R14D, R15D, 000B0F1Ch
    ; Inner body
    MOV EAX, R12D
    INC EAX
    MOV ECX, R13D
    INC ECX
    MOV EDX, R14D
    SUB EDX, 2
    MOV R8D, R15D
    SUB R8D, 2
    INVOKE FillRectBuf, RBX, EAX, ECX, EDX, R8D, [mainCol]

    ; Top & Left 2px highlight
    MOV EAX, R12D
    INC EAX
    MOV ECX, R13D
    INC ECX
    MOV EDX, R14D
    SUB EDX, 2
    INVOKE FillRectBuf, RBX, EAX, ECX, EDX, 2, [lightCol]

    MOV EAX, R12D
    INC EAX
    MOV ECX, R13D
    INC ECX
    MOV R8D, R15D
    SUB R8D, 2
    INVOKE FillRectBuf, RBX, EAX, ECX, 2, R8D, [lightCol]

    ; Bottom & Right 2px shadow
    MOV EAX, R12D
    INC EAX
    MOV ECX, R13D
    ADD ECX, R15D
    SUB ECX, 3
    MOV EDX, R14D
    SUB EDX, 2
    INVOKE FillRectBuf, RBX, EAX, ECX, EDX, 2, [darkCol]

    MOV EAX, R12D
    ADD EAX, R14D
    SUB EAX, 3
    MOV ECX, R13D
    INC ECX
    MOV R8D, R15D
    SUB R8D, 2
    INVOKE FillRectBuf, RBX, EAX, ECX, 2, R8D, [darkCol]

    RET
ENDF

; -----------------------------------------------------------------------------
; DrawCircle(cx, cy, r, color): Clipped filled circle to gPixels
; -----------------------------------------------------------------------------
DrawCircle FRAME argX, argY, r, col
USES RBX, RDI, R12, R13, R14, R15

    MOV R12D, [r]
    CMP R12D, 0
    JLE >>.done
    MOV R13D, R12D
    IMUL R13D, R13D             ; r^2
    MOV EBX, [col]

    MOV R14D, R12D
    NEG R14D                    ; dy = -r..r
.dy_loop:
    CMP R14D, R12D
    JG >>.done

    MOV R15D, R12D
    NEG R15D                    ; dx = -r..r
.dx_loop:
    CMP R15D, R12D
    JG >>.next_dy

    MOV EAX, R15D
    IMUL EAX, EAX
    MOV ECX, R14D
    IMUL ECX, ECX
    ADD EAX, ECX
    CMP EAX, R13D
    JG >.next_dx

    MOV EAX, [argX]
    ADD EAX, R15D
    MOV ECX, [argY]
    ADD ECX, R14D
    INVOKE PutPixel, EAX, ECX, EBX

.next_dx:
    INC R15D
    JMP <.dx_loop
.next_dy:
    INC R14D
    JMP <.dy_loop
.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; DrawRing(cx, cy, rOuter, rInner, color): Filled circular ring
; -----------------------------------------------------------------------------
DrawRing FRAME argX, argY, rOut, rIn, col
USES RBX, RDI, R12, R13, R14, R15
LOCAL rOutSq, rInSq

    MOV R12D, [rOut]
    MOV EAX, R12D
    IMUL EAX, EAX
    MOV [rOutSq], EAX

    MOV EAX, [rIn]
    IMUL EAX, EAX
    MOV [rInSq], EAX
    MOV EBX, [col]

    MOV R14D, R12D
    NEG R14D
.dy_loop:
    CMP R14D, R12D
    JG >>.done
    MOV R15D, R12D
    NEG R15D
.dx_loop:
    CMP R15D, R12D
    JG >>.next_dy
    MOV EAX, R15D
    IMUL EAX, EAX
    MOV ECX, R14D
    IMUL ECX, ECX
    ADD EAX, ECX
    CMP EAX, [rOutSq]
    JG >.next_dx
    CMP EAX, [rInSq]
    JL >.next_dx

    MOV EAX, [argX]
    ADD EAX, R15D
    MOV ECX, [argY]
    ADD ECX, R14D
    INVOKE PutPixel, EAX, ECX, EBX
.next_dx:
    INC R15D
    JMP <.dx_loop
.next_dy:
    INC R14D
    JMP <.dy_loop
.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; DrawChar5x7Buf(pBuf, x, y, ch, scale, color)
; -----------------------------------------------------------------------------
DrawChar5x7Buf FRAME pBuf, x, y, charCode, scale, col
USES RBX, RSI, R12, R13, R14, R15

    MOV EAX, [charCode]
    ; Convert lowercase a..z to uppercase A..Z
    CMP EAX, 'a'
    JL >.not_lower
    CMP EAX, 'z'
    JG >.not_lower
    SUB EAX, 32
.not_lower:
    CMP EAX, 32
    JL >.use_space
    CMP EAX, 95
    JLE >.char_ok
.use_space:
    MOV EAX, 32
.char_ok:
    SUB EAX, 32
    IMUL EAX, EAX, 7
    LEA RSI, [gFont5x7]
    ADD RSI, RAX                ; RSI -> 7 bytes for glyph

    MOV R12D, [scale]
    XOR R13D, R13D              ; row = 0..6
.row_loop:
    CMP R13D, 7
    JGE >>.done
    MOVZX EBX, B[RSI + R13]     ; 5-bit row mask
    TEST EBX, EBX
    JZ >>.next_row

    XOR R14D, R14D              ; col = 0..4
.col_loop:
    CMP R14D, 5
    JGE >>.next_row
    MOV ECX, 4
    SUB ECX, R14D
    BT EBX, ECX
    JNC >.next_col

    ; Draw scale x scale block at (x + col*scale, y + row*scale)
    MOV EAX, R14D
    IMUL EAX, R12D
    ADD EAX, [x]
    MOV R15D, R13D
    IMUL R15D, R12D
    ADD R15D, [y]
    INVOKE FillRectBuf, [pBuf], EAX, R15D, R12D, R12D, [col]

.next_col:
    INC R14D
    JMP <.col_loop

.next_row:
    INC R13D
    JMP <.row_loop

.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; DrawTextBuf(pBuf, x, y, pStr, scale, color)
; -----------------------------------------------------------------------------
DrawTextBuf FRAME pBuf, x, y, pStr, scale, col
USES RBX, RSI, R12, R13
    MOV RSI, [pStr]
    MOV R12D, [x]
    MOV R13D, [scale]
    IMUL EBX, R13D, 6           ; char pitch = 6 * scale
.loop:
    MOVZX EAX, B[RSI]
    TEST EAX, EAX
    JZ >.done
    INVOKE DrawChar5x7Buf, [pBuf], R12D, [y], EAX, R13D, [col]
    ADD R12D, EBX
    INC RSI
    JMP <.loop
.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; DrawTextCentered(cx, y, pStr, scale, color)
; -----------------------------------------------------------------------------
DrawTextCentered FRAME argX, y, pStr, scale, col
    MOV RAX, [pStr]
    XOR ECX, ECX
.len_loop:
    CMP B[RAX + RCX], 0
    JE >.len_done
    INC ECX
    JMP <.len_loop
.len_done:
    TEST ECX, ECX
    JZ >.done
    IMUL EAX, ECX, 6
    DEC EAX
    IMUL EAX, [scale]
    SHR EAX, 1
    MOV EDX, [argX]
    SUB EDX, EAX
    INVOKE DrawTextBuf, [gPixels], EDX, [y], [pStr], [scale], [col]
.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; IntToStr(val, pOutBuf): Formats non-negative integer into ASCII string
; -----------------------------------------------------------------------------
IntToStr FRAME val, pOutBuf
USES RBX, RDI
LOCAL tmp[16]:B
    MOV EAX, [val]
    CMP EAX, 0
    JGE >.pos_ok
    XOR EAX, EAX
.pos_ok:
    MOV RDI, [pOutBuf]
    TEST EAX, EAX
    JNZ >.digits
    MOV B[RDI], '0'
    MOV B[RDI + 1], 0
    RET
.digits:
    XOR ECX, ECX
    MOV EBX, 10
    LEA R8, [tmp]
.div_loop:
    XOR EDX, EDX
    DIV EBX
    ADD DL, '0'
    MOV [R8 + RCX], DL
    INC ECX
    TEST EAX, EAX
    JNZ <.div_loop

    XOR EDX, EDX
.rev_loop:
    DEC ECX
    MOV AL, [R8 + RCX]
    MOV [RDI + RDX], AL
    INC EDX
    TEST ECX, ECX
    JNZ <.rev_loop
    MOV B[RDI + RDX], 0
    RET
ENDF

; -----------------------------------------------------------------------------
; InitBackgroundCache: Allocates & pre-renders static gradient, grid, borders, legend
; -----------------------------------------------------------------------------
InitBackgroundCache FRAME
USES RBX, RDI, R12, R13, R14

    INVOKE VirtualAlloc, 0, 2764800, MEM_COMMIT + MEM_RESERVE, PAGE_READWRITE
    TEST RAX, RAX
    JZ >>.done
    MOV [gBgPixels], RAX
    MOV R12, RAX

    ; 1. Fill vertical space gradient across entire 960x720 buffer
    XOR R13D, R13D              ; y = 0..719
.grad_y:
    CMP R13D, SCREEN_H
    JGE >>.grid_lines

    ; Compute row color: R = 10 + y*12/720, G = 14 + y*16/720, B = 26 + y*28/720
    MOV EAX, R13D
    IMUL EAX, 12
    XOR EDX, EDX
    MOV ECX, SCREEN_H
    DIV ECX
    ADD EAX, 10
    MOV R14D, EAX
    SHL R14D, 16                ; R << 16

    MOV EAX, R13D
    IMUL EAX, 16
    XOR EDX, EDX
    MOV ECX, SCREEN_H
    DIV ECX
    ADD EAX, 14
    SHL EAX, 8
    OR R14D, EAX                ; G << 8

    MOV EAX, R13D
    IMUL EAX, 28
    XOR EDX, EDX
    MOV ECX, SCREEN_H
    DIV ECX
    ADD EAX, 26
    OR R14D, EAX                ; B

    MOV EAX, R13D
    IMUL EAX, SCREEN_W
    SHL EAX, 2
    LEA RDI, [R12 + RAX]
    MOV EAX, R14D
    MOV ECX, SCREEN_W
    REP STOSD

    INC R13D
    JMP <.grad_y

.grid_lines:
    ; Subtle dark cyber grid inside arena
    MOV R13D, ARENA_LEFT + 48
.gx_loop:
    CMP R13D, ARENA_RIGHT
    JGE >.gy_init
    INVOKE FillRectBuf, R12, R13D, ARENA_TOP, 1, 600, 0018223Bh
    ADD R13D, 48
    JMP <.gx_loop

.gy_init:
    MOV R13D, ARENA_TOP + 48
.gy_loop:
    CMP R13D, ARENA_BOTTOM
    JGE >.borders
    INVOKE FillRectBuf, R12, ARENA_LEFT, R13D, ARENA_W, 1, 0018223Bh
    ADD R13D, 48
    JMP <.gy_loop

.borders:
    ; Top HUD panel background & separator
    INVOKE FillRectBuf, R12, 0, 0, SCREEN_W, HUD_H, COL_HUD_BG
    INVOKE FillRectBuf, R12, 0, HUD_H, SCREEN_W, 2, COL_HUD_LINE

    ; Glowing Arena Rails (Left, Right, Top)
    INVOKE FillRectBuf, R12, 16, HUD_H, 8, 644, COL_WALL_EDGE
    INVOKE FillRectBuf, R12, 22, 78, 2, 606, COL_WALL_GLOW
    INVOKE FillRectBuf, R12, ARENA_RIGHT, HUD_H, 8, 644, COL_WALL_EDGE
    INVOKE FillRectBuf, R12, ARENA_RIGHT, 78, 2, 606, COL_WALL_GLOW
    INVOKE FillRectBuf, R12, 16, 78, 928, 4, COL_WALL_EDGE
    INVOKE FillRectBuf, R12, 22, 81, 916, 2, COL_WALL_GLOW

    ; Bottom Color Legend Bar (y = 684..720)
    INVOKE FillRectBuf, R12, 0, LEGEND_Y, SCREEN_W, 36, COL_HUD_BG
    INVOKE FillRectBuf, R12, 0, LEGEND_Y, SCREEN_W, 2, COL_HUD_LINE

    ; Draw color-coded brick swatches in legend bar (y = 694)
    INVOKE FillBevelRectBuf, R12, 28, 695, 16, 12, 0028E66Bh, 0085FFB0h, 00127D38h
    INVOKE DrawTextBuf, R12, 48, 697, ADDR strLeg1, 1, COL_GREEN

    INVOKE FillBevelRectBuf, R12, 108, 695, 16, 12, 00FFC420h, 00FFE885h, 00996B00h
    INVOKE DrawTextBuf, R12, 128, 697, ADDR strLeg2, 1, COL_GOLD

    INVOKE FillBevelRectBuf, R12, 182, 695, 16, 12, 00FF6B1Ah, 00FFB078h, 00963100h
    INVOKE DrawTextBuf, R12, 202, 697, ADDR strLeg3, 1, COL_ORANGE

    INVOKE FillBevelRectBuf, R12, 268, 695, 16, 12, 00EB223Dh, 00FF8093h, 00870B1Ch
    INVOKE DrawTextBuf, R12, 288, 697, ADDR strLeg4, 1, COL_RED

    INVOKE FillBevelRectBuf, R12, 342, 695, 16, 12, 00A435FFh, 00D699FFh, 00521099h
    INVOKE DrawTextBuf, R12, 362, 697, ADDR strLeg5, 1, COL_VIOLET

    INVOKE FillBevelRectBuf, R12, 428, 695, 16, 12, COL_STEEL, COL_STEEL_HI, COL_STEEL_LO
    INVOKE DrawTextBuf, R12, 448, 697, ADDR strLegSteel, 1, COL_STEEL_HI

    INVOKE FillBevelRectBuf, R12, 496, 695, 16, 12, COL_CYAN, COL_WHITE, 00006688h
    INVOKE DrawTextBuf, R12, 516, 697, ADDR strLegRegen, 1, COL_CYAN

    INVOKE FillBevelRectBuf, R12, 570, 695, 16, 12, COL_MAGENTA, COL_YELLOW, 00660033h
    INVOKE DrawTextBuf, R12, 590, 697, ADDR strLegTnt, 1, COL_MAGENTA

    INVOKE DrawTextBuf, R12, 628, 697, ADDR strControlsBar, 1, COL_TEXT_DIM

.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; DrawPowerupBar(x, y, timer, maxTimer, pLabel, color)
; -----------------------------------------------------------------------------
DrawPowerupBar FRAME brkX, brkY, timer, maxTimer, pLabel, col
    CMP D[timer], 0
    JLE >>.done
    CMP D[maxTimer], 0
    JLE >>.done
    INVOKE DrawTextBuf, [gPixels], [brkX], [brkY], [pLabel], 1, [col]
    MOV EAX, [brkX]
    ADD EAX, 40
    INVOKE FillRect, EAX, [brkY], 48, 7, 001E2842h
    MOV EAX, [timer]
    IMUL EAX, 46
    XOR EDX, EDX
    DIV D[maxTimer]
    CMP EAX, 2
    JGE >.w_ok
    MOV EAX, 2
.w_ok:
    MOV ECX, [brkX]
    ADD ECX, 41
    MOV EDX, [brkY]
    INC EDX
    INVOKE FillRect, ECX, EDX, EAX, 5, [col]
.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; DrawHUD: Top status bar (Score, Best, Level, Lives, Gimmick, Powerup timers)
; -----------------------------------------------------------------------------
DrawHUD FRAME
USES RBX, R12

    ; Row 1 (y = 10): SCORE, BEST, LVL, COMBO, LIVES, SFX
    INVOKE DrawTextBuf, [gPixels], 24, 10, ADDR strScoreLbl, 2, COL_TEXT_DIM
    INVOKE IntToStr, [gScore], ADDR gStrBuf
    INVOKE DrawTextBuf, [gPixels], 92, 10, ADDR gStrBuf, 2, COL_WHITE

    INVOKE DrawTextBuf, [gPixels], 220, 10, ADDR strBestLbl, 2, COL_TEXT_DIM
    INVOKE IntToStr, [gHighScore], ADDR gStrBuf
    INVOKE DrawTextBuf, [gPixels], 276, 10, ADDR gStrBuf, 2, COL_GOLD

    INVOKE DrawTextBuf, [gPixels], 400, 10, ADDR strLevelLbl, 2, COL_TEXT_DIM
    MOV EAX, [gLevel]
    INC EAX
    INVOKE IntToStr, EAX, ADDR gStrBuf
    MOV B[gStrBuf + 1], '/'
    MOV B[gStrBuf + 2], '8'
    MOV B[gStrBuf + 3], 0
    INVOKE DrawTextBuf, [gPixels], 442, 10, ADDR gStrBuf, 2, COL_CYAN

    ; Combo badge if combo >= 2
    CMP D[gCombo], 2
    JL >>.no_combo
    INVOKE DrawTextBuf, [gPixels], 505, 10, ADDR strComboLbl, 2, COL_ORANGE
    INVOKE IntToStr, [gCombo], ADDR gStrBuf
    INVOKE DrawTextBuf, [gPixels], 572, 10, ADDR gStrBuf, 2, COL_YELLOW
.no_combo:

    ; Lives mini-paddles (x = 630..)
    INVOKE DrawTextBuf, [gPixels], 628, 10, ADDR strLivesLbl, 2, COL_TEXT_DIM
    XOR EBX, EBX
.lives_loop:
    CMP EBX, [gLives]
    JGE >.lives_done
    MOV EAX, EBX
    IMUL EAX, 26
    ADD EAX, 696
    INVOKE FillBevelRectBuf, [gPixels], EAX, 12, 22, 8, COL_CYAN, COL_WHITE, 00007799h
    INC EBX
    JMP <.lives_loop
.lives_done:

    ; Sound status badge
    CMP D[gMuted], 0
    JNE >.muted_lbl
    INVOKE DrawTextBuf, [gPixels], 856, 14, ADDR strSoundOn, 2, COL_GREEN
    JMP >.row2
.muted_lbl:
    INVOKE DrawTextBuf, [gPixels], 840, 14, ADDR strSoundOff, 2, COL_RED

.row2:
    ; Row 2 (y = 38 & 56): Level Name + Active Gimmick!
    MOV EAX, [gLevel]
    LEA RBX, [gLevelNames]
    MOV R12, [RBX + RAX*8]
    INVOKE DrawTextBuf, [gPixels], 24, 36, R12, 2, COL_WHITE

    MOV EAX, [gLevel]
    LEA RBX, [gLevelGimmicks]
    MOV R12, [RBX + RAX*8]
    INVOKE DrawTextBuf, [gPixels], 24, 56, R12, 2, COL_CYAN

    ; Active powerup countdown bars on right side of HUD
    INVOKE DrawPowerupBar, 660, 38, [gWideTimer], 720, ADDR strPwrWide, COL_CYAN
    INVOKE DrawPowerupBar, 765, 38, [gFireTimer], 600, ADDR strPwrFire, COL_ORANGE
    INVOKE DrawPowerupBar, 865, 38, [gLaserTimer], 660, ADDR strPwrLaser, COL_YELLOW
    INVOKE DrawPowerupBar, 660, 56, [gSlowTimer], 600, ADDR strPwrSlow, COL_SKY
    INVOKE DrawPowerupBar, 765, 56, [gShieldTimer], 720, ADDR strPwrShield, COL_GOLD

    RET
ENDF

; -----------------------------------------------------------------------------
; DrawGravityWell: Animated purple vortex field for Level 7
; -----------------------------------------------------------------------------
DrawGravityWell FRAME
USES RBX
    CMP D[gGravityActive], 0
    JE >>.done

    ; Pulse radius smoothly using (gFrameCount & 31)
    MOV EAX, [gFrameCount]
    AND EAX, 31
    IMUL EAX, EAX, 3
    MOV EBX, 138
    SUB EBX, EAX                ; shrinks 138 -> 45
    CMP EBX, 20
    JL >.inner_core
    LEA EAX, [EBX - 2]
    INVOKE DrawRing, 480, 390, EBX, EAX, 006A28B5h

.inner_core:
    INVOKE DrawRing, 480, 390, 138, 136, 004D1E85h
    INVOKE DrawRing, 480, 390, 88, 86, 00722EC4h
    INVOKE DrawCircle, 480, 390, 14, COL_VIOLET
    INVOKE DrawCircle, 480, 390, 7, COL_MAGENTA
    INVOKE DrawCircle, 480, 390, 3, COL_WHITE
.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; DrawPortals: Animated warp rings for Level 4 & Level 8
; -----------------------------------------------------------------------------
DrawPortals FRAME
USES RBX, R12, R13, R14
    CMP D[gHasPortals], 0
    JE >>.done

    LEA RBX, [gPortals]
    XOR R12D, R12D
.loop:
    CMP R12D, MAX_PORTALS
    JGE >>.done
    CMP D[RBX + PORTAL.active], 0
    JE >>.next

    CVTTSD2SI R13D, [RBX + PORTAL.x]
    CVTTSD2SI R14D, [RBX + PORTAL.y]

    ; Pulsing outer ring
    MOV EAX, [gFrameCount]
    SHR EAX, 2
    AND EAX, 3
    ADD EAX, 18
    MOV ECX, EAX
    SUB ECX, 4
    MOV EDX, [RBX + PORTAL.color]
    CMP D[RBX + PORTAL.flash], 0
    JLE >.no_fl
    MOV EDX, COL_WHITE
.no_fl:
    INVOKE DrawRing, R13D, R14D, EAX, ECX, EDX
    INVOKE DrawRing, R13D, R14D, 11, 8, COL_WHITE
    INVOKE DrawCircle, R13D, R14D, 5, 00090D1Ah

.next:
    ADD RBX, SIZEOF PORTAL
    INC R12D
    JMP <.loop
.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; DrawBumpers: Glowing pinball repulsor bumpers for Level 6
; -----------------------------------------------------------------------------
DrawBumpers FRAME
USES RBX, R12, R13, R14
    CMP D[gHasBumpers], 0
    JE >>.done

    LEA RBX, [gBumpers]
    XOR R12D, R12D
.loop:
    CMP R12D, MAX_BUMPERS
    JGE >>.done
    CMP D[RBX + BUMPER.active], 0
    JE >>.next

    CVTTSD2SI R13D, [RBX + BUMPER.x]
    CVTTSD2SI R14D, [RBX + BUMPER.y]

    CMP D[RBX + BUMPER.flash], 0
    JG >>.flash_draw

    INVOKE DrawCircle, R13D, R14D, 23, COL_MAGENTA
    INVOKE DrawCircle, R13D, R14D, 18, 002B1142h
    INVOKE DrawCircle, R13D, R14D, 12, COL_CYAN
    INVOKE DrawCircle, R13D, R14D, 5, COL_WHITE
    JMP >.next

.flash_draw:
    INVOKE DrawCircle, R13D, R14D, 26, COL_WHITE
    INVOKE DrawCircle, R13D, R14D, 16, COL_YELLOW

.next:
    ADD RBX, SIZEOF BUMPER
    INC R12D
    JMP <.loop
.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; DrawBricks: Draws all bricks colored strictly by remaining HP + gimmick icons
; -----------------------------------------------------------------------------
DrawBricks FRAME
USES RBX, RDI, R12, R13, R14, R15
LOCAL brkX, brkY, brkW, brkH, mainC, lightC, darkC

    LEA RBX, [gBricks]
    XOR R12D, R12D
.loop:
    CMP R12D, MAX_BRICKS
    JGE >>.done

    CMP D[RBX + BRICK.active], 0
    JE >>.next

    CVTTSD2SI R13D, [RBX + BRICK.x]
    CVTTSD2SI R14D, [RBX + BRICK.y]
    MOV [brkX], R13D
    MOV [brkY], R14D
    MOV EAX, [RBX + BRICK.w]
    MOV [brkW], EAX
    MOV EAX, [RBX + BRICK.h]
    MOV [brkH], EAX

    ; Select palette by btype / hp
    CMP D[RBX + BRICK.flash], 0
    JLE >.normal_pal
    MOV D[mainC], COL_WHITE
    MOV D[lightC], COL_WHITE
    MOV D[darkC], COL_CYAN
    JMP >>.draw_body

.normal_pal:
    CMP D[RBX + BRICK.btype], BRICK_STEEL
    JNE >.hp_pal
    MOV D[mainC], COL_STEEL
    MOV D[lightC], COL_STEEL_HI
    MOV D[darkC], COL_STEEL_LO
    JMP >>.draw_body

.hp_pal:
    MOV EAX, [RBX + BRICK.hp]
    CMP EAX, 1
    JGE >.hp_min_ok
    MOV EAX, 1
.hp_min_ok:
    CMP EAX, 5
    JLE >.hp_idx_ok
    MOV EAX, 5
.hp_idx_ok:
    LEA RCX, [gHpMainColors]
    MOV EDX, [RCX + RAX*4]
    MOV [mainC], EDX
    LEA RCX, [gHpLightColors]
    MOV EDX, [RCX + RAX*4]
    MOV [lightC], EDX
    LEA RCX, [gHpDarkColors]
    MOV EDX, [RCX + RAX*4]
    MOV [darkC], EDX

.draw_body:
    INVOKE FillBevelRectBuf, [gPixels], [brkX], [brkY], [brkW], [brkH], [mainC], [lightC], [darkC]

    ; --- Special Type Visual Markers ---
    MOV EAX, [RBX + BRICK.btype]
    CMP EAX, BRICK_STEEL
    JE >.decor_steel
    CMP EAX, BRICK_MOVING
    JE >>.decor_moving
    CMP EAX, BRICK_REGEN
    JE >>.decor_regen
    CMP EAX, BRICK_EXPLOSIVE
    JE >>.decor_tnt
    JMP >>.draw_pips

.decor_steel:
    ; 4 metallic corner rivets
    MOV EAX, [brkX]
    ADD EAX, 5
    MOV ECX, [brkY]
    ADD ECX, 5
    INVOKE FillRect, EAX, ECX, 3, 3, COL_STEEL_HI
    MOV EAX, [brkX]
    ADD EAX, [brkW]
    SUB EAX, 8
    MOV ECX, [brkY]
    ADD ECX, 5
    INVOKE FillRect, EAX, ECX, 3, 3, COL_STEEL_HI
    MOV EAX, [brkX]
    ADD EAX, [brkW]
    SUB EAX, 8
    MOV ECX, [brkY]
    ADD ECX, [brkH]
    SUB ECX, 8
    INVOKE FillRect, EAX, ECX, 3, 3, COL_STEEL_HI
    MOV EAX, [brkX]
    ADD EAX, 5
    MOV ECX, [brkY]
    ADD ECX, [brkH]
    SUB ECX, 8
    INVOKE FillRect, EAX, ECX, 3, 3, COL_STEEL_HI
    JMP >>.next

.decor_moving:
    ; Side motion indicator chevrons
    MOV EAX, [brkX]
    ADD EAX, 5
    MOV ECX, [brkY]
    ADD ECX, 9
    INVOKE FillRect, EAX, ECX, 3, 6, COL_WHITE
    MOV EAX, [brkX]
    ADD EAX, [brkW]
    SUB EAX, 8
    MOV ECX, [brkY]
    ADD ECX, 9
    INVOKE FillRect, EAX, ECX, 3, 6, COL_WHITE
    JMP >>.draw_pips

.decor_regen:
    ; Pulsing cyan/white + cross emblem in top-right
    MOV EAX, [gFrameCount]
    TEST EAX, 16
    MOV R15D, COL_CYAN
    JZ >.reg_c
    MOV R15D, COL_WHITE
.reg_c:
    MOV EAX, [brkX]
    ADD EAX, 8
    MOV ECX, [brkY]
    ADD ECX, 11
    INVOKE FillRect, EAX, ECX, 9, 3, R15D
    MOV EAX, [brkX]
    ADD EAX, 11
    MOV ECX, [brkY]
    ADD ECX, 8
    INVOKE FillRect, EAX, ECX, 3, 9, R15D
    JMP >>.draw_pips

.decor_tnt:
    ; Explosive hazard band + glowing yellow core
    MOV EAX, [brkX]
    ADD EAX, 10
    MOV ECX, [brkY]
    ADD ECX, 5
    MOV EDX, [brkW]
    SUB EDX, 20
    INVOKE DrawRectOutline, EAX, ECX, EDX, 14, COL_YELLOW
    MOV EAX, [brkX]
    ADD EAX, 30
    MOV ECX, [brkY]
    ADD ECX, 8
    INVOKE FillRect, EAX, ECX, 8, 8, COL_YELLOW

.draw_pips:
    ; Draw crisp hit pips showing exact remaining hits (1..5)
    MOV R15D, [RBX + BRICK.hp]
    CMP R15D, 1
    JL >>.draw_cracks
    CMP R15D, 5
    JLE >.pips_ok
    MOV R15D, 5
.pips_ok:
    ; Start X = bx + (bw - (hp*6 - 2)) / 2
    MOV EAX, R15D
    IMUL EAX, 6
    SUB EAX, 2
    MOV ECX, [brkW]
    SUB ECX, EAX
    SHR ECX, 1
    ADD ECX, [brkX]               ; pipX
    MOV R13D, ECX
    MOV R14D, [brkY]
    ADD R14D, [brkH]
    SUB R14D, 7                 ; pipY near bottom of brick

    XOR EDI, EDI
.pip_loop:
    CMP EDI, R15D
    JGE >.draw_cracks
    INVOKE FillRect, R13D, R14D, 4, 3, COL_WHITE
    ADD R13D, 6
    INC EDI
    JMP <.pip_loop

.draw_cracks:
    ; If damaged (hp < maxHp), draw dark crack notches on top/middle
    MOV EAX, [RBX + BRICK.hp]
    CMP EAX, [RBX + BRICK.maxHp]
    JGE >>.next
    MOV EAX, [brkX]
    ADD EAX, 18
    MOV ECX, [brkY]
    ADD ECX, 4
    INVOKE FillRect, EAX, ECX, 2, 5, COL_BLACK
    MOV EAX, [brkX]
    ADD EAX, 20
    MOV ECX, [brkY]
    ADD ECX, 8
    INVOKE FillRect, EAX, ECX, 4, 2, COL_BLACK
    MOV EAX, [brkX]
    ADD EAX, 42
    MOV ECX, [brkY]
    ADD ECX, 5
    INVOKE FillRect, EAX, ECX, 2, 6, COL_BLACK

.next:
    ADD RBX, SIZEOF BRICK
    INC R12D
    JMP <<.loop

.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; DrawBoss: Renders Level 8 Overlord Monolith + HP bar
; -----------------------------------------------------------------------------
DrawBoss FRAME
USES RBX, RDI, R12, R13, R14, R15
LOCAL mainC, lightC, darkC

    CMP D[gHasBoss], 0
    JE >>.done
    LEA RBX, [gBoss]
    CMP D[RBX + BOSS.active], 0
    JE >>.done

    CVTTSD2SI R12D, [RBX + BOSS.x]
    CVTTSD2SI R13D, [RBX + BOSS.y]
    MOV R14D, [RBX + BOSS.w]
    MOV R15D, [RBX + BOSS.h]

    ; Color tier by HP (1..5 mapped from 24 HP)
    MOV EAX, [RBX + BOSS.hp]
    ADD EAX, 4
    MOV ECX, 5
    XOR EDX, EDX
    DIV ECX                     ; tier 1..5
    CMP EAX, 1
    JGE >.t_ok
    MOV EAX, 1
.t_ok:
    CMP EAX, 5
    JLE >.t_max
    MOV EAX, 5
.t_max:
    CMP D[RBX + BOSS.flash], 0
    JLE >.boss_pal
    MOV D[mainC], COL_WHITE
    MOV D[lightC], COL_WHITE
    MOV D[darkC], COL_RED
    JMP >>.draw_hull

.boss_pal:
    LEA RCX, [gHpMainColors]
    MOV EDX, [RCX + RAX*4]
    MOV [mainC], EDX
    LEA RCX, [gHpLightColors]
    MOV EDX, [RCX + RAX*4]
    MOV [lightC], EDX
    LEA RCX, [gHpDarkColors]
    MOV EDX, [RCX + RAX*4]
    MOV [darkC], EDX

.draw_hull:
    INVOKE FillBevelRectBuf, [gPixels], R12D, R13D, R14D, R15D, [mainC], [lightC], [darkC]

    ; Glowing crimson core eye
    ADD R12D, 70
    ADD R13D, 20
    INVOKE DrawCircle, R12D, R13D, 11, COL_BLACK
    INVOKE DrawCircle, R12D, R13D, 8, COL_RED
    INVOKE DrawCircle, R12D, R13D, 4, COL_YELLOW

    ; Overhead Boss HP Bar at y = ARENA_TOP + 6
    INVOKE FillRect, 320, 88, 320, 12, 00161E33h
    INVOKE DrawRectOutline, 320, 88, 320, 12, COL_WHITE
    MOV EAX, [RBX + BOSS.hp]
    IMUL EAX, 316
    XOR EDX, EDX
    DIV D[RBX + BOSS.maxHp]
    CMP EAX, 2
    JGE >.bw_ok
    MOV EAX, 2
.bw_ok:
    INVOKE FillRect, 322, 90, EAX, 8, [mainC]
    INVOKE DrawTextCentered, 480, 90, ADDR strBossName, 1, COL_WHITE

.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; DrawPaddleAndShield: Safety floor barrier + glowing paddle + laser turrets
; -----------------------------------------------------------------------------
DrawPaddleAndShield FRAME
USES RBX, R12, R13

    ; Bottom Safety Shield if active
    CMP D[gShieldTimer], 0
    JLE >.draw_pad
    MOV EAX, [gFrameCount]
    TEST EAX, 8
    MOV EBX, COL_GOLD
    JZ >.sh_col
    MOV EBX, COL_YELLOW
.sh_col:
    INVOKE FillRect, ARENA_LEFT, 676, ARENA_W, 4, EBX
    INVOKE FillRect, ARENA_LEFT, 677, ARENA_W, 2, COL_WHITE

.draw_pad:
    ; Blink when invulnerable after taking hazard hit
    CMP D[gPadInvuln], 0
    JLE >.pad_vis
    TEST D[gPadInvuln], 4
    JNZ >>.done
.pad_vis:
    CVTTSD2SI R12D, [gPadCurW]  ; width
    CVTTSD2SI EBX, [gPadX]
    MOV EAX, R12D
    SHR EAX, 1
    SUB EBX, EAX                ; left X

    ; Choose paddle accent color
    MOV R13D, COL_CYAN
    CMP D[gPadStunTimer], 0
    JLE >.chk_fire_pad
    MOV R13D, COL_RED
    JMP >.pad_draw_rect
.chk_fire_pad:
    CMP D[gLaserTimer], 0
    JLE >.pad_draw_rect
    MOV R13D, COL_YELLOW

.pad_draw_rect:
    INVOKE FillBevelRectBuf, [gPixels], EBX, PADDLE_Y, R12D, PADDLE_H, 00385280h, 008AB4F8h, 001A2840h
    ; Glowing end caps
    LEA EAX, [EBX + 2]
    INVOKE FillRect, EAX, 650, 12, 12, R13D
    MOV EAX, EBX
    ADD EAX, R12D
    SUB EAX, 14
    INVOKE FillRect, EAX, 650, 12, 12, R13D
    ; Center energy core
    MOV EAX, EBX
    MOV ECX, R12D
    SHR ECX, 1
    ADD EAX, ECX
    SUB EAX, 12
    INVOKE FillRect, EAX, 653, 24, 6, COL_WHITE

    ; Laser cannons when LASER powerup active
    CMP D[gLaserTimer], 0
    JLE >>.done
    LEA EAX, [EBX + 4]
    INVOKE FillRect, EAX, 641, 4, 8, COL_YELLOW
    MOV EAX, EBX
    ADD EAX, R12D
    SUB EAX, 8
    INVOKE FillRect, EAX, 641, 4, 8, COL_YELLOW

.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; DrawBalls: Motion trails + glowing core / Fireball visuals
; -----------------------------------------------------------------------------
DrawBalls FRAME
USES RBX, RDI, R12, R13, R14, R15

    LEA RBX, [gBalls]
    XOR R12D, R12D
.loop:
    CMP R12D, MAX_BALLS
    JGE >>.done
    CMP D[RBX + BALL.active], 0
    JE >>.next

    ; Trail circles (5 -> 1)
    MOV R13D, 5
.tr_loop:
    CMP R13D, 1
    JL >>.main_ball
    MOV EAX, [RBX + BALL.trailX + R13*4]
    MOV ECX, [RBX + BALL.trailY + R13*4]
    MOV EDX, 7
    SUB EDX, R13D               ; radius shrinks 2..6
    CMP D[gFireTimer], 0
    JG >.tr_fire
    MOV R14D, 00164E78h
    JMP >.draw_tr
.tr_fire:
    MOV R14D, 00992600h
.draw_tr:
    INVOKE DrawCircle, EAX, ECX, EDX, R14D
    DEC R13D
    JMP <.tr_loop

.main_ball:
    CVTTSD2SI R14D, [RBX + BALL.x]
    CVTTSD2SI R15D, [RBX + BALL.y]
    CMP D[gFireTimer], 0
    JG >.ball_fire
    INVOKE DrawCircle, R14D, R15D, 9, COL_CYAN
    INVOKE DrawCircle, R14D, R15D, BALL_RADIUS, COL_WHITE
    JMP >>.next
.ball_fire:
    INVOKE DrawCircle, R14D, R15D, 10, COL_RED
    INVOKE DrawCircle, R14D, R15D, 8, COL_ORANGE
    INVOKE DrawCircle, R14D, R15D, 5, COL_YELLOW

.next:
    ADD RBX, SIZEOF BALL
    INC R12D
    JMP <<.loop
.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; DrawCapsulesAndProjectiles: Powerup pills, lasers, hazard bolts, particles, popups
; -----------------------------------------------------------------------------
DrawCapsulesAndProjectiles FRAME
USES RBX, R12, R13, R14

    ; 1. Powerup Capsules
    LEA RBX, [gPowerups]
    XOR R12D, R12D
.pwr_loop:
    CMP R12D, MAX_POWERUPS
    JGE >>.lasers
    CMP D[RBX + POWERUP.active], 0
    JE >>.next_pwr

    CVTTSD2SI R13D, [RBX + POWERUP.x]
    SUB R13D, 16
    CVTTSD2SI R14D, [RBX + POWERUP.y]
    SUB R14D, 8

    MOV EAX, [RBX + POWERUP.ptype]
    LEA RCX, [gPwrColors]
    MOV EDX, [RCX + RAX*4]
    INVOKE FillBevelRectBuf, [gPixels], R13D, R14D, 32, 16, EDX, COL_WHITE, 00101010h

    MOV EAX, [RBX + POWERUP.ptype]
    LEA RCX, [gPwrLetters]
    MOVZX EAX, B[RCX + RAX]
    ADD R13D, 13
    ADD R14D, 4
    INVOKE DrawChar5x7Buf, [gPixels], R13D, R14D, EAX, 1, COL_BLACK

.next_pwr:
    ADD RBX, SIZEOF POWERUP
    INC R12D
    JMP <.pwr_loop

.lasers:
    ; 2. Player Lasers
    LEA RBX, [gLasers]
    XOR R12D, R12D
.las_loop:
    CMP R12D, MAX_LASERS
    JGE >>.hazards
    CMP D[RBX + BOLT.active], 0
    JE >.next_las
    CVTTSD2SI R13D, [RBX + BOLT.x]
    CVTTSD2SI R14D, [RBX + BOLT.y]
    LEA EAX, [R13 - 2]
    LEA ECX, [R14 - 6]
    INVOKE FillRect, EAX, ECX, 4, 12, COL_YELLOW
    LEA EAX, [R13 - 1]
    LEA ECX, [R14 - 4]
    INVOKE FillRect, EAX, ECX, 2, 8, COL_WHITE
.next_las:
    ADD RBX, SIZEOF BOLT
    INC R12D
    JMP <.las_loop

.hazards:
    ; 3. Enemy Hazard Bolts
    LEA RBX, [gHazards]
    XOR R12D, R12D
.haz_loop:
    CMP R12D, MAX_HAZARDS
    JGE >>.particles
    CMP D[RBX + BOLT.active], 0
    JE >.next_haz
    CVTTSD2SI R13D, [RBX + BOLT.x]
    CVTTSD2SI R14D, [RBX + BOLT.y]
    LEA EAX, [R13 - 3]
    LEA ECX, [R14 - 7]
    INVOKE FillRect, EAX, ECX, 6, 14, COL_RED
    LEA EAX, [R13 - 1]
    LEA ECX, [R14 - 5]
    INVOKE FillRect, EAX, ECX, 2, 10, COL_YELLOW
.next_haz:
    ADD RBX, SIZEOF BOLT
    INC R12D
    JMP <.haz_loop

.particles:
    ; 4. Particles
    LEA RBX, [gParticles]
    XOR R12D, R12D
.part_loop:
    CMP R12D, MAX_PARTICLES
    JGE >.popups
    CMP D[RBX + PARTICLE.active], 0
    JE >.next_part
    CVTTSD2SI R13D, [RBX + PARTICLE.x]
    CVTTSD2SI R14D, [RBX + PARTICLE.y]
    INVOKE FillRect, R13D, R14D, [RBX + PARTICLE.size], [RBX + PARTICLE.size], [RBX + PARTICLE.color]
.next_part:
    ADD RBX, SIZEOF PARTICLE
    INC R12D
    JMP <.part_loop

.popups:
    ; 5. Floating Score / Status Popups
    LEA RBX, [gPopups]
    XOR R12D, R12D
.pop_loop:
    CMP R12D, MAX_POPUPS
    JGE >.done
    CMP D[RBX + POPUP.active], 0
    JE >.next_pop
    CMP D[RBX + POPUP.y], ARENA_TOP + 6
    JL >.next_pop
    LEA RAX, [RBX + POPUP.text]
    INVOKE DrawTextCentered, [RBX + POPUP.x], [RBX + POPUP.y], RAX, 1, [RBX + POPUP.color]
.next_pop:
    ADD RBX, SIZEOF POPUP
    INC R12D
    JMP <.pop_loop

.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; DrawOverlays: Title Screen, Level Intro, Pause, Game Over, Victory Screens
; -----------------------------------------------------------------------------
DrawOverlays FRAME
USES RBX, R12

    ; Check if ball is sitting stuck on paddle during PLAYING -> prompt
    MOV EAX, [gState]
    CMP EAX, STATE_PLAYING
    JNE >.not_playing_hint
    CMP D[gBalls + BALL.active], 0
    JE >.done_ret
    CMP D[gBalls + BALL.stuck], 0
    JE >.done_ret
    INVOKE DrawTextCentered, 480, 560, ADDR strGetReady, 2, COL_WHITE
.done_ret:
    RET

.not_playing_hint:
    CMP EAX, STATE_TITLE
    JE >.draw_title
    CMP EAX, STATE_LEVEL_INTRO
    JE >>.draw_intro
    CMP EAX, STATE_PAUSED
    JE >>.draw_pause
    CMP EAX, STATE_GAME_OVER
    JE >>.draw_gameover
    CMP EAX, STATE_VICTORY
    JE >>.draw_victory
    RET

.draw_title:
    INVOKE FillRect, 110, 125, 740, 480, 000D1326h
    INVOKE DrawRectOutline, 110, 125, 740, 480, COL_CYAN
    INVOKE DrawRectOutline, 113, 128, 734, 474, COL_WALL_GLOW

    INVOKE DrawTextCentered, 480, 160, ADDR strTitleMain, 5, COL_CYAN
    INVOKE DrawTextCentered, 480, 215, ADDR strTitleSub, 2, COL_GOLD

    ; Visual Wall HP Color Key Showcase inside Title Box!
    INVOKE FillBevelRectBuf, [gPixels], 150, 275, 72, 26, 0028E66Bh, 0085FFB0h, 00127D38h
    INVOKE DrawTextCentered, 186, 308, ADDR strLeg1, 1, COL_GREEN

    INVOKE FillBevelRectBuf, [gPixels], 234, 275, 72, 26, 00FFC420h, 00FFE885h, 00996B00h
    INVOKE DrawTextCentered, 270, 308, ADDR strLeg2, 1, COL_GOLD

    INVOKE FillBevelRectBuf, [gPixels], 318, 275, 72, 26, 00FF6B1Ah, 00FFB078h, 00963100h
    INVOKE DrawTextCentered, 354, 308, ADDR strLeg3, 1, COL_ORANGE

    INVOKE FillBevelRectBuf, [gPixels], 402, 275, 72, 26, 00EB223Dh, 00FF8093h, 00870B1Ch
    INVOKE DrawTextCentered, 438, 308, ADDR strLeg4, 1, COL_RED

    INVOKE FillBevelRectBuf, [gPixels], 486, 275, 72, 26, 00A435FFh, 00D699FFh, 00521099h
    INVOKE DrawTextCentered, 522, 308, ADDR strLeg5, 1, COL_VIOLET

    INVOKE FillBevelRectBuf, [gPixels], 570, 275, 72, 26, COL_STEEL, COL_STEEL_HI, COL_STEEL_LO
    INVOKE DrawTextCentered, 606, 308, ADDR strLegSteel, 1, COL_STEEL_HI

    INVOKE FillBevelRectBuf, [gPixels], 654, 275, 72, 26, COL_CYAN, COL_WHITE, 00006688h
    INVOKE DrawTextCentered, 690, 308, ADDR strLegRegen, 1, COL_CYAN

    INVOKE FillBevelRectBuf, [gPixels], 738, 275, 72, 26, COL_MAGENTA, COL_YELLOW, 00660033h
    INVOKE DrawTextCentered, 774, 308, ADDR strLegTnt, 1, COL_MAGENTA

    INVOKE DrawTextCentered, 480, 360, ADDR strTitleCaps, 2, COL_TEXT_DIM

    ; Blink prompt
    TEST D[gFrameCount], 32
    JNZ >.skip_blink
    INVOKE DrawTextCentered, 480, 445, ADDR strTitlePrompt, 3, COL_WHITE
.skip_blink:
    INVOKE DrawTextCentered, 480, 505, ADDR strTitleSelect, 2, COL_GREEN
    INVOKE DrawTextCentered, 480, 548, ADDR strControlsBar, 1, COL_TEXT_DIM
    RET

.draw_intro:
    INVOKE FillRect, 90, 290, 780, 150, 000D1326h
    INVOKE DrawRectOutline, 90, 290, 780, 150, COL_GOLD
    MOV EAX, [gLevel]
    LEA RBX, [gLevelNames]
    MOV R12, [RBX + RAX*8]
    INVOKE DrawTextCentered, 480, 316, R12, 3, COL_WHITE

    MOV EAX, [gLevel]
    LEA RBX, [gLevelGimmicks]
    MOV R12, [RBX + RAX*8]
    INVOKE DrawTextCentered, 480, 360, R12, 2, COL_CYAN

    MOV EAX, [gLevel]
    LEA RBX, [gLevelHints]
    MOV R12, [RBX + RAX*8]
    INVOKE DrawTextCentered, 480, 400, R12, 2, COL_GOLD
    RET

.draw_pause:
    INVOKE FillRect, 230, 300, 500, 130, 000D1326h
    INVOKE DrawRectOutline, 230, 300, 500, 130, COL_CYAN
    INVOKE DrawTextCentered, 480, 326, ADDR strPaused, 4, COL_CYAN
    INVOKE DrawTextCentered, 480, 384, ADDR strPausedSub, 2, COL_WHITE
    RET

.draw_gameover:
    INVOKE FillRect, 200, 270, 560, 190, 001A0B14h
    INVOKE DrawRectOutline, 200, 270, 560, 190, COL_RED
    INVOKE DrawTextCentered, 480, 296, ADDR strGameOver, 4, COL_RED
    INVOKE IntToStr, [gScore], ADDR gStrBuf
    INVOKE DrawTextCentered, 480, 355, ADDR gStrBuf, 3, COL_GOLD
    INVOKE DrawTextCentered, 480, 412, ADDR strGameOverSub, 2, COL_WHITE
    RET

.draw_victory:
    INVOKE FillRect, 140, 240, 680, 230, 000A1D18h
    INVOKE DrawRectOutline, 140, 240, 680, 230, COL_GREEN
    INVOKE DrawTextCentered, 480, 268, ADDR strVictory, 4, COL_GREEN
    INVOKE DrawTextCentered, 480, 318, ADDR strVictorySub, 2, COL_CYAN
    INVOKE IntToStr, [gScore], ADDR gStrBuf
    INVOKE DrawTextCentered, 480, 362, ADDR gStrBuf, 3, COL_GOLD
    INVOKE DrawTextCentered, 480, 422, ADDR strVictorySub2, 2, COL_WHITE
    RET
ENDF

; -----------------------------------------------------------------------------
; RenderFrame: Copies cached bg and composites all dynamic game layers
; -----------------------------------------------------------------------------
RenderFrame FRAME
USES RSI, RDI, RCX

    ; Fast copy pre-rendered background -> gPixels (345,600 qwords = 2.76 MB)
    MOV RSI, [gBgPixels]
    MOV RDI, [gPixels]
    TEST RSI, RSI
    JZ >>.done
    TEST RDI, RDI
    JZ >>.done
    MOV RCX, SCREEN_PIXELS / 2
    REP MOVSQ

    CALL DrawHUD
    CALL DrawGravityWell
    CALL DrawPortals
    CALL DrawBumpers
    CALL DrawBricks
    CALL DrawBoss
    CALL DrawPaddleAndShield
    CALL DrawBalls
    CALL DrawCapsulesAndProjectiles
    CALL DrawOverlays

.done:
    RET
ENDF
