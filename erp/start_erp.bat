@echo off
cd /d "%~dp0.."

python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found.
    pause
    exit /b 1
)

if not exist "%~dp0erp.env.bat" (
    echo [ERROR] erp\erp.env.bat not found. Copy erp\erp.env.example.bat to erp\erp.env.bat and edit it.
    pause
    exit /b 1
)
call "%~dp0erp.env.bat"

echo Installing packages...
pip install -r erp\requirements.txt -q

echo.
echo ================================================
echo  ERP
echo  http://127.0.0.1:%ERP_PORT%
echo  Ctrl+C to stop
echo ================================================
python -m erp.serve
pause
