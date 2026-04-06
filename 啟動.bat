@echo off
chcp 65001 >nul
cd /d %~dp0
echo Starting document management system...
pip install -r requirements.txt -q
python app.py
pause
