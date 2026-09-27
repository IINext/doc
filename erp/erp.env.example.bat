@echo off
rem Copy this file to erp.env.bat and fill in the values. erp.env.bat is not committed to git.
set ERP_DATABASE_URL=postgresql://erp:CHANGE_ME@localhost:5432/erp
rem Generate once with: python -c "import secrets; print(secrets.token_hex(32))"
set ERP_SECRET_KEY=CHANGE_ME
set ERP_SIGNING_APP_NAME=Home
set ERP_PORT=8100
