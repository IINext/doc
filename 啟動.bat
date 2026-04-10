@echo off
cd /d "%~dp0"

python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found.
    pause
    exit /b 1
)

echo Installing packages...
pip install -r requirements.txt -q

rem Find cloudflared.exe
set CLOUDFLARED=
if exist "%~dp0cloudflared.exe" set CLOUDFLARED=%~dp0cloudflared.exe
if "%CLOUDFLARED%"=="" (
    if exist "%~dp0..\即時通\cloudflared.exe" set CLOUDFLARED=%~dp0..\即時通\cloudflared.exe
)

rem Start Cloudflare Tunnel
if not "%CLOUDFLARED%"=="" (
    if exist "%~dp0tunnel-config.yml" (
        findstr /c:"<TUNNEL_ID>" "%~dp0tunnel-config.yml" >nul 2>&1
        if errorlevel 1 (
            echo Starting Cloudflare Tunnel...
            start "CF Tunnel" "%CLOUDFLARED%" tunnel --config "%~dp0tunnel-config.yml" run
            timeout /t 3 >nul
        ) else (
            echo [WARNING] Run cloudflare-tunnel-init.bat first.
        )
    )
)

echo.
echo ================================================
echo  Document Management System
echo  [LAN]      http://127.0.0.1:5100
echo  [Internet] https://doc.mobime.tw
echo  Ctrl+C to stop
echo ================================================
echo.

python app.py
pause
