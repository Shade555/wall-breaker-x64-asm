; =============================================================================
; physics_core.asm - PRNG, Score, Popups, Particles, Powerups & Brick Damage
; =============================================================================

#include constants.inc

CODE SECTION

; -----------------------------------------------------------------------------
; NextRand -> returns pseudo-random 32-bit unsigned value in EAX
; -----------------------------------------------------------------------------
NextRand FRAME
    MOV RAX, [gPrngState]
    MOV RCX, RAX
    SHL RCX, 13
    XOR RAX, RCX
    MOV RCX, RAX
    SHR RCX, 7
    XOR RAX, RCX
    MOV RCX, RAX
    SHL RCX, 17
    XOR RAX, RCX
    MOV [gPrngState], RAX
    SHR RAX, 16
    AND EAX, 7FFFFFFFh
    RET
ENDF

; -----------------------------------------------------------------------------
; RandRange(maxVal) -> returns 0 .. maxVal-1 in EAX
; -----------------------------------------------------------------------------
RandRange FRAME maxVal
    CALL NextRand
    MOV ECX, [maxVal]
    CMP ECX, 1
    JLE >.ret_zero
    XOR EDX, EDX
    DIV ECX
    MOV EAX, EDX
    RET
.ret_zero:
    XOR EAX, EAX
    RET
ENDF

; -----------------------------------------------------------------------------
; AddScore(basePts): Adds combo-scaled points and updates gHighScore
; -----------------------------------------------------------------------------
AddScore FRAME basePts
    MOV EAX, [basePts]
    MOV ECX, [gCombo]
    CMP ECX, 1
    JLE >.no_mult
    CMP ECX, 8
    JLE >.mult_ok
    MOV ECX, 8
.mult_ok:
    ; bonus = basePts * (combo - 1) / 4
    DEC ECX
    IMUL ECX, EAX
    SAR ECX, 2
    ADD EAX, ECX
.no_mult:
    ADD [gScore], EAX
    MOV EAX, [gScore]
    CMP EAX, [gHighScore]
    JLE >.done
    MOV [gHighScore], EAX
.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; SpawnPopup(px, py, pStr, color)
; -----------------------------------------------------------------------------
SpawnPopup FRAME px, py, pStr, color
USES RBX, RSI, RDI

    LEA RBX, [gPopups]
    XOR ECX, ECX
.find_slot:
    CMP ECX, MAX_POPUPS
    JGE >>.done
    CMP D[RBX + POPUP.active], 0
    JE >.found
    ADD RBX, SIZEOF POPUP
    INC ECX
    JMP <.find_slot

.found:
    MOV EAX, [px]
    MOV [RBX + POPUP.x], EAX
    MOV EAX, [py]
    MOV [RBX + POPUP.y], EAX
    MOV EAX, [color]
    MOV [RBX + POPUP.color], EAX
    MOV D[RBX + POPUP.active], 1
    MOV D[RBX + POPUP.life], 42

    MOV RSI, [pStr]
    LEA RDI, [RBX + POPUP.text]
    XOR ECX, ECX
.copy_str:
    CMP ECX, 15
    JGE >.term
    MOV AL, [RSI + RCX]
    MOV [RDI + RCX], AL
    TEST AL, AL
    JZ >.done
    INC ECX
    JMP <.copy_str
.term:
    MOV B[RDI + 15], 0
.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; SpawnBurst(cx, cy, color, count, speedScale)
; -----------------------------------------------------------------------------
SpawnBurst FRAME argX, argY, color, count, speedScale
USES RBX, RSI, RDI, R12, R13, R14

    MOV R12D, [count]
    LEA RBX, [gParticles]
    XOR R13D, R13D              ; slot index

.spawn_loop:
    CMP R12D, 0
    JLE >>.done
.find_slot:
    CMP R13D, MAX_PARTICLES
    JGE >>.done
    CMP D[RBX + PARTICLE.active], 0
    JE >.got_slot
    ADD RBX, SIZEOF PARTICLE
    INC R13D
    JMP <.find_slot

.got_slot:
    MOV D[RBX + PARTICLE.active], 1
    MOV EAX, [color]
    MOV D[RBX + PARTICLE.color], EAX

    ; x, y = cx, cy
    CVTSI2SD XMM0, D[argX]
    MOVSD [RBX + PARTICLE.x], XMM0
    CVTSI2SD XMM0, D[argY]
    MOVSD [RBX + PARTICLE.y], XMM0

    ; Random vx in [-4.5, +4.5] * speedScale / 10
    INVOKE RandRange, 90
    SUB EAX, 45
    IMUL EAX, [speedScale]
    CVTSI2SD XMM0, EAX
    MOV EAX, 100
    CVTSI2SD XMM1, EAX
    DIVSD XMM0, XMM1
    MOVSD [RBX + PARTICLE.vx], XMM0

    ; Random vy in [-5.0, +3.5] * speedScale / 10
    INVOKE RandRange, 85
    SUB EAX, 50
    IMUL EAX, [speedScale]
    CVTSI2SD XMM0, EAX
    MOV EAX, 100
    CVTSI2SD XMM1, EAX
    DIVSD XMM0, XMM1
    MOVSD [RBX + PARTICLE.vy], XMM0

    INVOKE RandRange, 18
    ADD EAX, 16
    MOV D[RBX + PARTICLE.life], EAX
    MOV D[RBX + PARTICLE.maxLife], EAX

    INVOKE RandRange, 3
    ADD EAX, 2
    MOV D[RBX + PARTICLE.size], EAX

    ADD RBX, SIZEOF PARTICLE
    INC R13D
    DEC R12D
    JMP <<.spawn_loop

.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; GetBrickColor(hp, btype) -> returns main RGB color in EAX
; -----------------------------------------------------------------------------
GetBrickColor FRAME hp, btype
    MOV ECX, [btype]
    CMP ECX, BRICK_STEEL
    JNE >.not_steel
    MOV EAX, COL_STEEL
    RET
.not_steel:
    MOV EAX, [hp]
    CMP EAX, 1
    JGE >.min_ok
    MOV EAX, 1
.min_ok:
    CMP EAX, 5
    JLE >.idx_ok
    MOV EAX, 5
.idx_ok:
    LEA RCX, [gHpMainColors]
    MOV EAX, [RCX + RAX*4]
    RET
ENDF

; -----------------------------------------------------------------------------
; MaybeDropPowerup(cx, cy, maxHp)
; -----------------------------------------------------------------------------
MaybeDropPowerup FRAME argX, argY, maxHp
USES RBX

    ; chance = 22 + maxHp * 4 (26% to 42%)
    INVOKE RandRange, 100
    MOV ECX, [maxHp]
    IMUL ECX, ECX, 4
    ADD ECX, 22
    CMP EAX, ECX
    JGE >>.done

    LEA RBX, [gPowerups]
    XOR ECX, ECX
.find_slot:
    CMP ECX, MAX_POWERUPS
    JGE >>.done
    CMP D[RBX + POWERUP.active], 0
    JE >.got_slot
    ADD RBX, SIZEOF POWERUP
    INC ECX
    JMP <.find_slot

.got_slot:
    MOV D[RBX + POWERUP.active], 1
    CVTSI2SD XMM0, D[argX]
    MOVSD [RBX + POWERUP.x], XMM0
    CVTSI2SD XMM0, D[argY]
    MOVSD [RBX + POWERUP.y], XMM0
    MOVSD XMM0, [fPwrDropVy]
    MOVSD [RBX + POWERUP.vy], XMM0

    ; Weighted powerup roll 0..99
    INVOKE RandRange, 100
    CMP EAX, 18
    JL >>.p_wide
    CMP EAX, 36
    JL >>.p_multi
    CMP EAX, 52
    JL >>.p_fire
    CMP EAX, 68
    JL >>.p_laser
    CMP EAX, 82
    JL >>.p_slow
    CMP EAX, 90
    JL >>.p_life
    MOV D[RBX + POWERUP.ptype], PWR_SHIELD
    RET
.p_wide:
    MOV D[RBX + POWERUP.ptype], PWR_WIDE
    RET
.p_multi:
    MOV D[RBX + POWERUP.ptype], PWR_MULTI
    RET
.p_fire:
    MOV D[RBX + POWERUP.ptype], PWR_FIRE
    RET
.p_laser:
    MOV D[RBX + POWERUP.ptype], PWR_LASER
    RET
.p_slow:
    MOV D[RBX + POWERUP.ptype], PWR_SLOW
    RET
.p_life:
    MOV D[RBX + POWERUP.ptype], PWR_LIFE
.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; SpawnMultiBalls: Duplicates first active ball up to 2 extra balls
; -----------------------------------------------------------------------------
SpawnMultiBalls FRAME
USES RBX, RSI, RDI, R12, R13

    ; Find first active ball as source
    LEA RSI, [gBalls]
    XOR ECX, ECX
.find_src:
    CMP ECX, MAX_BALLS
    JGE >>.done
    CMP D[RSI + BALL.active], 0
    JNE >.got_src
    ADD RSI, SIZEOF BALL
    INC ECX
    JMP <.find_src

.got_src:
    MOV D[RSI + BALL.stuck], 0
    MOV R12D, 2                 ; spawn up to 2 extra balls
    LEA RDI, [gBalls]
    XOR R13D, R13D

.find_dst:
    CMP R12D, 0
    JLE >>.done
    CMP R13D, MAX_BALLS
    JGE >>.done
    CMP D[RDI + BALL.active], 0
    JE >.spawn_it
    ADD RDI, SIZEOF BALL
    INC R13D
    JMP <.find_dst

.spawn_it:
    MOV D[RDI + BALL.active], 1
    MOV D[RDI + BALL.stuck], 0
    MOV D[RDI + BALL.portalCd], 0
    MOV D[RDI + BALL.bumperCd], 0

    MOVSD XMM0, [RSI + BALL.x]
    MOVSD [RDI + BALL.x], XMM0
    MOVSD XMM0, [RSI + BALL.y]
    MOVSD [RDI + BALL.y], XMM0
    MOVSD XMM0, [RSI + BALL.speed]
    MOVSD [RDI + BALL.speed], XMM0

    ; Perturb angle cleanly based on R12D (1 or 2)
    MOVSD XMM0, [RSI + BALL.vx]
    MOVSD XMM1, [RSI + BALL.vy]
    CMP R12D, 2
    JE >>.ang_left
    ; Rotate slightly right: vx' = vx*0.85 - vy*0.45, vy' = vy*0.85 + vx*0.45
    MOVSD XMM2, XMM0
    MULSD XMM2, [fZeroPoint85]
    MOVSD XMM3, XMM1
    MULSD XMM3, [fHalf]
    SUBSD XMM2, XMM3
    MOVSD [RDI + BALL.vx], XMM2

    MOVSD XMM2, XMM1
    MULSD XMM2, [fZeroPoint85]
    MOVSD XMM3, XMM0
    MULSD XMM3, [fHalf]
    ADDSD XMM2, XMM3
    MOVSD [RDI + BALL.vy], XMM2
    JMP >>.norm_new

.ang_left:
    MOVSD XMM2, XMM0
    MULSD XMM2, [fZeroPoint85]
    MOVSD XMM3, XMM1
    MULSD XMM3, [fHalf]
    ADDSD XMM2, XMM3
    MOVSD [RDI + BALL.vx], XMM2

    MOVSD XMM2, XMM1
    MULSD XMM2, [fZeroPoint85]
    MOVSD XMM3, XMM0
    MULSD XMM3, [fHalf]
    SUBSD XMM2, XMM3
    MOVSD [RDI + BALL.vy], XMM2

.norm_new:
    INVOKE NormalizeBallVel, RDI

    ; Init trail
    CVTTSD2SI EAX, [RDI + BALL.x]
    CVTTSD2SI EDX, [RDI + BALL.y]
    XOR ECX, ECX
.tr:
    MOV D[RDI + BALL.trailX + RCX*4], EAX
    MOV D[RDI + BALL.trailY + RCX*4], EDX
    INC ECX
    CMP ECX, 6
    JL <.tr

    DEC R12D
    ADD RDI, SIZEOF BALL
    INC R13D
    JMP <<.find_dst

.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; ApplyPowerup(ptype)
; -----------------------------------------------------------------------------
ApplyPowerup FRAME ptype
USES RBX

    INVOKE AddScore, 150
    INVOKE PlaySfx, SFX_POWERUP

    CVTTSD2SI EBX, [gPadX]
    MOV EAX, [ptype]

    CMP EAX, PWR_WIDE
    JE >>.do_wide
    CMP EAX, PWR_MULTI
    JE >>.do_multi
    CMP EAX, PWR_FIRE
    JE >>.do_fire
    CMP EAX, PWR_LASER
    JE >>.do_laser
    CMP EAX, PWR_SLOW
    JE >>.do_slow
    CMP EAX, PWR_LIFE
    JE >>.do_life
    CMP EAX, PWR_SHIELD
    JE >>.do_shield
    RET

.do_wide:
    MOV D[gWideTimer], 720
    MOVSD XMM0, [gPadBaseW]
    MULSD XMM0, [fWideScale]
    MOVSD [gPadTargetW], XMM0
    INVOKE SpawnPopup, EBX, 630, ADDR strPopWide, COL_CYAN
    RET

.do_multi:
    CALL SpawnMultiBalls
    INVOKE SpawnPopup, EBX, 630, ADDR strPopMulti, COL_MAGENTA
    RET

.do_fire:
    MOV D[gFireTimer], 600
    INVOKE SpawnPopup, EBX, 630, ADDR strPopFire, COL_ORANGE
    RET

.do_laser:
    MOV D[gLaserTimer], 660
    INVOKE SpawnPopup, EBX, 630, ADDR strPopLaser, COL_YELLOW
    RET

.do_slow:
    MOV D[gSlowTimer], 600
    INVOKE SpawnPopup, EBX, 630, ADDR strPopSlow, COL_SKY
    RET

.do_life:
    CMP D[gLives], 5
    JGE >.life_cap
    INC D[gLives]
.life_cap:
    INVOKE AddScore, 100
    INVOKE SpawnPopup, EBX, 630, ADDR strPopLife, COL_GREEN
    RET

.do_shield:
    MOV D[gShieldTimer], 720
    INVOKE SpawnPopup, EBX, 630, ADDR strPopShield, COL_GOLD
    RET
ENDF

; -----------------------------------------------------------------------------
; TriggerExplosion(cx, cy): Damages all nearby breakable bricks within 108px
; -----------------------------------------------------------------------------
TriggerExplosion FRAME argX, argY
USES RBX, RSI, R12, R13

    MOV D[gScreenShake], 12
    INVOKE PlaySfx, SFX_EXPLODE
    INVOKE SpawnBurst, [argX], [argY], COL_ORANGE, 24, 16
    INVOKE SpawnPopup, [argX], [argY], ADDR strPopBoom, COL_YELLOW

    CVTSI2SD XMM4, D[argX]
    CVTSI2SD XMM5, D[argY]

    LEA RBX, [gBricks]
    XOR R12D, R12D
.loop:
    CMP R12D, MAX_BRICKS
    JGE >>.done

    CMP D[RBX + BRICK.active], 0
    JE >>.next
    CMP D[RBX + BRICK.btype], BRICK_STEEL
    JE >>.next

    ; Brick center
    MOV EAX, [RBX + BRICK.w]
    SHR EAX, 1
    CVTSI2SD XMM0, EAX
    ADDSD XMM0, [RBX + BRICK.x]
    SUBSD XMM0, XMM4
    MULSD XMM0, XMM0

    MOV EAX, [RBX + BRICK.h]
    SHR EAX, 1
    CVTSI2SD XMM1, EAX
    ADDSD XMM1, [RBX + BRICK.y]
    SUBSD XMM1, XMM5
    MULSD XMM1, XMM1

    ADDSD XMM0, XMM1
    UCOMISD XMM0, [fBlastRadSq]
    JA >.next

    ; Save XMM4/XMM5 in locals? No, DamageBrick might use XMM0..3 or recurse!
    ; So pass idx and reload XMM4/XMM5 right after!
    INVOKE DamageBrick, R12D, 2, 0
    CVTSI2SD XMM4, D[argX]
    CVTSI2SD XMM5, D[argY]

.next:
    ADD RBX, SIZEOF BRICK
    INC R12D
    JMP <.loop

.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; DamageBrick(brickIdx, dmg, playSound): Applies damage and handles destruction
; -----------------------------------------------------------------------------
DamageBrick FRAME brickIdx, dmg, playSound
USES RBX, R12, R13, R14

    MOV EAX, [brickIdx]
    IMUL RAX, RAX, SIZEOF BRICK
    LEA RBX, [gBricks]
    ADD RBX, RAX

    CMP D[RBX + BRICK.active], 0
    JE >>.done

    ; Center coords in R12D, R13D
    CVTTSD2SI R12D, [RBX + BRICK.x]
    MOV EAX, [RBX + BRICK.w]
    SHR EAX, 1
    ADD R12D, EAX

    CVTTSD2SI R13D, [RBX + BRICK.y]
    MOV EAX, [RBX + BRICK.h]
    SHR EAX, 1
    ADD R13D, EAX

    MOV D[RBX + BRICK.flash], 5

    CMP D[RBX + BRICK.btype], BRICK_STEEL
    JNE >>.breakable

    ; Indestructible steel hit
    INVOKE SpawnBurst, R12D, R13D, COL_STEEL_HI, 5, 8
    CMP D[playSound], 0
    JE >>.done
    INVOKE PlaySfx, SFX_STEEL
    JMP >>.done

.breakable:
    ; Get pre-hit color in R14D for particles
    INVOKE GetBrickColor, [RBX + BRICK.hp], [RBX + BRICK.btype]
    MOV R14D, EAX

    INC D[gCombo]
    MOV EAX, [gCombo]
    CMP EAX, [gMaxCombo]
    JLE >.combo_ok
    MOV [gMaxCombo], EAX
.combo_ok:

    MOV D[RBX + BRICK.regenTick], 0
    MOV EAX, [RBX + BRICK.hp]
    SUB EAX, [dmg]
    MOV [RBX + BRICK.hp], EAX
    CMP EAX, 0
    JLE >>.destroyed

    ; Still alive (color shifts down to new HP!)
    INVOKE AddScore, 30
    INVOKE SpawnBurst, R12D, R13D, R14D, 5, 7
    CMP D[playSound], 0
    JE >>.done
    INVOKE PlaySfx, SFX_BRICK
    JMP >>.done

.destroyed:
    MOV D[RBX + BRICK.active], 0
    DEC D[gBricksLeft]

    MOV EAX, [RBX + BRICK.maxHp]
    IMUL EAX, EAX, 100
    INVOKE AddScore, EAX

    INVOKE SpawnBurst, R12D, R13D, R14D, 14, 11

    CMP D[RBX + BRICK.btype], BRICK_EXPLOSIVE
    JNE >.not_tnt
    INVOKE TriggerExplosion, R12D, R13D
    JMP >.drop_check

.not_tnt:
    CMP D[playSound], 0
    JE >.drop_check
    INVOKE PlaySfx, SFX_BREAK

.drop_check:
    INVOKE MaybeDropPowerup, R12D, R13D, [RBX + BRICK.maxHp]

.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; NormalizeBallVel(pBall): Keeps ball magnitude == pBall.speed & prevents flat vy
; -----------------------------------------------------------------------------
NormalizeBallVel FRAME pBall
USES RBX
    MOV RBX, [pBall]
    MOVSD XMM0, [RBX + BALL.vx]
    MOVSD XMM1, [RBX + BALL.vy]

    ; len = sqrt(vx*vx + vy*vy)
    MOVSD XMM2, XMM0
    MULSD XMM2, XMM2
    MOVSD XMM3, XMM1
    MULSD XMM3, XMM3
    ADDSD XMM2, XMM3
    SQRTSD XMM2, XMM2

    ; Guard near-zero length
    MOV EAX, 1
    CVTSI2SD XMM3, EAX
    MOV EAX, 1000
    CVTSI2SD XMM4, EAX
    DIVSD XMM3, XMM4            ; 0.001
    UCOMISD XMM2, XMM3
    JA >.len_ok
    MOVSD XMM0, [fBallLaunchVx]
    MOVSD XMM1, [fBallLaunchVy]
    JMP >>.apply_speed

.len_ok:
    DIVSD XMM0, XMM2            ; ux
    DIVSD XMM1, XMM2            ; uy

    ; Check |uy| >= 0.36
    MOVSD XMM2, XMM1
    UCOMISD XMM2, [fZero]
    JAE >.uy_abs
    MULSD XMM2, [fMinusOne]
.uy_abs:
    UCOMISD XMM2, [fMinVyRatio]
    JAE >>.apply_speed

    ; Clamp uy to +-0.36 and recompute ux = sign(ux) * sqrt(1 - 0.36^2)
    UCOMISD XMM1, [fZero]
    JB >.uy_neg
    MOVSD XMM1, [fMinVyRatio]
    JMP >.recomp_ux
.uy_neg:
    MOVSD XMM1, [fMinVyRatio]
    MULSD XMM1, [fMinusOne]
.recomp_ux:
    MOVSD XMM3, [fOne]
    MOVSD XMM4, XMM1
    MULSD XMM4, XMM4
    SUBSD XMM3, XMM4
    SQRTSD XMM3, XMM3
    UCOMISD XMM0, [fZero]
    JAE >.ux_pos
    MULSD XMM3, [fMinusOne]
.ux_pos:
    MOVSD XMM0, XMM3

.apply_speed:
    MOVSD XMM2, [RBX + BALL.speed]
    MULSD XMM0, XMM2
    MULSD XMM1, XMM2
    MOVSD [RBX + BALL.vx], XMM0
    MOVSD [RBX + BALL.vy], XMM1
    RET
ENDF

; -----------------------------------------------------------------------------
; FirePlayerLasers: Fires twin laser bolts from paddle edges
; -----------------------------------------------------------------------------
FirePlayerLasers FRAME
USES RBX, RSI, R12

    CMP D[gLaserTimer], 0
    JLE >>.done
    CMP D[gLaserCd], 0
    JG >>.done

    MOV D[gLaserCd], 14
    MOV R12D, 2                 ; left & right bolt
    LEA RBX, [gLasers]
    XOR ECX, ECX

.find_slot:
    CMP R12D, 0
    JLE >>.fired_sfx
    CMP ECX, MAX_LASERS
    JGE >>.fired_sfx
    CMP D[RBX + BOLT.active], 0
    JE >.spawn_bolt
    ADD RBX, SIZEOF BOLT
    INC ECX
    JMP <.find_slot

.spawn_bolt:
    MOV D[RBX + BOLT.active], 1
    MOVSD XMM0, [gPadCurW]
    MULSD XMM0, [fHalf]
    SUBSD XMM0, [fFour]
    SUBSD XMM0, [fTwo]
    MOVSD XMM1, [gPadX]
    CMP R12D, 2
    JE >.left_tip
    ADDSD XMM1, XMM0
    JMP >.set_pos
.left_tip:
    SUBSD XMM1, XMM0
.set_pos:
    MOVSD [RBX + BOLT.x], XMM1
    MOVSD XMM2, [fPadTopY]
    SUBSD XMM2, [fFour]
    MOVSD [RBX + BOLT.y], XMM2
    MOVSD XMM0, [fZero]
    MOVSD [RBX + BOLT.vx], XMM0
    MOVSD XMM0, [fLaserVy]
    MOVSD [RBX + BOLT.vy], XMM0

    DEC R12D
    ADD RBX, SIZEOF BOLT
    INC ECX
    JMP <.find_slot

.fired_sfx:
    CMP R12D, 2
    JE >.done
    INVOKE PlaySfx, SFX_LASER
.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; LaunchStuckBalls: Releases any ball resting on the paddle
; -----------------------------------------------------------------------------
LaunchStuckBalls FRAME
USES RBX
    LEA RBX, [gBalls]
    XOR ECX, ECX
    XOR EDX, EDX
.loop:
    CMP ECX, MAX_BALLS
    JGE >.done
    CMP D[RBX + BALL.active], 0
    JE >.next
    CMP D[RBX + BALL.stuck], 0
    JE >.next
    MOV D[RBX + BALL.stuck], 0
    MOV EDX, 1
.next:
    ADD RBX, SIZEOF BALL
    INC ECX
    JMP <.loop
.done:
    TEST EDX, EDX
    JZ >.no_sfx
    INVOKE PlaySfx, SFX_PADDLE
.no_sfx:
    RET
ENDF
