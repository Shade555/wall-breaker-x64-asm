@echo off
setlocal enabledelayedexpansion

set "GOASM="
set "GOLINK="
where goasm.exe >nul 2>nul
if %errorlevel%==0 (
    set "GOASM=goasm.exe"
    set "GOLINK=golink.exe"
) else (
    if exist "C:\Users\slevi\Downloads\ECGo\GoAsm\Bin\GoAsm.exe" (
        set "GOASM=C:\Users\slevi\Downloads\ECGo\GoAsm\Bin\GoAsm.exe"
        set "GOLINK=C:\Users\slevi\Downloads\ECGo\GoAsm\Bin\GoLink.exe"
    ) else (
        echo Error: GoAsm.exe not found in PATH or C:\Users\slevi\Downloads\ECGo\GoAsm\Bin
        exit /b 1
    )
)

set "OBJDIR=%~dp0obj"
if not exist "%OBJDIR%" mkdir "%OBJDIR%"

set "MODULES=state audio levels physics_core physics_ball physics_world render main"
set "OBJS="

pushd "%~dp0src"
for %%M in (%MODULES%) do (
    "%GOASM%" /x64 /fo "%OBJDIR%\%%M.obj" %%M.asm
    if !errorlevel! neq 0 (
        popd
        echo Assembly failed on %%M.asm!
        exit /b 1
    )
    set "OBJS=!OBJS! "%OBJDIR%\%%M.obj""
)
popd

"%GOLINK%" /entry START /fo "%~dp0wall_breaker.exe" %OBJS% kernel32.dll user32.dll gdi32.dll winmm.dll
if %errorlevel% neq 0 (
    echo Linking failed!
    exit /b 1
)

rmdir /s /q "%OBJDIR%" >nul 2>nul
echo Build succeeded: "%~dp0wall_breaker.exe"
exit /b 0
