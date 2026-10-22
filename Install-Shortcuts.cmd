@echo off
setlocal
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-Shortcuts.ps1"
set "installResult=%errorlevel%"
echo.
pause
exit /b %installResult%
