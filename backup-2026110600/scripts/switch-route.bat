@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0switch-route.ps1" %*
