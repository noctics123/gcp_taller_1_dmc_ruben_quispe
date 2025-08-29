@echo off
setlocal
set SCRIPT=%~dp0run_deploy.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
exit /b %ERRORLEVEL%

