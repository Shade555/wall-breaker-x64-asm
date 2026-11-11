; =============================================================================
; state.asm - Global Constants, Tables, Bitmap Font & Game State (GoAsm x64)
; =============================================================================

#include constants.inc

CONST SECTION

szClassName     DB 'WallBreakerGoAsmClass',0
szWindowTitle   DB 'WALL BREAKER // X64 GOASM EDITION',0

; --- Floating Point Constants (16-byte aligned) ---
ALIGN 16
fZero           DQ 0.0
fHalf           DQ 0.5
fOne            DQ 1.0
fMinusOne       DQ -1.0
fTwo            DQ 2.0
fThree          DQ 3.0
fFour           DQ 4.0
fSubStepInv     DQ 0.25
fBallRadius     DQ 7.0
fPadY           DQ 648.0
fPadH           DQ 16.0
fPadTopY        DQ 648.0
fArenaLeft      DQ 24.0
fArenaRight     DQ 936.0
fArenaTop       DQ 82.0
fArenaBottom    DQ 682.0
fShieldY        DQ 676.0
fMinVyRatio     DQ 0.36
fMaxVxRatio     DQ 0.92
fPadAngleMax    DQ 0.88
fSlowScale      DQ 0.72
fWideScale      DQ 1.55
fPadLerp        DQ 0.20
fPadKeySpeed    DQ 10.5
fPwrDropVy      DQ 2.35
fPwrW           DQ 32.0
fPwrH           DQ 16.0
fLaserVy        DQ -11.5
fHazardVy       DQ 4.2
fGravityCx      DQ 480.0
fGravityCy      DQ 390.0
fGravityRadSq   DQ 19600.0
fGravityPullY   DQ 0.032
fGravitySwirl   DQ 0.018
fBumperBoost    DQ 1.05
fMaxBallSpeed   DQ 11.8
fBlastRadSq     DQ 11664.0
fPortalExitOff  DQ 26.0
fBrickMinV      DQ 1.0
fBrickMaxV      DQ 2.6
fBossMinX       DQ 48.0
fBossMaxX       DQ 772.0
fBossSpeed      DQ 2.4
fBossHalfW      DQ 70.0
fBossH          DQ 40.0
fNegOnePoint2   DQ -1.2
fZeroPoint95    DQ 0.95
fZeroPoint92    DQ 0.92
fZeroPoint85    DQ 0.85

; --- Wall Color Tables Indexed by Remaining HP (0..5) ---
; HP=1: Emerald Green, HP=2: Amber Gold, HP=3: Tangerine Orange, HP=4: Crimson Red, HP=5+: Royal Violet
ALIGN 4
gHpMainColors   DD 00202020h, 0028E66Bh, 00FFC420h, 00FF6B1Ah, 00EB223Dh, 00A435FFh
gHpLightColors  DD 00404040h, 0085FFB0h, 00FFE885h, 00FFB078h, 00FF8093h, 00D699FFh
gHpDarkColors   DD 00101010h, 00127D38h, 00996B00h, 00963100h, 00870B1Ch, 00521099h

; --- Powerup Tables Indexed by ptype (0..7) ---
gPwrColors      DD 00888888h, 0000E5FFh, 00FF33CCh, 00FF5500h, 00FFE600h, 004DA6FFh, 002EE66Bh, 00FFD700h
gPwrLetters     DB '?', 'W', 'M', 'F', 'L', 'S', '+', 'B'

; --- Level Speeds & Paddle Base Widths (8 Levels) ---
ALIGN 8
gLevelSpeeds    DQ 5.2, 5.7, 6.2, 6.6, 7.0, 7.4, 7.8, 8.2
gLevelPadWidths DQ 132.0, 124.0, 118.0, 112.0, 108.0, 104.0, 100.0, 96.0

; --- Level Titles & Gimmick Descriptions (defined before pointer arrays) ---
strLvl1Name     DB 'LEVEL 1: NEON INITIATION',0
strLvl2Name     DB 'LEVEL 2: IRON BASTION',0
strLvl3Name     DB 'LEVEL 3: SHIFTING PHALANX',0
strLvl4Name     DB 'LEVEL 4: WARP MATRIX',0
strLvl5Name     DB 'LEVEL 5: BIO-CORE REACTOR',0
strLvl6Name     DB 'LEVEL 6: PINBALL CITADEL',0
strLvl7Name     DB 'LEVEL 7: SINGULARITY CHAIN',0
strLvl8Name     DB 'LEVEL 8: OVERLORD MONOLITH',0

strLvl1Gim      DB 'GIMMICK: COLOR-CODED MULTI-HIT ARMOR',0
strLvl2Gim      DB 'GIMMICK: INDESTRUCTIBLE STEEL WALLS',0
strLvl3Gim      DB 'GIMMICK: MOVING PATROL BRICKS',0
strLvl4Gim      DB 'GIMMICK: DIMENSIONAL WARP PORTALS',0
strLvl5Gim      DB 'GIMMICK: SELF-HEALING REGEN BRICKS',0
strLvl6Gim      DB 'GIMMICK: PINBALL REPULSOR BUMPERS',0
strLvl7Gim      DB 'GIMMICK: GRAVITY WELL + TNT CHAINS',0
strLvl8Gim      DB 'GIMMICK: BOSS CITADEL + HAZARD LASERS',0

strLvl1Hint     DB 'GREEN=1 HIT  GOLD=2  ORANGE=3  CATCH DROPPED CAPSULES!',0
strLvl2Hint     DB 'CHROME STEEL CANNOT BREAK - BANK SHOTS INTO THE VAULT!',0
strLvl3Hint     DB 'BRICK ROWS SLIDE LEFT AND RIGHT - TIME YOUR SHOTS!',0
strLvl4Hint     DB 'ENTER CYAN PORTAL TO WARP OUT ORANGE PORTAL BEHIND WALLS!',0
strLvl5Hint     DB 'GLOWING + BRICKS REGENERATE HP IF LEFT WOUNDED!',0
strLvl6Hint     DB 'HEX BUMPERS DEFLECT AND BOOST BALL SPEED ON IMPACT!',0
strLvl7Hint     DB 'PURPLE CORE CURVES BALLS - HIT TNT FOR CHAIN BLASTS!',0
strLvl8Hint     DB 'DODGE CRIMSON BOLTS AND SHATTER THE OVERLORD CORE!',0

ALIGN 8
gLevelNames     DQ strLvl1Name, strLvl2Name, strLvl3Name, strLvl4Name
                DQ strLvl5Name, strLvl6Name, strLvl7Name, strLvl8Name
gLevelGimmicks  DQ strLvl1Gim, strLvl2Gim, strLvl3Gim, strLvl4Gim
                DQ strLvl5Gim, strLvl6Gim, strLvl7Gim, strLvl8Gim
gLevelHints     DQ strLvl1Hint, strLvl2Hint, strLvl3Hint, strLvl4Hint
                DQ strLvl5Hint, strLvl6Hint, strLvl7Hint, strLvl8Hint

; --- UI & HUD Strings ---
strScoreLbl     DB 'SCORE',0
strBestLbl      DB 'BEST',0
strLevelLbl     DB 'LVL',0
strLivesLbl     DB 'LIVES',0
strComboLbl     DB 'COMBO',0
strSoundOn      DB 'SFX:ON',0
strSoundOff     DB 'SFX:MUTE',0

strPwrWide      DB 'WIDE',0
strPwrFire      DB 'FIRE',0
strPwrLaser     DB 'LASER',0
strPwrSlow      DB 'SLOW',0
strPwrShield    DB 'SHIELD',0

strLeg1         DB '1:GREEN',0
strLeg2         DB '2:GOLD',0
strLeg3         DB '3:ORANGE',0
strLeg4         DB '4:RED',0
strLeg5         DB '5:VIOLET',0
strLegSteel     DB 'STEEL',0
strLegRegen     DB '+REGEN',0
strLegTnt       DB 'TNT',0
strControlsBar  DB 'MOVE:MOUSE/A-D  FIRE:SPACE  [P]PAUSE [M]MUTE',0

strTitleMain    DB 'WALL BREAKER',0
strTitleSub     DB 'X64 GOASM EDITION // 8 LEVELS & UNIQUE GIMMICKS',0
strTitlePrompt  DB 'PRESS SPACE OR CLICK TO START',0
strTitleSelect  DB 'OR PRESS KEYS [1]-[8] TO JUMP TO ANY LEVEL',0
strTitleCaps    DB 'W:WIDE  M:MULTI  F:FIRE  L:LASER  S:SLOW  +:LIFE  B:SHIELD',0

strPaused       DB 'PAUSED',0
strPausedSub    DB 'PRESS [P] TO RESUME  |  [R] TO RESTART',0
strGameOver     DB 'GAME OVER',0
strGameOverSub  DB 'PRESS [SPACE] OR [R] TO PLAY AGAIN',0
strVictory      DB 'CITADEL CONQUERED!',0
strVictorySub   DB 'YOU CLEARED ALL 8 LEVELS IN PURE X64 ASSEMBLY!',0
strVictorySub2  DB 'PRESS [SPACE] OR [R] TO PLAY AGAIN',0
strGetReady     DB 'PRESS SPACE OR CLICK TO LAUNCH',0
strBossName     DB 'OVERLORD MONOLITH',0
strPopWarp      DB 'WARP!',0
strPopBoom      DB 'BOOM!',0
strPopHeal      DB '+HP!',0
strPopLife      DB '+1 LIFE!',0
strPopWide      DB 'WIDE!',0
strPopMulti     DB 'MULTI x3!',0
strPopFire      DB 'FIREBALL!',0
strPopLaser     DB 'LASERS!',0
strPopSlow      DB 'SLOW!',0
strPopShield    DB 'SHIELD!',0
strPopHit       DB 'HIT!',0

; --- 5x7 Pixel Bitmap Font (ASCII 32..95, 7 bytes per char, bits 4..0) ---
gFont5x7:
    DB 00h,00h,00h,00h,00h,00h,00h ; 32 ' '
    DB 04h,04h,04h,04h,04h,00h,04h ; 33 '!'
    DB 0Ah,0Ah,00h,00h,00h,00h,00h ; 34 '"'
    DB 0Ah,1Fh,0Ah,0Ah,1Fh,0Ah,00h ; 35 '#'
    DB 04h,0Fh,14h,0Eh,05h,1Eh,04h ; 36 '$'
    DB 18h,19h,02h,04h,08h,13h,03h ; 37 '%'
    DB 0Ch,12h,14h,08h,15h,12h,0Dh ; 38 '&'
    DB 04h,04h,00h,00h,00h,00h,00h ; 39 '''
    DB 02h,04h,08h,08h,08h,04h,02h ; 40 '('
    DB 08h,04h,02h,02h,02h,04h,08h ; 41 ')'
    DB 00h,0Ah,04h,1Fh,04h,0Ah,00h ; 42 '*'
    DB 00h,04h,04h,1Fh,04h,04h,00h ; 43 '+'
    DB 00h,00h,00h,00h,04h,04h,08h ; 44 ','
    DB 00h,00h,00h,1Fh,00h,00h,00h ; 45 '-'
    DB 00h,00h,00h,00h,00h,04h,00h ; 46 '.'
    DB 01h,02h,02h,04h,08h,08h,10h ; 47 '/'
    DB 0Eh,11h,13h,15h,19h,11h,0Eh ; 48 '0'
    DB 04h,0Ch,04h,04h,04h,04h,0Eh ; 49 '1'
    DB 0Eh,11h,01h,06h,08h,10h,1Fh ; 50 '2'
    DB 1Eh,01h,01h,0Eh,01h,01h,1Eh ; 51 '3'
    DB 02h,06h,0Ah,12h,1Fh,02h,02h ; 52 '4'
    DB 1Fh,10h,1Eh,01h,01h,11h,0Eh ; 53 '5'
    DB 06h,08h,10h,1Eh,11h,11h,0Eh ; 54 '6'
    DB 1Fh,01h,02h,04h,08h,08h,08h ; 55 '7'
    DB 0Eh,11h,11h,0Eh,11h,11h,0Eh ; 56 '8'
    DB 0Eh,11h,11h,0Fh,01h,02h,0Ch ; 57 '9'
    DB 00h,04h,00h,00h,04h,00h,00h ; 58 ':'
    DB 00h,04h,00h,00h,04h,04h,08h ; 59 ';'
    DB 02h,04h,08h,10h,08h,04h,02h ; 60 '<'
    DB 00h,00h,1Fh,00h,1Fh,00h,00h ; 61 '='
    DB 08h,04h,02h,01h,02h,04h,08h ; 62 '>'
    DB 0Eh,11h,01h,06h,04h,00h,04h ; 63 '?'
    DB 0Eh,11h,17h,15h,17h,10h,0Eh ; 64 '@'
    DB 0Eh,11h,11h,1Fh,11h,11h,11h ; 65 'A'
    DB 1Eh,11h,11h,1Eh,11h,11h,1Eh ; 66 'B'
    DB 0Eh,11h,10h,10h,10h,11h,0Eh ; 67 'C'
    DB 1Eh,11h,11h,11h,11h,11h,1Eh ; 68 'D'
    DB 1Fh,10h,10h,1Eh,10h,10h,1Fh ; 69 'E'
    DB 1Fh,10h,10h,1Eh,10h,10h,10h ; 70 'F'
    DB 0Eh,11h,10h,17h,11h,11h,0Fh ; 71 'G'
    DB 11h,11h,11h,1Fh,11h,11h,11h ; 72 'H'
    DB 0Eh,04h,04h,04h,04h,04h,0Eh ; 73 'I'
    DB 07h,02h,02h,02h,02h,12h,0Ch ; 74 'J'
    DB 11h,12h,14h,18h,14h,12h,11h ; 75 'K'
    DB 10h,10h,10h,10h,10h,10h,1Fh ; 76 'L'
    DB 11h,1Bh,15h,15h,11h,11h,11h ; 77 'M'
    DB 11h,19h,15h,13h,11h,11h,11h ; 78 'N'
    DB 0Eh,11h,11h,11h,11h,11h,0Eh ; 79 'O'
    DB 1Eh,11h,11h,1Eh,10h,10h,10h ; 80 'P'
    DB 0Eh,11h,11h,11h,15h,12h,0Dh ; 81 'Q'
    DB 1Eh,11h,11h,1Eh,14h,12h,11h ; 82 'R'
    DB 0Fh,10h,10h,0Eh,01h,01h,1Eh ; 83 'S'
    DB 1Fh,04h,04h,04h,04h,04h,04h ; 84 'T'
    DB 11h,11h,11h,11h,11h,11h,0Eh ; 85 'U'
    DB 11h,11h,11h,11h,11h,0Ah,04h ; 86 'V'
    DB 11h,11h,11h,15h,15h,1Bh,11h ; 87 'W'
    DB 11h,11h,0Ah,04h,0Ah,11h,11h ; 88 'X'
    DB 11h,11h,0Ah,04h,04h,04h,04h ; 89 'Y'
    DB 1Fh,01h,02h,04h,08h,10h,1Fh ; 90 'Z'
    DB 0Eh,08h,08h,08h,08h,08h,0Eh ; 91 '['
    DB 10h,08h,08h,04h,02h,02h,01h ; 92 '\'
    DB 0Eh,02h,02h,02h,02h,02h,0Eh ; 93 ']'
    DB 04h,0Ah,11h,00h,00h,00h,00h ; 94 '^'
    DB 00h,00h,00h,00h,00h,00h,1Fh ; 95 '_'

; =============================================================================
; Mutable Data & Uninitialized Buffers
; =============================================================================
DATA SECTION

ALIGN 8
; Win32 / Rendering Handles
gHInst          DQ 0
gHwnd           DQ 0
gMemDC          DQ 0
gDIB            DQ 0
gPixels         DQ 0
gBgPixels       DQ 0
gSfxBase        DQ 0
gSfxPtrs        DQ 9 DUP 0

; DIB Bitmap Info
gBmi            BITMAPINFOHEADER

; Win32 Structures
gMsg            MSGSTRUCT
gPs             PAINTSTRUCT
gRcClient       RECT
gRcWork         RECT
gWc             WNDCLASSEXA

; Timing & RNG
ALIGN 8
gFreq           DQ 0
gLastTick       DQ 0
gAccumSec       DQ 0.0
gPrngState      DQ 0123456789ABCDEFh
gFrameCount     DD 0
gClientW        DD SCREEN_W
gClientH        DD SCREEN_H
gRunning        DD 1

; Input State
gMouseX         DD 480
gMouseY         DD 360
gLastMouseX     DD 480
gUseMouse       DD 0
gPrevSpace      DD 0
gPrevPause      DD 0
gPrevRestart    DD 0
gPrevMute       DD 0
gPrevMouseDown  DD 0
gPrevNumKey     DD 0

; Game Flow & Score
gState          DD STATE_TITLE
gLevel          DD 0            ; 0-based (0..7 => Levels 1..8)
gScore          DD 0
gHighScore      DD 0
gLives          DD 3
gCombo          DD 0
gMaxCombo       DD 0
gIntroTimer     DD 0
gMuted          DD 0
gScreenShake    DD 0
gBricksLeft     DD 0
gHasMoving      DD 0
gHasRegen       DD 0
gHasPortals     DD 0
gHasBumpers     DD 0
gGravityActive  DD 0
gHasBoss        DD 0

; Paddle State
ALIGN 8
gPadX           DQ 480.0        ; paddle center X
gPadBaseW       DQ 132.0
gPadCurW        DQ 132.0
gPadTargetW     DQ 132.0
gPadStunTimer   DD 0
gPadInvuln      DD 0
gLaserCd        DD 0

; Powerup Timers (frames remaining @ 60fps)
gWideTimer      DD 0
gFireTimer      DD 0
gLaserTimer     DD 0
gSlowTimer      DD 0
gShieldTimer    DD 0

; Scratch String Buffer
gStrBuf         DB 128 DUP 0
gKeyDown        DB 256 DUP 0

; Entity Arrays
ALIGN 8
gBalls          DB (SIZEOF BALL * MAX_BALLS) DUP 0
gBricks         DB (SIZEOF BRICK * MAX_BRICKS) DUP 0
gPowerups       DB (SIZEOF POWERUP * MAX_POWERUPS) DUP 0
gLasers         DB (SIZEOF BOLT * MAX_LASERS) DUP 0
gHazards        DB (SIZEOF BOLT * MAX_HAZARDS) DUP 0
gPortals        DB (SIZEOF PORTAL * MAX_PORTALS) DUP 0
gBumpers        DB (SIZEOF BUMPER * MAX_BUMPERS) DUP 0
gParticles      DB (SIZEOF PARTICLE * MAX_PARTICLES) DUP 0
gPopups         DB (SIZEOF POPUP * MAX_POPUPS) DUP 0
gBoss           BOSS
