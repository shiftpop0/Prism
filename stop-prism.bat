@echo off
setlocal
powershell -ExecutionPolicy Bypass -File "%~dp0stop-prism.ps1"
if errorlevel 1 (
  echo.
  echo [ERROR] 停止失败，请查看上方日志。
  pause
)

