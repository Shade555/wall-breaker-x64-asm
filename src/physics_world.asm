; =============================================================================
; physics_world.asm - Boss AI, Projectiles, Timers, Input & Main Game Tick
; =============================================================================

#include constants.inc

CODE SECTION

; -----------------------------------------------------------------------------
; DamageBoss(dmg): Applies damage to Level 8 Overlord Monolith
; -----------------------------------------------------------------------------
DamageBoss FRAME dmg
USES RBX, R12, R13

    LEA RBX, [gBoss]
    CMP D[RBX + BOSS.active], 0
    JE >>.done

    MOV D[RBX + BOSS.flash], 6
    MOV EAX, [RBX + BOSS.hp]
    SUB EAX, [dmg]
    MOV [RBX + BOSS.hp], EAX
    INVOKE AddScore, 150

    CVTTSD2SI R12D, [RBX + BOSS.x]
    ADD R12D, 70
    CVTTSD2SI R13D, [RBX + BOSS.y]
    ADD R13D, 20

    CMP D[RBX + BOSS.hp], 0
    JLE >>.boss_dead

    INVOKE SpawnBurst, R12D, R13D, COL_RED, 8, 9
    INVOKE PlaySfx, SFX_BRICK
    RET

.boss_dead:
    MOV D[RBX + BOSS.active], 0
    MOV D[gScreenShake], 18
    INVOKE AddScore, 2000
    INVOKE SpawnBurst, R12D, R13D, COL_GOLD, 42, 18
    INVOKE SpawnPopup, R12D, R13D, ADDR strPopBoom, COL_YELLOW
    INVOKE PlaySfx, SFX_EXPLODE

.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; UpdateMovingAndRegenBricks: Updates patrolling & healing bricks + flashes
; -----------------------------------------------------------------------------
UpdateBricks FRAME
USES RBX, R12, R13, R14

    LEA RBX, [gBricks]
    XOR R12D, R12D
.loop:
    CMP R12D, MAX_BRICKS
    JGE >>.done

    CMP D[RBX + BRICK.active], 0
    JE >>.next

    ; Decay hit flash
    CMP D[RBX + BRICK.flash], 0
    JLE >.no_flash
    DEC D[RBX + BRICK.flash]
.no_flash:

    ; Moving patrol brick
    CMP D[RBX + BRICK.btype], BRICK_MOVING
    JNE >>.chk_regen

    MOVSD XMM0, [RBX + BRICK.x]
    ADDSD XMM0, [RBX + BRICK.vx]
    MOVSD [RBX + BRICK.x], XMM0

    UCOMISD XMM0, [RBX + BRICK.minX]
    JAE >.chk_max_x
    MOVSD XMM0, [RBX + BRICK.minX]
    MOVSD [RBX + BRICK.x], XMM0
    MOVSD XMM1, [RBX + BRICK.vx]
    MULSD XMM1, [fMinusOne]
    MOVSD [RBX + BRICK.vx], XMM1
    JMP >.chk_regen

.chk_max_x:
    UCOMISD XMM0, [RBX + BRICK.maxX]
    JBE >.chk_regen
    MOVSD XMM0, [RBX + BRICK.maxX]
    MOVSD [RBX + BRICK.x], XMM0
    MOVSD XMM1, [RBX + BRICK.vx]
    MULSD XMM1, [fMinusOne]
    MOVSD [RBX + BRICK.vx], XMM1

.chk_regen:
    CMP D[RBX + BRICK.btype], BRICK_REGEN
    JNE >>.next
    MOV EAX, [RBX + BRICK.hp]
    CMP EAX, [RBX + BRICK.maxHp]
    JGE >>.next

    INC D[RBX + BRICK.regenTick]
    CMP D[RBX + BRICK.regenTick], 270
    JL >>.next

    MOV D[RBX + BRICK.regenTick], 0
    INC D[RBX + BRICK.hp]
    MOV D[RBX + BRICK.flash], 6
    CVTTSD2SI R13D, [RBX + BRICK.x]
    ADD R13D, 34
    CVTTSD2SI R14D, [RBX + BRICK.y]
    ADD R14D, 12
    INVOKE SpawnBurst, R13D, R14D, COL_CYAN, 6, 6
    INVOKE SpawnPopup, R13D, R14D, ADDR strPopHeal, COL_CYAN

.next:
    ADD RBX, SIZEOF BRICK
    INC R12D
    JMP <<.loop

.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; UpdateBoss: Moves Level 8 Boss & fires crimson hazard bolts downward
; -----------------------------------------------------------------------------
UpdateBoss FRAME
USES RBX, RSI

    CMP D[gHasBoss], 0
    JE >>.done
    LEA RBX, [gBoss]
    CMP D[RBX + BOSS.active], 0
    JE >>.done

    CMP D[RBX + BOSS.flash], 0
    JLE >.no_flash
    DEC D[RBX + BOSS.flash]
.no_flash:

    ; Patrol horizontally
    MOVSD XMM0, [RBX + BOSS.x]
    ADDSD XMM0, [RBX + BOSS.vx]
    MOVSD [RBX + BOSS.x], XMM0

    UCOMISD XMM0, [fBossMinX]
    JAE >.chk_rmax
    MOVSD XMM0, [fBossMinX]
    MOVSD [RBX + BOSS.x], XMM0
    MOVSD XMM1, [RBX + BOSS.vx]
    MULSD XMM1, [fMinusOne]
    MOVSD [RBX + BOSS.vx], XMM1
    JMP >.fire_tick

.chk_rmax:
    UCOMISD XMM0, [fBossMaxX]
    JBE >.fire_tick
    MOVSD XMM0, [fBossMaxX]
    MOVSD [RBX + BOSS.x], XMM0
    MOVSD XMM1, [RBX + BOSS.vx]
    MULSD XMM1, [fMinusOne]
    MOVSD [RBX + BOSS.vx], XMM1

.fire_tick:
    DEC D[RBX + BOSS.fireTimer]
    JG >>.done

    ; Reset fire timer (faster when HP <= 12!)
    MOV D[RBX + BOSS.fireTimer], 95
    CMP D[RBX + BOSS.hp], 12
    JG >.spawn_haz
    MOV D[RBX + BOSS.fireTimer], 68

.spawn_haz:
    LEA RSI, [gHazards]
    XOR ECX, ECX
.find_slot:
    CMP ECX, MAX_HAZARDS
    JGE >>.done
    CMP D[RSI + BOLT.active], 0
    JE >.got_slot
    ADD RSI, SIZEOF BOLT
    INC ECX
    JMP <.find_slot

.got_slot:
    MOV D[RSI + BOLT.active], 1
    MOVSD XMM0, [RBX + BOSS.x]
    ADDSD XMM0, [fBossHalfW]
    MOVSD [RSI + BOLT.x], XMM0
    MOVSD XMM1, [RBX + BOSS.y]
    ADDSD XMM1, [fBossH]
    MOVSD [RSI + BOLT.y], XMM1
    MOVSD XMM0, [fZero]
    MOVSD [RSI + BOLT.vx], XMM0
    MOVSD XMM0, [fHazardVy]
    MOVSD [RSI + BOLT.vy], XMM0
    INVOKE PlaySfx, SFX_LASER

.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; UpdateProjectilesAndDrops: Player lasers, Boss hazards, Powerups, Particles
; -----------------------------------------------------------------------------
UpdateProjectilesAndDrops FRAME
USES RBX, RSI, R12, R13

    ; --- 1. Player Lasers ---
    LEA RBX, [gLasers]
    XOR R12D, R12D
.laser_loop:
    CMP R12D, MAX_LASERS
    JGE >>.lasers_done
    CMP D[RBX + BOLT.active], 0
    JE >>.next_laser

    MOVSD XMM0, [RBX + BOLT.y]
    ADDSD XMM0, [RBX + BOLT.vy]
    MOVSD [RBX + BOLT.y], XMM0

    UCOMISD XMM0, [fArenaTop]
    JAE >.l_chk_boss
    MOV D[RBX + BOLT.active], 0
    JMP >>.next_laser

.l_chk_boss:
    CMP D[gHasBoss], 0
    JE >>.l_chk_bricks
    LEA RSI, [gBoss]
    CMP D[RSI + BOSS.active], 0
    JE >>.l_chk_bricks
    MOVSD XMM1, [RBX + BOLT.x]
    UCOMISD XMM1, [RSI + BOSS.x]
    JB >>.l_chk_bricks
    MOVSD XMM2, [RSI + BOSS.x]
    CVTSI2SD XMM3, D[RSI + BOSS.w]
    ADDSD XMM2, XMM3
    UCOMISD XMM1, XMM2
    JA >.l_chk_bricks
    MOVSD XMM2, [RSI + BOSS.y]
    CVTSI2SD XMM3, D[RSI + BOSS.h]
    ADDSD XMM2, XMM3
    UCOMISD XMM0, XMM2
    JA >.l_chk_bricks
    MOV D[RBX + BOLT.active], 0
    INVOKE DamageBoss, 1
    JMP >>.next_laser

.l_chk_bricks:
    LEA RSI, [gBricks]
    XOR R13D, R13D
.lb_loop:
    CMP R13D, MAX_BRICKS
    JGE >>.next_laser
    CMP D[RSI + BRICK.active], 0
    JE >>.lb_next

    MOVSD XMM1, [RBX + BOLT.x]
    MOVSD XMM2, [RSI + BRICK.x]
    UCOMISD XMM1, XMM2
    JB >>.lb_next
    CVTSI2SD XMM3, D[RSI + BRICK.w]
    ADDSD XMM2, XMM3
    UCOMISD XMM1, XMM2
    JA >>.lb_next

    MOVSD XMM0, [RBX + BOLT.y]
    MOVSD XMM2, [RSI + BRICK.y]
    UCOMISD XMM0, XMM2
    JB >.lb_next
    CVTSI2SD XMM3, D[RSI + BRICK.h]
    ADDSD XMM2, XMM3
    UCOMISD XMM0, XMM2
    JA >.lb_next

    MOV D[RBX + BOLT.active], 0
    INVOKE DamageBrick, R13D, 1, 1
    JMP >.next_laser

.lb_next:
    ADD RSI, SIZEOF BRICK
    INC R13D
    JMP <.lb_loop

.next_laser:
    ADD RBX, SIZEOF BOLT
    INC R12D
    JMP <<.laser_loop
.lasers_done:

    ; --- 2. Enemy Hazard Bolts ---
    LEA RBX, [gHazards]
    XOR R12D, R12D
.haz_loop:
    CMP R12D, MAX_HAZARDS
    JGE >>.haz_done
    CMP D[RBX + BOLT.active], 0
    JE >>.next_haz

    MOVSD XMM0, [RBX + BOLT.y]
    ADDSD XMM0, [RBX + BOLT.vy]
    MOVSD [RBX + BOLT.y], XMM0

    ; Safety shield blocks hazard bolts!
    CMP D[gShieldTimer], 0
    JLE >.h_chk_pad
    UCOMISD XMM0, [fShieldY]
    JB >.h_chk_pad
    MOV D[RBX + BOLT.active], 0
    CVTTSD2SI EAX, [RBX + BOLT.x]
    INVOKE SpawnBurst, EAX, 676, COL_GOLD, 6, 7
    JMP >>.next_haz

.h_chk_pad:
    UCOMISD XMM0, [fArenaBottom]
    JBE >.h_pad_box
    MOV D[RBX + BOLT.active], 0
    JMP >>.next_haz

.h_pad_box:
    UCOMISD XMM0, [fPadTopY]
    JB >>.next_haz
    MOVSD XMM2, [fPadTopY]
    ADDSD XMM2, [fPadH]
    UCOMISD XMM0, XMM2
    JA >>.next_haz

    MOVSD XMM1, [RBX + BOLT.x]
    SUBSD XMM1, [gPadX]
    UCOMISD XMM1, [fZero]
    JAE >.h_abs
    MULSD XMM1, [fMinusOne]
.h_abs:
    MOVSD XMM3, [gPadCurW]
    MULSD XMM3, [fHalf]
    UCOMISD XMM1, XMM3
    JA >>.next_haz

    ; Hazard hit paddle!
    MOV D[RBX + BOLT.active], 0
    CMP D[gPadInvuln], 0
    JG >>.next_haz
    MOV D[gPadInvuln], 75
    MOV D[gPadStunTimer], 35
    MOV D[gScreenShake], 10
    DEC D[gLives]
    INVOKE PlaySfx, SFX_EXPLODE
    CVTTSD2SI EAX, [gPadX]
    INVOKE SpawnBurst, EAX, PADDLE_Y, COL_RED, 16, 12
    INVOKE SpawnPopup, EAX, 628, ADDR strPopHit, COL_RED
    CMP D[gLives], 0
    JG >.next_haz
    MOV D[gState], STATE_GAME_OVER
    RET

.next_haz:
    ADD RBX, SIZEOF BOLT
    INC R12D
    JMP <<.haz_loop
.haz_done:

    ; --- 3. Falling Powerup Capsules ---
    LEA RBX, [gPowerups]
    XOR R12D, R12D
.pwr_loop:
    CMP R12D, MAX_POWERUPS
    JGE >>.pwr_done
    CMP D[RBX + POWERUP.active], 0
    JE >>.next_pwr

    MOVSD XMM0, [RBX + POWERUP.y]
    ADDSD XMM0, [RBX + POWERUP.vy]
    MOVSD [RBX + POWERUP.y], XMM0

    UCOMISD XMM0, [fArenaBottom]
    JBE >.p_chk_pad
    MOV D[RBX + POWERUP.active], 0
    JMP >>.next_pwr

.p_chk_pad:
    ; Capsule rect [x-16..x+16, y-8..y+8] vs paddle [padX-halfW..padX+halfW, padY..padY+16]
    MOVSD XMM1, XMM0
    ADDSD XMM1, [fFour]
    ADDSD XMM1, [fFour]
    UCOMISD XMM1, [fPadTopY]
    JB >>.next_pwr
    MOVSD XMM1, XMM0
    SUBSD XMM1, [fFour]
    SUBSD XMM1, [fFour]
    MOVSD XMM2, [fPadTopY]
    ADDSD XMM2, [fPadH]
    UCOMISD XMM1, XMM2
    JA >>.next_pwr

    MOVSD XMM1, [RBX + POWERUP.x]
    SUBSD XMM1, [gPadX]
    UCOMISD XMM1, [fZero]
    JAE >.p_abs
    MULSD XMM1, [fMinusOne]
.p_abs:
    MOVSD XMM2, [gPadCurW]
    MULSD XMM2, [fHalf]
    ADDSD XMM2, [fBallRadius]
    ADDSD XMM2, [fBallRadius]
    UCOMISD XMM1, XMM2
    JA >.next_pwr

    MOV D[RBX + POWERUP.active], 0
    INVOKE ApplyPowerup, [RBX + POWERUP.ptype]

.next_pwr:
    ADD RBX, SIZEOF POWERUP
    INC R12D
    JMP <<.pwr_loop
.pwr_done:

    ; --- 4. Particles ---
    LEA RBX, [gParticles]
    XOR R12D, R12D
.part_loop:
    CMP R12D, MAX_PARTICLES
    JGE >>.part_done
    CMP D[RBX + PARTICLE.active], 0
    JE >>.next_part

    MOVSD XMM0, [RBX + PARTICLE.x]
    ADDSD XMM0, [RBX + PARTICLE.vx]
    MOVSD [RBX + PARTICLE.x], XMM0
    MOVSD XMM1, [RBX + PARTICLE.y]
    ADDSD XMM1, [RBX + PARTICLE.vy]
    MOVSD [RBX + PARTICLE.y], XMM1

    ; Gravity on particles
    MOVSD XMM2, [RBX + PARTICLE.vy]
    ADDSD XMM2, [fGravityPullY]
    ADDSD XMM2, [fGravityPullY]
    ADDSD XMM2, [fGravityPullY]
    MOVSD [RBX + PARTICLE.vy], XMM2

    DEC D[RBX + PARTICLE.life]
    JG >.next_part
    MOV D[RBX + PARTICLE.active], 0

.next_part:
    ADD RBX, SIZEOF PARTICLE
    INC R12D
    JMP <.part_loop
.part_done:

    ; --- 5. Popups ---
    LEA RBX, [gPopups]
    XOR R12D, R12D
.pop_loop:
    CMP R12D, MAX_POPUPS
    JGE >>.pop_done
    CMP D[RBX + POPUP.active], 0
    JE >.next_pop
    TEST D[RBX + POPUP.life], 1
    JZ >.no_rise
    DEC D[RBX + POPUP.y]
.no_rise:
    DEC D[RBX + POPUP.life]
    JG >.next_pop
    MOV D[RBX + POPUP.active], 0
.next_pop:
    ADD RBX, SIZEOF POPUP
    INC R12D
    JMP <.pop_loop
.pop_done:

    ; --- 6. Portal / Bumper flashes ---
    LEA RBX, [gPortals]
    XOR R12D, R12D
.pf_loop:
    CMP R12D, MAX_PORTALS
    JGE >.pf_done
    CMP D[RBX + PORTAL.flash], 0
    JLE >.pf_next
    DEC D[RBX + PORTAL.flash]
.pf_next:
    ADD RBX, SIZEOF PORTAL
    INC R12D
    JMP <.pf_loop
.pf_done:

    LEA RBX, [gBumpers]
    XOR R12D, R12D
.bf_loop:
    CMP R12D, MAX_BUMPERS
    JGE >.bf_done
    CMP D[RBX + BUMPER.flash], 0
    JLE >.bf_next
    DEC D[RBX + BUMPER.flash]
.bf_next:
    ADD RBX, SIZEOF BUMPER
    INC R12D
    JMP <.bf_loop
.bf_done:

    RET
ENDF

; -----------------------------------------------------------------------------
; IsKeyDown(vk): Returns AX=8000h if latched via WndProc or foreground async
; -----------------------------------------------------------------------------
IsKeyDown FRAME vk
    MOV EAX, [vk]
    CMP EAX, 255
    JA >.ret0
    LEA RCX, [gKeyDown]
    CMP B[RCX + RAX], 0
    JNE >.ret1
    INVOKE GetAsyncKeyState, EAX
    TEST AX, 8000h
    JNZ >.chk_fg
.ret0:
    XOR EAX, EAX
    RET
.chk_fg:
    INVOKE GetForegroundWindow
    CMP RAX, [gHwnd]
    JNE <.ret0
.ret1:
    MOV EAX, 8000h
    RET
ENDF

; -----------------------------------------------------------------------------
; UpdateGame: Main 60 Hz frame tick (Input + State + Simulation)
; -----------------------------------------------------------------------------
UpdateGame FRAME
USES RBX, RSI, RDI, R12

    INC D[gFrameCount]

    ; Mix entropy into PRNG
    MOV EAX, [gFrameCount]
    XOR [gPrngState], RAX

    CMP D[gScreenShake], 0
    JLE >.no_shk
    DEC D[gScreenShake]
.no_shk:

    ; --- Edge-detected action keys ---
    INVOKE IsKeyDown, VK_SPACE
    TEST AX, 8000h
    SETNZ AL
    MOVZX R12D, AL              ; current Space state

    INVOKE IsKeyDown, VK_LBUTTON
    TEST AX, 8000h
    SETNZ AL
    MOVZX EBX, AL               ; current LButton state

    ; Mute toggle [M]
    INVOKE IsKeyDown, VK_M
    TEST AX, 8000h
    SETNZ AL
    MOVZX ECX, AL
    CMP ECX, 1
    JNE >.m_upd
    CMP D[gPrevMute], 0
    JNE >.m_upd
    XOR D[gMuted], 1
.m_upd:
    MOV [gPrevMute], ECX

    ; Restart [R]
    INVOKE IsKeyDown, VK_R
    TEST AX, 8000h
    SETNZ AL
    MOVZX ECX, AL
    CMP ECX, 1
    JNE >.r_upd
    CMP D[gPrevRestart], 0
    JNE >.r_upd
    CMP D[gState], STATE_TITLE
    JE >.r_upd
    INVOKE StartNewGame, 0
    JMP >>.end_keys
.r_upd:
    MOV [gPrevRestart], ECX

    ; Pause [P]
    INVOKE IsKeyDown, VK_P
    TEST AX, 8000h
    SETNZ AL
    MOVZX ECX, AL
    CMP ECX, 1
    JNE >.p_upd
    CMP D[gPrevPause], 0
    JNE >.p_upd
    CMP D[gState], STATE_PLAYING
    JNE >.chk_unpause
    MOV D[gState], STATE_PAUSED
    JMP >.p_upd
.chk_unpause:
    CMP D[gState], STATE_PAUSED
    JNE >.p_upd
    MOV D[gState], STATE_PLAYING
.p_upd:
    MOV [gPrevPause], ECX

    ; --- State Dispatch ---
    MOV EAX, [gState]
    CMP EAX, STATE_TITLE
    JE >.st_title
    CMP EAX, STATE_LEVEL_INTRO
    JE >>.st_intro
    CMP EAX, STATE_PLAYING
    JE >>.st_playing
    CMP EAX, STATE_PAUSED
    JE >>.end_keys
    JMP >>.st_endscreen

; --- TITLE SCREEN ---
.st_title:
    ; Check number keys 1..8 for direct level select
    MOV ESI, VK_1
.num_loop:
    CMP ESI, VK_8
    JG >>.chk_start
    INVOKE IsKeyDown, ESI
    TEST AX, 8000h
    JZ >.next_num
    SUB ESI, VK_1
    INVOKE StartNewGame, ESI
    JMP >>.end_keys
.next_num:
    INC ESI
    JMP <.num_loop

.chk_start:
    ; Start on Space or LClick edge
    CMP R12D, 1
    JNE >.chk_click_start
    CMP D[gPrevSpace], 0
    JE >.do_start
.chk_click_start:
    CMP EBX, 1
    JNE >>.end_keys
    CMP D[gPrevMouseDown], 0
    JNE >>.end_keys
.do_start:
    INVOKE StartNewGame, 0
    JMP >>.end_keys

; --- LEVEL INTRO ---
.st_intro:
    DEC D[gIntroTimer]
    JLE >.enter_play
    CMP R12D, 1
    JNE >.intro_click
    CMP D[gPrevSpace], 0
    JE >.enter_play
.intro_click:
    CMP EBX, 1
    JNE >>.end_keys
    CMP D[gPrevMouseDown], 0
    JNE >>.end_keys
.enter_play:
    MOV D[gState], STATE_PLAYING
    JMP >>.end_keys

; --- GAME OVER / VICTORY ---
.st_endscreen:
    CMP R12D, 1
    JNE >.end_click
    CMP D[gPrevSpace], 0
    JE >.restart_from_end
.end_click:
    CMP EBX, 1
    JNE >>.end_keys
    CMP D[gPrevMouseDown], 0
    JNE >>.end_keys
.restart_from_end:
    INVOKE StartNewGame, 0
    JMP >>.end_keys

; --- PLAYING ---
.st_playing:
    ; Powerup timer decay
    CMP D[gWideTimer], 0
    JLE >.w_off
    DEC D[gWideTimer]
    JMP >.w_done
.w_off:
    MOVSD XMM0, [gPadBaseW]
    MOVSD [gPadTargetW], XMM0
.w_done:
    CMP D[gFireTimer], 0
    JLE >.f_done
    DEC D[gFireTimer]
.f_done:
    CMP D[gLaserTimer], 0
    JLE >.l_done
    DEC D[gLaserTimer]
.l_done:
    CMP D[gSlowTimer], 0
    JLE >.s_done
    DEC D[gSlowTimer]
.s_done:
    CMP D[gShieldTimer], 0
    JLE >.sh_done
    DEC D[gShieldTimer]
.sh_done:
    CMP D[gLaserCd], 0
    JLE >.cd_done
    DEC D[gLaserCd]
.cd_done:
    CMP D[gPadInvuln], 0
    JLE >.inv_done
    DEC D[gPadInvuln]
.inv_done:
    CMP D[gPadStunTimer], 0
    JLE >.stun_done
    DEC D[gPadStunTimer]
.stun_done:

    ; Smooth paddle width lerp: cur += (target - cur) * 0.2
    MOVSD XMM0, [gPadTargetW]
    SUBSD XMM0, [gPadCurW]
    MULSD XMM0, [fPadLerp]
    ADDSD XMM0, [gPadCurW]
    MOVSD [gPadCurW], XMM0

    ; Paddle movement (keyboard or mouse)
    CMP D[gPadStunTimer], 0
    JG >>.skip_pad_move

    XOR ESI, ESI                ; keyMoved flag
    INVOKE IsKeyDown, VK_LEFT
    TEST AX, 8000h
    JNZ >.move_left
    INVOKE IsKeyDown, VK_A
    TEST AX, 8000h
    JZ >.chk_right
.move_left:
    MOVSD XMM0, [gPadX]
    SUBSD XMM0, [fPadKeySpeed]
    MOVSD [gPadX], XMM0
    MOV ESI, 1
    MOV D[gUseMouse], 0
.chk_right:
    INVOKE IsKeyDown, VK_RIGHT
    TEST AX, 8000h
    JNZ >.move_right
    INVOKE IsKeyDown, VK_D
    TEST AX, 8000h
    JZ >.chk_mouse_pad
.move_right:
    MOVSD XMM0, [gPadX]
    ADDSD XMM0, [fPadKeySpeed]
    MOVSD [gPadX], XMM0
    MOV ESI, 1
    MOV D[gUseMouse], 0

.chk_mouse_pad:
    CMP D[gUseMouse], 0
    JE >.clamp_paddle
    CVTSI2SD XMM0, D[gMouseX]
    MOVSD [gPadX], XMM0

.clamp_paddle:
    MOVSD XMM1, [gPadCurW]
    MULSD XMM1, [fHalf]
    MOVSD XMM2, [fArenaLeft]
    ADDSD XMM2, XMM1
    MOVSD XMM0, [gPadX]
    UCOMISD XMM0, XMM2
    JAE >.chk_pad_rmax
    MOVSD [gPadX], XMM2
    JMP >.skip_pad_move
.chk_pad_rmax:
    MOVSD XMM3, [fArenaRight]
    SUBSD XMM3, XMM1
    UCOMISD XMM0, XMM3
    JBE >.skip_pad_move
    MOVSD [gPadX], XMM3
.skip_pad_move:

    ; Launch ball or fire laser on Space or LClick
    CMP R12D, 1
    JE >.act_trigger
    CMP EBX, 1
    JNE >.no_action
.act_trigger:
    ; Launch stuck balls on edge (or hold)
    CALL LaunchStuckBalls
    CALL FirePlayerLasers
.no_action:

    ; Simulate world
    CALL UpdateBricks
    CALL UpdateBoss
    CALL UpdateProjectilesAndDrops
    CMP D[gState], STATE_PLAYING
    JNE >>.end_keys

    ; Step all balls
    XOR ESI, ESI
.ball_loop:
    CMP ESI, MAX_BALLS
    JGE >.balls_done
    INVOKE StepSingleBall, ESI
    INC ESI
    JMP <.ball_loop
.balls_done:

    ; Count remaining active balls
    LEA RSI, [gBalls]
    XOR ECX, ECX
    XOR EDX, EDX
.cnt_balls:
    CMP ECX, MAX_BALLS
    JGE >.chk_ball_loss
    CMP D[RSI + BALL.active], 0
    JE >.nb
    INC EDX
.nb:
    ADD RSI, SIZEOF BALL
    INC ECX
    JMP <.cnt_balls

.chk_ball_loss:
    TEST EDX, EDX
    JNZ >>.chk_level_clear

    ; Lost all balls!
    DEC D[gLives]
    MOV D[gCombo], 0
    MOV D[gWideTimer], 0
    MOV D[gFireTimer], 0
    MOV D[gLaserTimer], 0
    MOV D[gSlowTimer], 0
    MOV D[gShieldTimer], 0
    MOVSD XMM0, [gPadBaseW]
    MOVSD [gPadTargetW], XMM0
    INVOKE PlaySfx, SFX_LOSE

    CMP D[gLives], 0
    JG >.respawn_ball
    MOV D[gState], STATE_GAME_OVER
    JMP >>.end_keys

.respawn_ball:
    CALL ResetBallOnPaddle
    JMP >>.end_keys

.chk_level_clear:
    CMP D[gBricksLeft], 0
    JG >>.end_keys
    CMP D[gHasBoss], 0
    JE >.advance_lvl
    CMP D[gBoss + BOSS.active], 0
    JG >>.end_keys

.advance_lvl:
    INVOKE AddScore, 500
    INVOKE PlaySfx, SFX_LEVELUP
    MOV EAX, [gLevel]
    INC EAX
    CMP EAX, MAX_LEVELS
    JGE >.won_game
    INVOKE LoadLevel, EAX
    JMP >.end_keys

.won_game:
    MOV D[gState], STATE_VICTORY

.end_keys:
    MOV [gPrevSpace], R12D
    MOV [gPrevMouseDown], EBX
    RET
ENDF
