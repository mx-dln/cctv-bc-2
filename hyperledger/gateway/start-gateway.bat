@echo off
REM ==============================================================================
REM CCTV Hyperledger Fabric Gateway Launcher (Windows Batch)
REM ==============================================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-gateway.ps1"
pause
