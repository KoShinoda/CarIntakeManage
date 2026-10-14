@echo off
for %%f in ("%~dp0*.ps1") do set "SCRIPT=%%~f"
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%SCRIPT%" -Setup
