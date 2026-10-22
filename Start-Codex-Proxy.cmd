@echo off
setlocal
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Codex-Proxy.ps1"
set "launchResult=%errorlevel%"
echo.
pause
exit /b %launchResult%
