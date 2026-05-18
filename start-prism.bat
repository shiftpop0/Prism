@echo off
setlocal
powershell -ExecutionPolicy Bypass -File "%~dp0start-prism.ps1"
if errorlevel 1 (
  echo.
  echo [ERROR] 启动失败，请查看上方日志。
  pause
)
