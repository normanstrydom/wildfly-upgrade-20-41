@echo off
setlocal
echo Building sample applications...
powershell -ExecutionPolicy Bypass -File "%~dp0build-apps.ps1"
endlocal
