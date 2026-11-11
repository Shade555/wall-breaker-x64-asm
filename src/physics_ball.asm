; =============================================================================
; physics_ball.asm - Ball Sub-stepping, Sweeps, Portals, Bumpers & Collisions
; =============================================================================

#include constants.inc

CODE SECTION

; -----------------------------------------------------------------------------
; StepSingleBall(ballIdx): Advances one active ball with 4 substeps
; -----------------------------------------------------------------------------
StepSingleBall FRAME ballIdx
USES RBX, RSI, RDI, R12, R13, R14, R15
LOCAL stepScale, subIdx, bestBrick, minPen

    MOV EAX, [ballIdx]
    IMUL RAX, RAX, SIZEOF BALL
    LEA RBX, [gBalls]
    ADD RBX, RAX

    CMP D[RBX + BALL.active], 0
    JE >>.done

    ; If stuck on paddle, track paddle X
    CMP D[RBX + BALL.stuck], 0
    JE >.not_stuck
    MOVSD XMM0, [gPadX]
    ADDSD XMM0, [RBX + BALL.stuckDx]
    MOVSD [RBX + BALL.x], XMM0
    MOVSD XMM1, [fPadTopY]
    SUBSD XMM1, [fBallRadius]
    SUBSD XMM1, [fOne]
    MOVSD [RBX + BALL.y], XMM1
    JMP >>.update_trail

.not_stuck:
    ; Decrement cooldowns once per frame
    CMP D[RBX + BALL.portalCd], 0
    JLE >.cd1_ok
    DEC D[RBX + BALL.portalCd]
.cd1_ok:
    CMP D[RBX + BALL.bumperCd], 0
    JLE >.cd2_ok
    DEC D[RBX + BALL.bumperCd]
.cd2_ok:

    ; Compute stepScale = 0.25 * (gSlowTimer > 0 ? 0.72 : 1.0)
    MOVSD XMM0, [fSubStepInv]
    CMP D[gSlowTimer], 0
    JLE >.spd_ok
    MULSD XMM0, [fSlowScale]
.spd_ok:
    MOVSD [stepScale], XMM0

    MOV D[subIdx], 0
.sub_loop:
    CMP D[subIdx], 4
    JGE >>.after_substeps

    ; Gravity anomaly well in Level 7
    CMP D[gGravityActive], 0
    JE >>.no_gravity
    MOVSD XMM0, [RBX + BALL.x]
    SUBSD XMM0, [fGravityCx]
    MOVSD XMM1, [RBX + BALL.y]
    SUBSD XMM1, [fGravityCy]
    MOVSD XMM2, XMM0
    MULSD XMM2, XMM2
    MOVSD XMM3, XMM1
    MULSD XMM3, XMM3
    ADDSD XMM2, XMM3
    UCOMISD XMM2, [fGravityRadSq]
    JA >>.no_gravity
    ; Pull vy downward & swirl vx slightly
    MOVSD XMM3, [RBX + BALL.vy]
    ADDSD XMM3, [fGravityPullY]
    MOVSD [RBX + BALL.vy], XMM3
    ; swirl vx -= dy * 0.00025
    MOV EAX, 4000
    CVTSI2SD XMM4, EAX
    DIVSD XMM1, XMM4
    MOVSD XMM3, [RBX + BALL.vx]
    SUBSD XMM3, XMM1
    MOVSD [RBX + BALL.vx], XMM3
    INVOKE NormalizeBallVel, RBX
.no_gravity:

    ; Advance x += vx * stepScale, y += vy * stepScale
    MOVSD XMM0, [RBX + BALL.vx]
    MULSD XMM0, [stepScale]
    ADDSD XMM0, [RBX + BALL.x]
    MOVSD [RBX + BALL.x], XMM0

    MOVSD XMM1, [RBX + BALL.vy]
    MULSD XMM1, [stepScale]
    ADDSD XMM1, [RBX + BALL.y]
    MOVSD [RBX + BALL.y], XMM1

    ; --- Arena Wall Collisions ---
    ; Left wall: x < ARENA_LEFT + R
    MOVSD XMM2, [fArenaLeft]
    ADDSD XMM2, [fBallRadius]
    UCOMISD XMM0, XMM2
    JAE >.chk_right_wall
    MOVSD [RBX + BALL.x], XMM2
    MOVSD XMM3, [RBX + BALL.vx]
    UCOMISD XMM3, [fZero]
    JAE >.chk_right_wall
    MULSD XMM3, [fMinusOne]
    MOVSD [RBX + BALL.vx], XMM3

.chk_right_wall:
    MOVSD XMM0, [RBX + BALL.x]
    MOVSD XMM2, [fArenaRight]
    SUBSD XMM2, [fBallRadius]
    UCOMISD XMM0, XMM2
    JBE >.chk_top_wall
    MOVSD [RBX + BALL.x], XMM2
    MOVSD XMM3, [RBX + BALL.vx]
    UCOMISD XMM3, [fZero]
    JBE >.chk_top_wall
    MULSD XMM3, [fMinusOne]
    MOVSD [RBX + BALL.vx], XMM3

.chk_top_wall:
    MOVSD XMM1, [RBX + BALL.y]
    MOVSD XMM2, [fArenaTop]
    ADDSD XMM2, [fBallRadius]
    UCOMISD XMM1, XMM2
    JAE >.chk_shield
    MOVSD [RBX + BALL.y], XMM2
    MOVSD XMM3, [RBX + BALL.vy]
    UCOMISD XMM3, [fZero]
    JAE >.chk_shield
    MULSD XMM3, [fMinusOne]
    MOVSD [RBX + BALL.vy], XMM3

.chk_shield:
    CMP D[gShieldTimer], 0
    JLE >>.chk_paddle
    MOVSD XMM3, [RBX + BALL.vy]
    UCOMISD XMM3, [fZero]
    JBE >>.chk_paddle
    MOVSD XMM1, [RBX + BALL.y]
    ADDSD XMM1, [fBallRadius]
    UCOMISD XMM1, [fShieldY]
    JB >>.chk_paddle
    MOVSD XMM2, [fShieldY]
    SUBSD XMM2, [fBallRadius]
    MOVSD [RBX + BALL.y], XMM2
    MULSD XMM3, [fMinusOne]
    MOVSD [RBX + BALL.vy], XMM3
    CVTTSD2SI EAX, [RBX + BALL.x]
    INVOKE SpawnBurst, EAX, 676, COL_GOLD, 6, 7
    INVOKE PlaySfx, SFX_PADDLE

.chk_paddle:
    MOVSD XMM3, [RBX + BALL.vy]
    UCOMISD XMM3, [fZero]
    JBE >>.chk_portals
    ; y + R >= PADDLE_Y && y - R <= PADDLE_Y + PADDLE_H
    MOVSD XMM1, [RBX + BALL.y]
    MOVSD XMM2, XMM1
    ADDSD XMM2, [fBallRadius]
    UCOMISD XMM2, [fPadTopY]
    JB >>.chk_portals

    MOVSD XMM2, XMM1
    SUBSD XMM2, [fBallRadius]
    MOVSD XMM4, [fPadTopY]
    ADDSD XMM4, [fPadH]
    UCOMISD XMM2, XMM4
    JA >>.chk_portals

    ; Horizontal overlap: |x - gPadX| <= gPadCurW/2 + R
    MOVSD XMM0, [RBX + BALL.x]
    SUBSD XMM0, [gPadX]       ; offset from paddle center
    MOVSD XMM4, [gPadCurW]
    MULSD XMM4, [fHalf]         ; halfW
    MOVSD XMM5, XMM4
    ADDSD XMM5, [fBallRadius]

    MOVSD XMM2, XMM0
    UCOMISD XMM2, [fZero]
    JAE >.pad_abs_ok
    MULSD XMM2, [fMinusOne]
.pad_abs_ok:
    UCOMISD XMM2, XMM5
    JA >>.chk_portals

    ; Hit paddle! rel = clamp(offset / halfW, -0.95, 0.95)
    DIVSD XMM0, XMM4
    UCOMISD XMM0, [fZeroPoint95]
    JBE >.rel_min
    MOVSD XMM0, [fZeroPoint95]
    JMP >.rel_ok
.rel_min:
    MOVSD XMM5, [fZeroPoint95]
    MULSD XMM5, [fMinusOne]
    UCOMISD XMM0, XMM5
    JAE >.rel_ok
    MOVSD XMM0, XMM5
.rel_ok:
    ; ux = rel * 0.88, uy = -sqrt(1 - ux*ux)
    MULSD XMM0, [fPadAngleMax]
    MOVSD XMM1, [fOne]
    MOVSD XMM2, XMM0
    MULSD XMM2, XMM2
    SUBSD XMM1, XMM2
    SQRTSD XMM1, XMM1
    MULSD XMM1, [fMinusOne]

    MOVSD XMM2, [RBX + BALL.speed]
    MULSD XMM0, XMM2
    MULSD XMM1, XMM2
    MOVSD [RBX + BALL.vx], XMM0
    MOVSD [RBX + BALL.vy], XMM1

    MOVSD XMM2, [fPadTopY]
    SUBSD XMM2, [fBallRadius]
    SUBSD XMM2, [fOne]
    MOVSD [RBX + BALL.y], XMM2

    MOV D[gCombo], 0
    CVTTSD2SI EAX, [RBX + BALL.x]
    INVOKE SpawnBurst, EAX, PADDLE_Y, COL_CYAN, 6, 7
    INVOKE PlaySfx, SFX_PADDLE

.chk_portals:
    CMP D[gHasPortals], 0
    JE >>.chk_bumpers
    CMP D[RBX + BALL.portalCd], 0
    JG >>.chk_bumpers

    LEA RSI, [gPortals]
    XOR R12D, R12D
.portal_loop:
    CMP R12D, MAX_PORTALS
    JGE >>.chk_bumpers
    CMP D[RSI + PORTAL.active], 0
    JE >>.next_portal

    MOVSD XMM0, [RBX + BALL.x]
    SUBSD XMM0, [RSI + PORTAL.x]
    MULSD XMM0, XMM0
    MOVSD XMM1, [RBX + BALL.y]
    SUBSD XMM1, [RSI + PORTAL.y]
    MULSD XMM1, XMM1
    ADDSD XMM0, XMM1

    MOVSD XMM2, [RSI + PORTAL.radius]
    ADDSD XMM2, [fBallRadius]
    SUBSD XMM2, [fFour]
    MULSD XMM2, XMM2
    UCOMISD XMM0, XMM2
    JA >>.next_portal

    ; Teleport to paired portal!
    MOV EAX, [RSI + PORTAL.pairIdx]
    IMUL RAX, RAX, SIZEOF PORTAL
    LEA RDI, [gPortals]
    ADD RDI, RAX

    ; Unit direction of velocity
    MOVSD XMM0, [RBX + BALL.vx]
    MOVSD XMM1, [RBX + BALL.vy]
    DIVSD XMM0, [RBX + BALL.speed]
    DIVSD XMM1, [RBX + BALL.speed]

    MOVSD XMM2, [RDI + PORTAL.x]
    MULSD XMM0, [fPortalExitOff]
    ADDSD XMM2, XMM0
    MOVSD [RBX + BALL.x], XMM2

    MOVSD XMM3, [RDI + PORTAL.y]
    MULSD XMM1, [fPortalExitOff]
    ADDSD XMM3, XMM1
    MOVSD [RBX + BALL.y], XMM3

    MOV D[RBX + BALL.portalCd], 22
    MOV D[RSI + PORTAL.flash], 14
    MOV D[RDI + PORTAL.flash], 14

    CVTTSD2SI R13D, [RSI + PORTAL.x]
    CVTTSD2SI R14D, [RSI + PORTAL.y]
    INVOKE SpawnBurst, R13D, R14D, [RSI + PORTAL.color], 10, 10
    CVTTSD2SI R13D, [RDI + PORTAL.x]
    CVTTSD2SI R14D, [RDI + PORTAL.y]
    INVOKE SpawnBurst, R13D, R14D, [RDI + PORTAL.color], 10, 10
    INVOKE SpawnPopup, R13D, R14D, ADDR strPopWarp, COL_CYAN
    INVOKE PlaySfx, SFX_POWERUP
    JMP >.chk_bumpers

.next_portal:
    ADD RSI, SIZEOF PORTAL
    INC R12D
    JMP <<.portal_loop

.chk_bumpers:
    CMP D[gHasBumpers], 0
    JE >>.chk_boss
    CMP D[RBX + BALL.bumperCd], 0
    JG >>.chk_boss

    LEA RSI, [gBumpers]
    XOR R12D, R12D
.bumper_loop:
    CMP R12D, MAX_BUMPERS
    JGE >>.chk_boss
    CMP D[RSI + BUMPER.active], 0
    JE >>.next_bumper

    MOVSD XMM0, [RBX + BALL.x]
    SUBSD XMM0, [RSI + BUMPER.x] ; dx
    MOVSD XMM1, [RBX + BALL.y]
    SUBSD XMM1, [RSI + BUMPER.y] ; dy
    MOVSD XMM2, XMM0
    MULSD XMM2, XMM2
    MOVSD XMM3, XMM1
    MULSD XMM3, XMM3
    ADDSD XMM2, XMM3
    SQRTSD XMM2, XMM2           ; dist

    MOVSD XMM3, [RSI + BUMPER.radius]
    ADDSD XMM3, [fBallRadius]
    UCOMISD XMM2, XMM3
    JA >>.next_bumper

    ; Deflect outward along radial normal (dx/dist, dy/dist)
    UCOMISD XMM2, [fHalf]
    JAE >.dist_ok
    MOVSD XMM2, [fOne]
    MOVSD XMM0, [fZero]
    MOVSD XMM1, [fOne]
.dist_ok:
    DIVSD XMM0, XMM2            ; nx
    DIVSD XMM1, XMM2            ; ny

    ; Push outside bumper
    ADDSD XMM3, [fTwo]
    MOVSD XMM4, XMM0
    MULSD XMM4, XMM3
    ADDSD XMM4, [RSI + BUMPER.x]
    MOVSD [RBX + BALL.x], XMM4

    MOVSD XMM4, XMM1
    MULSD XMM4, XMM3
    ADDSD XMM4, [RSI + BUMPER.y]
    MOVSD [RBX + BALL.y], XMM4

    ; Slight speed kick capped at fMaxBallSpeed
    MOVSD XMM4, [RBX + BALL.speed]
    MULSD XMM4, [fBumperBoost]
    UCOMISD XMM4, [fMaxBallSpeed]
    JBE >.bspd_ok
    MOVSD XMM4, [fMaxBallSpeed]
.bspd_ok:
    MOVSD [RBX + BALL.speed], XMM4
    MULSD XMM0, XMM4
    MULSD XMM1, XMM4
    MOVSD [RBX + BALL.vx], XMM0
    MOVSD [RBX + BALL.vy], XMM1
    INVOKE NormalizeBallVel, RBX

    MOV D[RBX + BALL.bumperCd], 6
    MOV D[RSI + BUMPER.flash], 12
    CVTTSD2SI R13D, [RSI + BUMPER.x]
    CVTTSD2SI R14D, [RSI + BUMPER.y]
    INVOKE SpawnBurst, R13D, R14D, COL_MAGENTA, 10, 10
    INVOKE AddScore, 50
    INVOKE PlaySfx, SFX_STEEL
    JMP >.chk_boss

.next_bumper:
    ADD RSI, SIZEOF BUMPER
    INC R12D
    JMP <<.bumper_loop

.chk_boss:
    CMP D[gHasBoss], 0
    JE >>.chk_bricks
    LEA RSI, [gBoss]
    CMP D[RSI + BOSS.active], 0
    JE >>.chk_bricks

    ; Closest point on boss AABB to ball
    MOVSD XMM0, [RBX + BALL.x]
    MOVSD XMM2, [RSI + BOSS.x]
    UCOMISD XMM0, XMM2
    JAE >.bs_x1
    MOVSD XMM0, XMM2
    JMP >.bs_xok
.bs_x1:
    CVTSI2SD XMM3, D[RSI + BOSS.w]
    ADDSD XMM2, XMM3
    UCOMISD XMM0, XMM2
    JBE >.bs_xok
    MOVSD XMM0, XMM2
.bs_xok:
    MOVSD XMM1, [RBX + BALL.y]
    MOVSD XMM2, [RSI + BOSS.y]
    UCOMISD XMM1, XMM2
    JAE >.bs_y1
    MOVSD XMM1, XMM2
    JMP >.bs_yok
.bs_y1:
    CVTSI2SD XMM3, D[RSI + BOSS.h]
    ADDSD XMM2, XMM3
    UCOMISD XMM1, XMM2
    JBE >.bs_yok
    MOVSD XMM1, XMM2
.bs_yok:
    MOVSD XMM2, [RBX + BALL.x]
    SUBSD XMM2, XMM0            ; dx
    MOVSD XMM3, [RBX + BALL.y]
    SUBSD XMM3, XMM1            ; dy
    MOVSD XMM4, XMM2
    MULSD XMM4, XMM4
    MOVSD XMM5, XMM3
    MULSD XMM5, XMM5
    ADDSD XMM4, XMM5
    MOVSD XMM5, [fBallRadius]
    MULSD XMM5, XMM5
    UCOMISD XMM4, XMM5
    JA >>.chk_bricks

    ; Reflect ball off Boss
    MOVSD XMM4, XMM2
    UCOMISD XMM4, [fZero]
    JAE >.bs_adx
    MULSD XMM4, [fMinusOne]
.bs_adx:
    MOVSD XMM5, XMM3
    UCOMISD XMM5, [fZero]
    JAE >.bs_ady
    MULSD XMM5, [fMinusOne]
.bs_ady:
    UCOMISD XMM4, XMM5
    JA >>.bs_horiz
    ; Bounce vertical
    MOVSD XMM0, [RBX + BALL.vy]
    MULSD XMM0, [fMinusOne]
    MOVSD [RBX + BALL.vy], XMM0
    UCOMISD XMM3, [fZero]
    JB >.bs_up
    MOVSD XMM1, [RSI + BOSS.y]
    CVTSI2SD XMM2, D[RSI + BOSS.h]
    ADDSD XMM1, XMM2
    ADDSD XMM1, [fBallRadius]
    ADDSD XMM1, [fTwo]
    MOVSD [RBX + BALL.y], XMM1
    JMP >>.bs_hit
.bs_up:
    MOVSD XMM1, [RSI + BOSS.y]
    SUBSD XMM1, [fBallRadius]
    SUBSD XMM1, [fTwo]
    MOVSD [RBX + BALL.y], XMM1
    JMP >>.bs_hit
.bs_horiz:
    MOVSD XMM0, [RBX + BALL.vx]
    MULSD XMM0, [fMinusOne]
    MOVSD [RBX + BALL.vx], XMM0
    UCOMISD XMM2, [fZero]
    JB >.bs_left
    MOVSD XMM1, [RSI + BOSS.x]
    CVTSI2SD XMM2, D[RSI + BOSS.w]
    ADDSD XMM1, XMM2
    ADDSD XMM1, [fBallRadius]
    ADDSD XMM1, [fTwo]
    MOVSD [RBX + BALL.x], XMM1
    JMP >.bs_hit
.bs_left:
    MOVSD XMM1, [RSI + BOSS.x]
    SUBSD XMM1, [fBallRadius]
    SUBSD XMM1, [fTwo]
    MOVSD [RBX + BALL.x], XMM1

.bs_hit:
    MOV EAX, 1
    CMP D[gFireTimer], 0
    JLE >.bs_dmg
    MOV EAX, 2
.bs_dmg:
    INVOKE DamageBoss, EAX

.chk_bricks:
    LEA RSI, [gBricks]
    XOR R12D, R12D
    MOV R13D, -1                ; hit brick index

.brick_loop:
    CMP R12D, MAX_BRICKS
    JGE >>.next_substep

    CMP D[RSI + BRICK.active], 0
    JE >>.next_brick

    ; Closest point (XMM0, XMM1) on brick AABB to ball (bx, by)
    MOVSD XMM0, [RBX + BALL.x]
    MOVSD XMM2, [RSI + BRICK.x]
    UCOMISD XMM0, XMM2
    JAE >.bx1
    MOVSD XMM0, XMM2
    JMP >.bx_ok
.bx1:
    CVTSI2SD XMM3, D[RSI + BRICK.w]
    ADDSD XMM2, XMM3
    UCOMISD XMM0, XMM2
    JBE >.bx_ok
    MOVSD XMM0, XMM2
.bx_ok:
    MOVSD XMM1, [RBX + BALL.y]
    MOVSD XMM2, [RSI + BRICK.y]
    UCOMISD XMM1, XMM2
    JAE >.by1
    MOVSD XMM1, XMM2
    JMP >.by_ok
.by1:
    CVTSI2SD XMM3, D[RSI + BRICK.h]
    ADDSD XMM2, XMM3
    UCOMISD XMM1, XMM2
    JBE >.by_ok
    MOVSD XMM1, XMM2
.by_ok:
    MOVSD XMM2, [RBX + BALL.x]
    SUBSD XMM2, XMM0            ; dx = ball.x - closestX
    MOVSD XMM3, [RBX + BALL.y]
    SUBSD XMM3, XMM1            ; dy = ball.y - closestY

    MOVSD XMM4, XMM2
    MULSD XMM4, XMM4
    MOVSD XMM5, XMM3
    MULSD XMM5, XMM5
    ADDSD XMM4, XMM5

    MOVSD XMM5, [fBallRadius]
    MULSD XMM5, XMM5
    UCOMISD XMM4, XMM5
    JA >>.next_brick

    ; Brick collision! Check Fireball pierce condition:
    ; Fireball pierces breakable bricks with hp <= 2 (since dmg = 2 destroys them!)
    CMP D[gFireTimer], 0
    JLE >>.normal_bounce
    CMP D[RSI + BRICK.btype], BRICK_STEEL
    JE >.normal_bounce
    CMP D[RSI + BRICK.hp], 2
    JG >.fire_bounce
    INVOKE DamageBrick, R12D, 2, 1
    JMP >>.next_brick            ; pierce straight through!

.fire_bounce:
    MOV R14D, 2
    JMP >.do_bounce

.normal_bounce:
    MOV R14D, 1

.do_bounce:
    ; Determine reflection axis using |dx| vs |dy| (or edge overlap)
    MOVSD XMM4, XMM2
    UCOMISD XMM4, [fZero]
    JAE >.abx
    MULSD XMM4, [fMinusOne]
.abx:
    MOVSD XMM5, XMM3
    UCOMISD XMM5, [fZero]
    JAE >.aby
    MULSD XMM5, [fMinusOne]
.aby:
    UCOMISD XMM4, XMM5
    JA >>.bounce_x

    ; Reflect Y
    UCOMISD XMM3, [fZero]
    JB >>.hit_top
    ; Hit bottom face of brick
    MOVSD XMM0, [RBX + BALL.vy]
    UCOMISD XMM0, [fZero]
    JAE >.push_bot
    MULSD XMM0, [fMinusOne]
    MOVSD [RBX + BALL.vy], XMM0
.push_bot:
    MOVSD XMM1, [RSI + BRICK.y]
    CVTSI2SD XMM2, D[RSI + BRICK.h]
    ADDSD XMM1, XMM2
    ADDSD XMM1, [fBallRadius]
    ADDSD XMM1, [fHalf]
    MOVSD [RBX + BALL.y], XMM1
    JMP >>.apply_dmg

.hit_top:
    MOVSD XMM0, [RBX + BALL.vy]
    UCOMISD XMM0, [fZero]
    JBE >.push_top
    MULSD XMM0, [fMinusOne]
    MOVSD [RBX + BALL.vy], XMM0
.push_top:
    MOVSD XMM1, [RSI + BRICK.y]
    SUBSD XMM1, [fBallRadius]
    SUBSD XMM1, [fHalf]
    MOVSD [RBX + BALL.y], XMM1
    JMP >>.apply_dmg

.bounce_x:
    UCOMISD XMM2, [fZero]
    JB >>.hit_left
    ; Hit right face of brick
    MOVSD XMM0, [RBX + BALL.vx]
    UCOMISD XMM0, [fZero]
    JAE >.push_right
    MULSD XMM0, [fMinusOne]
    MOVSD [RBX + BALL.vx], XMM0
.push_right:
    MOVSD XMM1, [RSI + BRICK.x]
    CVTSI2SD XMM2, D[RSI + BRICK.w]
    ADDSD XMM1, XMM2
    ADDSD XMM1, [fBallRadius]
    ADDSD XMM1, [fHalf]
    MOVSD [RBX + BALL.x], XMM1
    JMP >>.apply_dmg

.hit_left:
    MOVSD XMM0, [RBX + BALL.vx]
    UCOMISD XMM0, [fZero]
    JBE >.push_left
    MULSD XMM0, [fMinusOne]
    MOVSD [RBX + BALL.vx], XMM0
.push_left:
    MOVSD XMM1, [RSI + BRICK.x]
    SUBSD XMM1, [fBallRadius]
    SUBSD XMM1, [fHalf]
    MOVSD [RBX + BALL.x], XMM1

.apply_dmg:
    INVOKE DamageBrick, R12D, R14D, 1
    JMP >.next_substep          ; one solid bounce per substep

.next_brick:
    ADD RSI, SIZEOF BRICK
    INC R12D
    JMP <<.brick_loop

.next_substep:
    INC D[subIdx]
    JMP <<.sub_loop

.after_substeps:
    ; Pit check: y - R > ARENA_BOTTOM
    MOVSD XMM0, [RBX + BALL.y]
    SUBSD XMM0, [fBallRadius]
    UCOMISD XMM0, [fArenaBottom]
    JBE >.update_trail
    MOV D[RBX + BALL.active], 0
    RET

.update_trail:
    ; Shift trailX/Y[5..1] = [4..0]
    MOV ECX, 5
.sh_loop:
    MOV EAX, [RBX + BALL.trailX + RCX*4 - 4]
    MOV [RBX + BALL.trailX + RCX*4], EAX
    MOV EAX, [RBX + BALL.trailY + RCX*4 - 4]
    MOV [RBX + BALL.trailY + RCX*4], EAX
    DEC ECX
    JNZ <.sh_loop

    CVTTSD2SI EAX, [RBX + BALL.x]
    MOV [RBX + BALL.trailX], EAX
    CVTTSD2SI EAX, [RBX + BALL.y]
    MOV [RBX + BALL.trailY], EAX

.done:
    RET
ENDF
