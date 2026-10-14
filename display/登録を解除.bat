@echo off
for %%f in ("%~dp0*.ps1") do set "SCRIPT=%%~f"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Remove
echo.
timeout /t 10
