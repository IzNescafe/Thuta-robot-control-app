@echo off
title Thuta AI - Flutter Laptop Preview
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_laptop.ps1"
set "THUTA_EXIT=%ERRORLEVEL%"
if not "%THUTA_EXIT%"=="0" (
  echo.
  echo Thuta AI could not start. Error code: %THUTA_EXIT%
  echo Keep this window open and share the error shown above.
  pause
)
exit /b %THUTA_EXIT%
