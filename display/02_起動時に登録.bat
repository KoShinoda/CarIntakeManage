@echo off
rem To pin the monitor, set its number (e.g. set MONITOR=1). Empty = portrait monitor, else primary.
set MONITOR=

for %%f in ("%~dp0*.ps1") do set "SCRIPT=%%~f"
if "%MONITOR%"=="" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Install
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Install -Monitor %MONITOR%
)
echo.
timeout /t 30
