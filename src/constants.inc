; =============================================================================
; constants.inc - Win64 API Definitions, Game Constants & Structures (GoAsm x64)
; =============================================================================

; --- Win32 Window & Message Constants ---
#define CS_VREDRAW          0001h
#define CS_HREDRAW          0002h
#define CS_OWNDC            0020h

#define WS_OVERLAPPED       00000000h
#define WS_CAPTION          00C00000h
#define WS_SYSMENU          00080000h
#define WS_THICKFRAME       00040000h
#define WS_MINIMIZEBOX      00020000h
#define WS_MAXIMIZEBOX      00010000h
#define WS_VISIBLE          10000000h
#define WS_OVERLAPPEDWINDOW 00CF0000h

#define CW_USEDEFAULT       80000000h
#define SW_SHOWNORMAL       1
#define SPI_GETWORKAREA     48

#define WM_CREATE           0001h
#define WM_DESTROY          0002h
#define WM_SIZE             0005h
#define WM_SETFOCUS         0007h
#define WM_KILLFOCUS        0008h
#define WM_PAINT            000Fh
#define WM_CLOSE            0010h
#define WM_QUIT             0012h
#define WM_ERASEBKGND       0014h
#define WM_KEYDOWN          0100h
#define WM_KEYUP            0101h
#define WM_MOUSEMOVE        0200h
#define WM_LBUTTONDOWN      0201h
#define WM_LBUTTONUP        0202h

#define PM_REMOVE           0001h
#define IDC_ARROW           32512
#define IDI_APPLICATION     32512
#define DIB_RGB_COLORS      0
#define SRCCOPY             00CC0020h
#define BI_RGB              0
#define COLORONCOLOR        3

; Virtual Key Codes
#define VK_RETURN           0Dh
#define VK_ESCAPE           1Bh
#define VK_SPACE            20h
#define VK_LEFT             25h
#define VK_UP               26h
#define VK_RIGHT            27h
#define VK_DOWN             28h
#define VK_A                41h
#define VK_D                44h
#define VK_M                4Dh
#define VK_N                4Eh
#define VK_P                50h
#define VK_R                52h
#define VK_1                31h
#define VK_8                38h
#define VK_LBUTTON          01h

; Sound Flags (winmm PlaySoundA)
#define SND_ASYNC           0001h
#define SND_NODEFAULT       0002h
#define SND_MEMORY          0004h
#define SND_PLAY_FLAGS      0007h

; VirtualAlloc
#define MEM_COMMIT          1000h
#define MEM_RESERVE         2000h
#define PAGE_READWRITE      04h

; --- Logical Framebuffer & Arena Dimensions ---
#define SCREEN_W            960
#define SCREEN_H            720
#define SCREEN_PIXELS       691200

#define HUD_H               76
#define LEGEND_Y            684

#define ARENA_LEFT          24
#define ARENA_RIGHT         936
#define ARENA_TOP           82
#define ARENA_BOTTOM        682
#define ARENA_W             912

#define PADDLE_Y            648
#define PADDLE_H            16
#define BALL_RADIUS         7
#define BALL_DIAM           14

#define GRID_COLS           12
#define GRID_ROWS           10
#define MAX_BRICKS          120
#define BRICK_W             68
#define BRICK_H             24
#define GRID_X0             50
#define GRID_Y0             114
#define GRID_DX             72
#define GRID_DY             28

; --- Array Capacities ---
#define MAX_BALLS           8
#define MAX_POWERUPS        16
#define MAX_LASERS          24
#define MAX_HAZARDS         16
#define MAX_PORTALS         4
#define MAX_BUMPERS         4
#define MAX_PARTICLES       180
#define MAX_POPUPS          12
#define MAX_LEVELS          8

; --- Game States ---
#define STATE_TITLE         0
#define STATE_LEVEL_INTRO   1
#define STATE_PLAYING       2
#define STATE_PAUSED        3
#define STATE_GAME_OVER     4
#define STATE_VICTORY       5

; --- Brick Types ---
#define BRICK_NORMAL        0
#define BRICK_STEEL         1
#define BRICK_MOVING        2
#define BRICK_REGEN         3
#define BRICK_EXPLOSIVE     4
#define HP_STEEL            255

; --- Powerup Types ---
#define PWR_NONE            0
#define PWR_WIDE            1
#define PWR_MULTI           2
#define PWR_FIRE            3
#define PWR_LASER           4
#define PWR_SLOW            5
#define PWR_LIFE            6
#define PWR_SHIELD          7

; --- Sound Effect IDs ---
#define SFX_PADDLE          0
#define SFX_BRICK           1
#define SFX_STEEL           2
#define SFX_BREAK           3
#define SFX_POWERUP         4
#define SFX_LASER           5
#define SFX_EXPLODE         6
#define SFX_LOSE            7
#define SFX_LEVELUP         8

; --- Color Palette (00RRGGBB for 32-bit DIB) ---
#define COL_BG_TOP          000A0E1Ah
#define COL_BG_BOT          00141B30h
#define COL_HUD_BG          000E1324h
#define COL_HUD_LINE        00263A66h
#define COL_WALL_EDGE       002B3D63h
#define COL_WALL_GLOW       00446AB3h
#define COL_WHITE           00FFFFFFh
#define COL_BLACK           00000000h
#define COL_TEXT_DIM        008FA3C7h
#define COL_CYAN            0000E5FFh
#define COL_GOLD            00FFC820h
#define COL_ORANGE          00FF6B1Ah
#define COL_RED             00EF233Ch
#define COL_GREEN           0028E66Bh
#define COL_VIOLET          00A435FFh
#define COL_MAGENTA         00FF33CCh
#define COL_YELLOW          00FFE600h
#define COL_SKY             004DA6FFh
#define COL_STEEL           00788596h
#define COL_STEEL_HI        00C4D0E0h
#define COL_STEEL_LO        0038414Dh

; =============================================================================
; Win32 Structures (x64 Aligned)
; =============================================================================
RECT STRUCT
    left    DD 0
    top     DD 0
    right   DD 0
    bottom  DD 0
ENDS

POINT STRUCT
    x       DD 0
    y       DD 0
ENDS

PAINTSTRUCT STRUCT
    hdc         DQ 0
    fErase      DD 0
    rcPaint     RECT
    fRestore    DD 0
    fIncUpdate  DD 0
    rgbReserved DB 32 DUP 0
    pad         DD 0
ENDS

MSGSTRUCT STRUCT
    hwnd    DQ 0
    message DD 0
    pad1    DD 0
    wParam  DQ 0
    lParam  DQ 0
    time    DD 0
    pt      POINT
    pad2    DD 0
ENDS

WNDCLASSEXA STRUCT
    cbSize        DD 0
    style         DD 0
    lpfnWndProc   DQ 0
    cbClsExtra    DD 0
    cbWndExtra    DD 0
    hInstance     DQ 0
    hIcon         DQ 0
    hCursor       DQ 0
    hbrBackground DQ 0
    lpszMenuName  DQ 0
    lpszClassName DQ 0
    hIconSm       DQ 0
ENDS

BITMAPINFOHEADER STRUCT
    biSize          DD 0
    biWidth         DD 0
    biHeight        DD 0
    biPlanes        DW 0
    biBitCount      DW 0
    biCompression   DD 0
    biSizeImage     DD 0
    biXPelsPerMeter DD 0
    biYPelsPerMeter DD 0
    biClrUsed       DD 0
    biClrImportant  DD 0
ENDS

; =============================================================================
; Game Entity Structures (All 8-byte aligned sizes)
; =============================================================================
BALL STRUCT
    x        DQ 0.0
    y        DQ 0.0
    vx       DQ 0.0
    vy       DQ 0.0
    speed    DQ 0.0
    active   DD 0
    stuck    DD 0
    stuckDx  DQ 0.0
    portalCd DD 0
    bumperCd DD 0
    trailX   DD 0,0,0,0,0,0
    trailY   DD 0,0,0,0,0,0
ENDS

BRICK STRUCT
    x         DQ 0.0
    y         DQ 0.0
    vx        DQ 0.0
    minX      DQ 0.0
    maxX      DQ 0.0
    w         DD 0
    h         DD 0
    active    DD 0
    hp        DD 0
    maxHp     DD 0
    btype     DD 0
    flash     DD 0
    regenTick DD 0
ENDS

POWERUP STRUCT
    x      DQ 0.0
    y      DQ 0.0
    vy     DQ 0.0
    active DD 0
    ptype  DD 0
ENDS

BOLT STRUCT
    x      DQ 0.0
    y      DQ 0.0
    vx     DQ 0.0
    vy     DQ 0.0
    active DD 0
    pad    DD 0
ENDS

PORTAL STRUCT
    x       DQ 0.0
    y       DQ 0.0
    radius  DQ 0.0
    active  DD 0
    pairIdx DD 0
    color   DD 0
    flash   DD 0
ENDS

BUMPER STRUCT
    x      DQ 0.0
    y      DQ 0.0
    radius DQ 0.0
    active DD 0
    flash  DD 0
ENDS

PARTICLE STRUCT
    x       DQ 0.0
    y       DQ 0.0
    vx      DQ 0.0
    vy      DQ 0.0
    active  DD 0
    life    DD 0
    maxLife DD 0
    color   DD 0
    size    DD 0
    pad     DD 0
ENDS

POPUP STRUCT
    x      DD 0
    y      DD 0
    active DD 0
    life   DD 0
    color  DD 0
    pad    DD 0
    text   DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
ENDS

BOSS STRUCT
    x         DQ 0.0
    y         DQ 0.0
    vx        DQ 0.0
    w         DD 0
    h         DD 0
    active    DD 0
    hp        DD 0
    maxHp     DD 0
    fireTimer DD 0
    flash     DD 0
    invuln    DD 0
    pad       DD 0
ENDS
