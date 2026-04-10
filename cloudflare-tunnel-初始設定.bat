@echo off
cd /d "%~dp0"

echo ================================================
echo  Cloudflare Tunnel Setup  (run once only)
echo ================================================
echo.

rem Find cloudflared.exe
set CLOUDFLARED=
if exist "%~dp0cloudflared.exe" set CLOUDFLARED=%~dp0cloudflared.exe
if "%CLOUDFLARED%"=="" (
    if exist "%~dp0..\即時通\cloudflared.exe" set CLOUDFLARED=%~dp0..\即時通\cloudflared.exe
)
if "%CLOUDFLARED%"=="" (
    echo [ERROR] cloudflared.exe not found.
    echo Please download from:
    echo   https://github.com/cloudflare/cloudflared/releases
    echo Place cloudflared.exe in this folder and retry.
    pause
    exit /b 1
)
echo Using: %CLOUDFLARED%
echo.

echo Step 1: Login to Cloudflare
echo   Browser will open, login then press any key here...
echo.
pause
"%CLOUDFLARED%" tunnel login
if errorlevel 1 (
    echo [ERROR] Login failed.
    pause
    exit /b 1
)
echo.

echo Step 2: Create tunnel  doc-server
"%CLOUDFLARED%" tunnel create doc-server
if errorlevel 1 (
    echo [ERROR] Failed to create tunnel.
    pause
    exit /b 1
)
echo.

echo Step 3: Route DNS  doc.mobime.tw
"%CLOUDFLARED%" tunnel route dns doc-server doc.mobime.tw
if errorlevel 1 (
    echo [WARNING] Auto DNS routing failed.
    echo Please add CNAME at Cloudflare Dashboard:
    echo   Name:  doc
    echo   Value: ^<tunnel-uuid^>.cfargotunnel.com
    pause
)
echo.

echo Step 4: Update tunnel-config.yml
for /f "tokens=1" %%i in ('"%CLOUDFLARED%" tunnel list 2^>nul ^| findstr /i "doc-server"') do set TUNNEL_ID=%%i
if "%TUNNEL_ID%"=="" (
    echo [WARNING] Could not auto-detect Tunnel ID.
    echo Run:  cloudflared tunnel list
    echo Copy the ID and update tunnel-config.yml manually.
) else (
    echo Tunnel ID: %TUNNEL_ID%
    powershell -Command "(Get-Content 'tunnel-config.yml') -replace '<TUNNEL_ID>', '%TUNNEL_ID%' | Set-Content 'tunnel-config.yml'"
    echo tunnel-config.yml updated.
)
echo.

echo ================================================
echo  Setup complete!
echo  Run start.bat to start the server.
echo  External URL: https://doc.mobime.tw
echo ================================================
pause
