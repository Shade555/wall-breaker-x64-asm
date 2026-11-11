; =============================================================================
; levels.asm - 8 Escalating Levels & Per-Level Gimmick Setup (GoAsm x64)
; =============================================================================
; Cell Codes:
;   0     = Empty
;   1..5  = Normal Brick (HP 1..5: Green, Gold, Orange, Red, Violet)
;   9     = Indestructible Steel Wall (HP=255)
;   11..15 = Moving Patrol Brick (HP 1..5)
;   21..25 = Self-Healing Regen Brick (HP 1..5)
;   31..32 = Explosive TNT Brick (HP 1..2)

#include constants.inc

CONST SECTION

; --- LEVEL 1: NEON INITIATION (Color-coded multi-hit intro) ---
gMapLvl1:
    DB 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0
    DB 0, 2, 2, 3, 2, 2, 2, 2, 3, 2, 2, 0
    DB 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2
    DB 1, 2, 1, 2, 1, 2, 2, 1, 2, 1, 2, 1
    DB 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    DB 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0
    DB 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0
    DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; --- LEVEL 2: IRON BASTION (Indestructible Steel Barriers) ---
gMapLvl2:
    DB 0, 4, 4, 4, 3, 4, 4, 3, 4, 4, 4, 0
    DB 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0
    DB 0, 9, 9, 9, 0, 2, 2, 0, 9, 9, 9, 0
    DB 0, 3, 4, 3, 2, 3, 3, 2, 3, 4, 3, 0
    DB 0, 2, 3, 2, 2, 2, 2, 2, 2, 3, 2, 0
    DB 0, 9, 9, 0, 0, 9, 9, 0, 0, 9, 9, 0
    DB 1, 1, 2, 1, 1, 2, 2, 1, 1, 2, 1, 1
    DB 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 0
    DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; --- LEVEL 3: SHIFTING PHALANX (Moving Patrol Bricks) ---
gMapLvl3:
    DB 0, 0, 4, 4, 4, 4, 4, 4, 4, 4, 0, 0
    DB 0, 0,13,13,13,13,13,13,13,13, 0, 0
    DB 0, 3, 3, 0, 3, 3, 3, 3, 0, 3, 3, 0
    DB 0, 0,13,12,13,14,14,13,12,13, 0, 0
    DB 0, 2, 2, 2, 0, 2, 2, 0, 2, 2, 2, 0
    DB 0, 0,12,12,12,12,12,12,12,12, 0, 0
    DB 1, 1, 2, 2, 1, 1, 1, 1, 2, 2, 1, 1
    DB 0, 0,11,12,11,11,11,11,12,11, 0, 0
    DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; --- LEVEL 4: WARP MATRIX (Dimensional Portals + Sealed Vaults) ---
gMapLvl4:
    DB 0, 4, 5, 4, 4, 0, 0, 4, 4, 5, 4, 0
    DB 0, 3, 4, 3, 3, 3, 3, 3, 3, 4, 3, 0
    DB 0, 9, 9, 9, 9, 0, 0, 9, 9, 9, 9, 0
    DB 2, 3, 3, 4, 3, 2, 2, 3, 4, 3, 3, 2
    DB 2, 2, 3, 3, 2, 0, 0, 2, 3, 3, 2, 2
    DB 0, 2, 9, 9, 2, 2, 2, 2, 9, 9, 2, 0
    DB 1, 1, 2, 2, 2, 1, 1, 2, 2, 2, 1, 1
    DB 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0
    DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; --- LEVEL 5: BIO-CORE REACTOR (Self-Healing Regen Bricks) ---
gMapLvl5:
    DB 0, 4, 4, 5, 5, 25, 25, 5, 5, 4, 4, 0
    DB 0, 3, 4,24, 4, 24, 24, 4,24, 4, 3, 0
    DB 2, 3,24, 5, 4,  3,  3, 4, 5,24, 3, 2
    DB 2, 2, 3,23, 3,  9,  9, 3,23, 3, 2, 2
    DB 0, 2, 3, 3,23,  3,  3,23, 3, 3, 2, 0
    DB 0, 1, 2, 2, 2, 23, 23, 2, 2, 2, 1, 0
    DB 0, 9, 1, 1, 2,  2,  2, 2, 1, 1, 9, 0
    DB 0, 0, 1, 1, 1,  0,  0, 1, 1, 1, 0, 0
    DB 0, 0, 0, 0, 0,  0,  0, 0, 0, 0, 0, 0
    DB 0, 0, 0, 0, 0,  0,  0, 0, 0, 0, 0, 0

; --- LEVEL 6: PINBALL CITADEL (Repulsor Bumpers + Heavy Armor) ---
gMapLvl6:
    DB 5, 5, 4, 5, 5, 4, 4, 5, 5, 4, 5, 5
    DB 4, 4, 5, 4, 3, 4, 4, 3, 4, 5, 4, 4
    DB 3, 9, 4, 4, 3, 3, 3, 3, 4, 4, 9, 3
    DB 3, 3, 3, 4, 9, 3, 3, 9, 4, 3, 3, 3
    DB 2, 2, 3, 3, 2, 2, 2, 2, 3, 3, 2, 2
    DB 0, 2, 2, 2, 2, 1, 1, 2, 2, 2, 2, 0
    DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; --- LEVEL 7: SINGULARITY CHAIN (Gravity Well + Explosive TNT Chains) ---
gMapLvl7:
    DB 5, 5,32, 5, 5, 5, 5, 5, 5,32, 5, 5
    DB 5, 4, 4, 5, 4,32,32, 4, 5, 4, 4, 5
    DB 4,31, 5, 4, 4, 5, 5, 4, 4, 5,31, 4
    DB 4, 4, 4,31, 4, 9, 9, 4,31, 4, 4, 4
    DB 3, 3, 4, 4, 3, 3, 3, 3, 4, 4, 3, 3
    DB 2, 3, 3,31, 3, 2, 2, 3,31, 3, 3, 2
    DB 0, 2, 2, 2, 2, 0, 0, 2, 2, 2, 2, 0
    DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; --- LEVEL 8: OVERLORD MONOLITH (Boss Top Rows + Mixed Gimmicks) ---
gMapLvl8:
    DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    DB 4, 9, 9, 4,24, 5, 5,24, 4, 9, 9, 4
    DB 3,32, 4, 4, 4,31,31, 4, 4, 4,32, 3
    DB 0, 0,13,13,14,13,13,14,13,13, 0, 0
    DB 2, 3, 3, 9, 2, 3, 3, 2, 9, 3, 3, 2
    DB 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0
    DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

ALIGN 8
gLevelMaps      DQ gMapLvl1, gMapLvl2, gMapLvl3, gMapLvl4
                DQ gMapLvl5, gMapLvl6, gMapLvl7, gMapLvl8

ALIGN 16
fPatrolOffset   DQ 100.0
fPatrolVelPos   DQ 1.65
fPatrolVelNeg   DQ -1.65
fPortalRad      DQ 20.0
fBumperRad      DQ 23.0
fPortalX0       DQ 115.0
fPortalY0       DQ 450.0
fPortalX1       DQ 480.0
fPortalY1       DQ 102.0
fPortalX2       DQ 845.0
fPortalY2       DQ 450.0
fPortalX3       DQ 480.0
fPortalY3       DQ 238.0

fPortal8X0      DQ 115.0
fPortal8Y0      DQ 475.0
fPortal8X1      DQ 845.0
fPortal8Y1      DQ 145.0

fBmpX0          DQ 210.0
fBmpY0          DQ 440.0
fBmpX1          DQ 750.0
fBmpY1          DQ 440.0
fBmpX2          DQ 375.0
fBmpY2          DQ 365.0
fBmpX3          DQ 585.0
fBmpY3          DQ 365.0

fBallLaunchVx   DQ 0.38
fBallLaunchVy   DQ -0.925

CODE SECTION

; -----------------------------------------------------------------------------
; ClearEntities: Zeroes balls, powerups, lasers, hazards, portals, bumpers, etc.
; -----------------------------------------------------------------------------
ClearEntities FRAME
USES RDI, RCX, RAX
    XOR EAX, EAX

    LEA RDI, [gBalls]
    MOV RCX, (SIZEOF BALL * MAX_BALLS) / 8
    REP STOSQ

    LEA RDI, [gBricks]
    MOV RCX, (SIZEOF BRICK * MAX_BRICKS) / 8
    REP STOSQ

    LEA RDI, [gPowerups]
    MOV RCX, (SIZEOF POWERUP * MAX_POWERUPS) / 8
    REP STOSQ

    LEA RDI, [gLasers]
    MOV RCX, (SIZEOF BOLT * MAX_LASERS) / 8
    REP STOSQ

    LEA RDI, [gHazards]
    MOV RCX, (SIZEOF BOLT * MAX_HAZARDS) / 8
    REP STOSQ

    LEA RDI, [gPortals]
    MOV RCX, (SIZEOF PORTAL * MAX_PORTALS) / 8
    REP STOSQ

    LEA RDI, [gBumpers]
    MOV RCX, (SIZEOF BUMPER * MAX_BUMPERS) / 8
    REP STOSQ

    LEA RDI, [gParticles]
    MOV RCX, (SIZEOF PARTICLE * MAX_PARTICLES) / 8
    REP STOSQ

    LEA RDI, [gPopups]
    MOV RCX, (SIZEOF POPUP * MAX_POPUPS) / 8
    REP STOSQ

    LEA RDI, [gBoss]
    MOV RCX, (SIZEOF BOSS) / 8
    REP STOSQ

    RET
ENDF

; -----------------------------------------------------------------------------
; ResetBallOnPaddle: Clears active balls and spawns Ball 0 ready on paddle
; -----------------------------------------------------------------------------
ResetBallOnPaddle FRAME
USES RBX, RDI, RCX, RAX

    LEA RDI, [gBalls]
    MOV RCX, (SIZEOF BALL * MAX_BALLS) / 8
    XOR EAX, EAX
    REP STOSQ

    LEA RBX, [gBalls]
    MOV D[RBX + BALL.active], 1
    MOV D[RBX + BALL.stuck], 1
    MOVSD XMM0, [fZero]
    MOVSD [RBX + BALL.stuckDx], XMM0

    MOVSD XMM0, [gPadX]
    MOVSD [RBX + BALL.x], XMM0
    MOVSD XMM1, [fPadTopY]
    SUBSD XMM1, [fBallRadius]
    SUBSD XMM1, [fOne]
    MOVSD [RBX + BALL.y], XMM1

    ; Speed from gLevelSpeeds[gLevel]
    MOV EAX, [gLevel]
    LEA RCX, [gLevelSpeeds]
    MOVSD XMM0, [RCX + RAX*8]
    MOVSD [RBX + BALL.speed], XMM0

    ; Launch direction normalized * speed
    MOVSD XMM1, XMM0
    MULSD XMM1, [fBallLaunchVx]
    MOVSD [RBX + BALL.vx], XMM1

    MOVSD XMM2, XMM0
    MULSD XMM2, [fBallLaunchVy]
    MOVSD [RBX + BALL.vy], XMM2

    ; Initialize trail positions to ball pos
    CVTTSD2SI EAX, [RBX + BALL.x]
    CVTTSD2SI EDX, [RBX + BALL.y]
    XOR ECX, ECX
.trail_init:
    MOV D[RBX + BALL.trailX + RCX*4], EAX
    MOV D[RBX + BALL.trailY + RCX*4], EDX
    INC ECX
    CMP ECX, 6
    JL <.trail_init

    RET
ENDF

; -----------------------------------------------------------------------------
; LoadLevel(levelIdx): Initializes bricks, gimmicks, paddle, ball & intro
; -----------------------------------------------------------------------------
LoadLevel FRAME levelIdx
USES RBX, RSI, RDI, R12, R13, R14, R15

    MOV EAX, [levelIdx]
    CMP EAX, 0
    JGE >.lvl_min_ok
    XOR EAX, EAX
.lvl_min_ok:
    CMP EAX, MAX_LEVELS - 1
    JLE >.lvl_max_ok
    MOV EAX, MAX_LEVELS - 1
.lvl_max_ok:
    MOV [gLevel], EAX

    CALL ClearEntities

    ; Reset powerup timers & paddle state
    XOR EAX, EAX
    MOV [gWideTimer], EAX
    MOV [gFireTimer], EAX
    MOV [gLaserTimer], EAX
    MOV [gSlowTimer], EAX
    MOV [gShieldTimer], EAX
    MOV [gPadStunTimer], EAX
    MOV [gPadInvuln], EAX
    MOV [gLaserCd], EAX
    MOV [gCombo], EAX
    MOV [gBricksLeft], EAX
    MOV [gScreenShake], EAX

    MOV [gHasMoving], EAX
    MOV [gHasRegen], EAX
    MOV [gHasPortals], EAX
    MOV [gHasBumpers], EAX
    MOV [gGravityActive], EAX
    MOV [gHasBoss], EAX

    ; Paddle setup for level
    MOV EAX, [gLevel]
    LEA RCX, [gLevelPadWidths]
    MOVSD XMM0, [RCX + RAX*8]
    MOVSD [gPadBaseW], XMM0
    MOVSD [gPadCurW], XMM0
    MOVSD [gPadTargetW], XMM0
    MOVSD XMM1, [fGravityCx]    ; 480.0
    MOVSD [gPadX], XMM1

    ; Load pointer to level brick map
    MOV EAX, [gLevel]
    LEA RCX, [gLevelMaps]
    MOV RSI, [RCX + RAX*8]      ; RSI -> 120 byte map
    LEA R12, [gBricks]          ; R12 -> brick array

    XOR R13D, R13D              ; row = 0..9
.row_loop:
    CMP R13D, GRID_ROWS
    JGE >>.rows_done

    XOR R14D, R14D              ; col = 0..11
.col_loop:
    CMP R14D, GRID_COLS
    JGE >>.next_row

    ; index = row * 12 + col
    MOV EAX, R13D
    IMUL EAX, EAX, GRID_COLS
    ADD EAX, R14D
    MOVZX EBX, B[RSI + RAX]     ; cell code
    TEST EBX, EBX
    JZ >>.next_col

    ; brick ptr RDI = R12 + index * SIZEOF BRICK
    IMUL R15, RAX, SIZEOF BRICK
    ADD R15, R12
    MOV RDI, R15

    ; Compute x = GRID_X0 + col * GRID_DX, y = GRID_Y0 + row * GRID_DY
    MOV EAX, R14D
    IMUL EAX, EAX, GRID_DX
    ADD EAX, GRID_X0
    CVTSI2SD XMM0, EAX
    MOVSD [RDI + BRICK.x], XMM0

    MOV EAX, R13D
    IMUL EAX, EAX, GRID_DY
    ADD EAX, GRID_Y0
    CVTSI2SD XMM1, EAX
    MOVSD [RDI + BRICK.y], XMM1

    MOV D[RDI + BRICK.w], BRICK_W
    MOV D[RDI + BRICK.h], BRICK_H
    MOV D[RDI + BRICK.active], 1

    ; Decode brick code in EBX
    CMP EBX, 9
    JE >.is_steel
    CMP EBX, 10
    JLE >.is_normal
    CMP EBX, 20
    JLE >.is_moving
    CMP EBX, 30
    JLE >>.is_regen
    JMP >>.is_explosive

.is_normal:
    MOV D[RDI + BRICK.btype], BRICK_NORMAL
    MOV D[RDI + BRICK.hp], EBX
    MOV D[RDI + BRICK.maxHp], EBX
    INC D[gBricksLeft]
    JMP >>.next_col

.is_steel:
    MOV D[RDI + BRICK.btype], BRICK_STEEL
    MOV D[RDI + BRICK.hp], HP_STEEL
    MOV D[RDI + BRICK.maxHp], HP_STEEL
    JMP >>.next_col

.is_moving:
    SUB EBX, 10
    MOV D[RDI + BRICK.btype], BRICK_MOVING
    MOV D[RDI + BRICK.hp], EBX
    MOV D[RDI + BRICK.maxHp], EBX
    MOV D[gHasMoving], 1
    INC D[gBricksLeft]
    ; minX = x - 100, maxX = x + 100, alternate vx by row parity (row & 2)
    MOVSD XMM2, XMM0
    SUBSD XMM2, [fPatrolOffset]
    MOVSD [RDI + BRICK.minX], XMM2
    MOVSD XMM3, XMM0
    ADDSD XMM3, [fPatrolOffset]
    MOVSD [RDI + BRICK.maxX], XMM3
    TEST R13D, 2
    JNZ >.mov_neg
    MOVSD XMM4, [fPatrolVelPos]
    MOVSD [RDI + BRICK.vx], XMM4
    JMP >>.next_col
.mov_neg:
    MOVSD XMM4, [fPatrolVelNeg]
    MOVSD [RDI + BRICK.vx], XMM4
    JMP >>.next_col

.is_regen:
    SUB EBX, 20
    MOV D[RDI + BRICK.btype], BRICK_REGEN
    MOV D[RDI + BRICK.hp], EBX
    MOV D[RDI + BRICK.maxHp], EBX
    MOV D[gHasRegen], 1
    INC D[gBricksLeft]
    JMP >>.next_col

.is_explosive:
    SUB EBX, 30
    MOV D[RDI + BRICK.btype], BRICK_EXPLOSIVE
    MOV D[RDI + BRICK.hp], EBX
    MOV D[RDI + BRICK.maxHp], EBX
    INC D[gBricksLeft]

.next_col:
    INC R14D
    JMP <<.col_loop

.next_row:
    INC R13D
    JMP <<.row_loop

.rows_done:
    ; Setup special per-level gimmicks (Portals, Bumpers, Gravity, Boss)
    MOV EAX, [gLevel]
    CMP EAX, 3                  ; Level 4 (0-based 3): Warp Matrix
    JE >.setup_portals_l4
    CMP EAX, 5                  ; Level 6 (0-based 5): Pinball Citadel
    JE >>.setup_bumpers_l6
    CMP EAX, 6                  ; Level 7 (0-based 6): Singularity Chain
    JE >>.setup_gravity_l7
    CMP EAX, 7                  ; Level 8 (0-based 7): Overlord Monolith
    JE >>.setup_boss_l8
    JMP >>.finish_setup

.setup_portals_l4:
    MOV D[gHasPortals], 1
    LEA RBX, [gPortals]
    ; Portal 0 (Cyan) -> pairs with 1
    MOVSD XMM0, [fPortalX0]
    MOVSD [RBX + PORTAL.x], XMM0
    MOVSD XMM0, [fPortalY0]
    MOVSD [RBX + PORTAL.y], XMM0
    MOVSD XMM0, [fPortalRad]
    MOVSD [RBX + PORTAL.radius], XMM0
    MOV D[RBX + PORTAL.active], 1
    MOV D[RBX + PORTAL.pairIdx], 1
    MOV D[RBX + PORTAL.color], COL_CYAN

    ; Portal 1 (Orange) -> pairs with 0
    ADD RBX, SIZEOF PORTAL
    MOVSD XMM0, [fPortalX1]
    MOVSD [RBX + PORTAL.x], XMM0
    MOVSD XMM0, [fPortalY1]
    MOVSD [RBX + PORTAL.y], XMM0
    MOVSD XMM0, [fPortalRad]
    MOVSD [RBX + PORTAL.radius], XMM0
    MOV D[RBX + PORTAL.active], 1
    MOV D[RBX + PORTAL.pairIdx], 0
    MOV D[RBX + PORTAL.color], COL_ORANGE

    ; Portal 2 (Cyan) -> pairs with 3
    ADD RBX, SIZEOF PORTAL
    MOVSD XMM0, [fPortalX2]
    MOVSD [RBX + PORTAL.x], XMM0
    MOVSD XMM0, [fPortalY2]
    MOVSD [RBX + PORTAL.y], XMM0
    MOVSD XMM0, [fPortalRad]
    MOVSD [RBX + PORTAL.radius], XMM0
    MOV D[RBX + PORTAL.active], 1
    MOV D[RBX + PORTAL.pairIdx], 3
    MOV D[RBX + PORTAL.color], COL_MAGENTA

    ; Portal 3 (Gold) -> pairs with 2
    ADD RBX, SIZEOF PORTAL
    MOVSD XMM0, [fPortalX3]
    MOVSD [RBX + PORTAL.x], XMM0
    MOVSD XMM0, [fPortalY3]
    MOVSD [RBX + PORTAL.y], XMM0
    MOVSD XMM0, [fPortalRad]
    MOVSD [RBX + PORTAL.radius], XMM0
    MOV D[RBX + PORTAL.active], 1
    MOV D[RBX + PORTAL.pairIdx], 2
    MOV D[RBX + PORTAL.color], COL_GOLD
    JMP >>.finish_setup

.setup_bumpers_l6:
    MOV D[gHasBumpers], 1
    LEA RBX, [gBumpers]

    MOVSD XMM0, [fBmpX0]
    MOVSD [RBX + BUMPER.x], XMM0
    MOVSD XMM0, [fBmpY0]
    MOVSD [RBX + BUMPER.y], XMM0
    MOVSD XMM0, [fBumperRad]
    MOVSD [RBX + BUMPER.radius], XMM0
    MOV D[RBX + BUMPER.active], 1

    ADD RBX, SIZEOF BUMPER
    MOVSD XMM0, [fBmpX1]
    MOVSD [RBX + BUMPER.x], XMM0
    MOVSD XMM0, [fBmpY1]
    MOVSD [RBX + BUMPER.y], XMM0
    MOVSD XMM0, [fBumperRad]
    MOVSD [RBX + BUMPER.radius], XMM0
    MOV D[RBX + BUMPER.active], 1

    ADD RBX, SIZEOF BUMPER
    MOVSD XMM0, [fBmpX2]
    MOVSD [RBX + BUMPER.x], XMM0
    MOVSD XMM0, [fBmpY2]
    MOVSD [RBX + BUMPER.y], XMM0
    MOVSD XMM0, [fBumperRad]
    MOVSD [RBX + BUMPER.radius], XMM0
    MOV D[RBX + BUMPER.active], 1

    ADD RBX, SIZEOF BUMPER
    MOVSD XMM0, [fBmpX3]
    MOVSD [RBX + BUMPER.x], XMM0
    MOVSD XMM0, [fBmpY3]
    MOVSD [RBX + BUMPER.y], XMM0
    MOVSD XMM0, [fBumperRad]
    MOVSD [RBX + BUMPER.radius], XMM0
    MOV D[RBX + BUMPER.active], 1
    JMP >>.finish_setup

.setup_gravity_l7:
    MOV D[gGravityActive], 1
    JMP >>.finish_setup

.setup_boss_l8:
    MOV D[gHasBoss], 1
    LEA RBX, [gBoss]
    MOV D[RBX + BOSS.active], 1
    MOV D[RBX + BOSS.w], 140
    MOV D[RBX + BOSS.h], 40
    MOV D[RBX + BOSS.hp], 24
    MOV D[RBX + BOSS.maxHp], 24
    MOV D[RBX + BOSS.fireTimer], 100
    MOVSD XMM0, [fGravityCx]
    SUBSD XMM0, [fBossHalfW]    ; 480 - 70 = 410
    MOVSD [RBX + BOSS.x], XMM0
    MOV EAX, GRID_Y0 + 6
    CVTSI2SD XMM0, EAX
    MOVSD [RBX + BOSS.y], XMM0
    MOVSD XMM0, [fBossSpeed]
    MOVSD [RBX + BOSS.vx], XMM0

    ; Also activate 1 pair of tactical Warp Portals in Level 8!
    MOV D[gHasPortals], 1
    LEA RBX, [gPortals]
    MOVSD XMM0, [fPortal8X0]
    MOVSD [RBX + PORTAL.x], XMM0
    MOVSD XMM0, [fPortal8Y0]
    MOVSD [RBX + PORTAL.y], XMM0
    MOVSD XMM0, [fPortalRad]
    MOVSD [RBX + PORTAL.radius], XMM0
    MOV D[RBX + PORTAL.active], 1
    MOV D[RBX + PORTAL.pairIdx], 1
    MOV D[RBX + PORTAL.color], COL_CYAN

    ADD RBX, SIZEOF PORTAL
    MOVSD XMM0, [fPortal8X1]
    MOVSD [RBX + PORTAL.x], XMM0
    MOVSD XMM0, [fPortal8Y1]
    MOVSD [RBX + PORTAL.y], XMM0
    MOVSD XMM0, [fPortalRad]
    MOVSD [RBX + PORTAL.radius], XMM0
    MOV D[RBX + PORTAL.active], 1
    MOV D[RBX + PORTAL.pairIdx], 0
    MOV D[RBX + PORTAL.color], COL_ORANGE

.finish_setup:
    CALL ResetBallOnPaddle
    MOV D[gState], STATE_LEVEL_INTRO
    MOV D[gIntroTimer], 110
    RET
ENDF

; -----------------------------------------------------------------------------
; StartNewGame(startLevel): Starts full campaign from startLevel (0..7)
; -----------------------------------------------------------------------------
StartNewGame FRAME startLevel
    MOV D[gScore], 0
    MOV D[gLives], 3
    MOV D[gCombo], 0
    MOV D[gMaxCombo], 0
    INVOKE LoadLevel, [startLevel]
    RET
ENDF
