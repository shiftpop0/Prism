param(
  [string]$ConfigPath = ".\config\prism-config.json",
  [string]$BackendServerAddr = "",
  [int]$FrontendPort = 0
)

$ErrorActionPreference = "Stop"

function Resolve-PortFromAddr([string]$addr, [int]$fallback) {
  if ([string]::IsNullOrWhiteSpace($addr)) { return $fallback }
  $port = ($addr -replace "^.*:", "")
  if ($port -match "^\d+$") { return [int]$port }
  return $fallback
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$runDir = Join-Path $root "run"
New-Item -ItemType Directory -Path $runDir -Force | Out-Null

$resolvedConfig = if ([System.IO.Path]::IsPathRooted($ConfigPath)) { $ConfigPath } else { Join-Path $root $ConfigPath }
if (-not (Test-Path $resolvedConfig)) { throw "config not found: $resolvedConfig" }

$cfg = Get-Content -Path $resolvedConfig -Raw -Encoding UTF8 | ConvertFrom-Json
$backendAddr = if ($BackendServerAddr -ne "") { $BackendServerAddr } elseif ($cfg.backend.server_addr) { [string]$cfg.backend.server_addr } else { ":8081" }
$backendPort = Resolve-PortFromAddr $backendAddr 8081
$frontendPortFinal = if ($FrontendPort -gt 0) { $FrontendPort } elseif ($cfg.frontend.port) { [int]$cfg.frontend.port } else { 5173 }

$backendExe = Join-Path $root "backend\server.exe"
$frontendServer = Join-Path $root "frontend\server.js"
if (-not (Test-Path $backendExe)) { throw "backend executable not found: $backendExe" }
if (-not (Test-Path $frontendServer)) { throw "frontend server not found: $frontendServer" }

$portableNodeExe = Get-ChildItem -Path (Join-Path $root "runtime\node-portable") -Recurse -Filter node.exe -ErrorAction SilentlyContinue | Select-Object -First 1
$nodeCmd = if ($portableNodeExe) { $portableNodeExe.FullName } else { "node" }

$backendCmd = "`$env:PRISM_CONFIG_PATH='$resolvedConfig'; `$env:SERVER_ADDR='$backendAddr'; `$env:PRISM_STATIC_DIR=''; & '$backendExe'"
$backendProc = Start-Process powershell -ArgumentList @("-ExecutionPolicy","Bypass","-Command",$backendCmd) -PassThru -WindowStyle Hidden
$backendProc.Id | Set-Content -Path (Join-Path $runDir "backend.pid") -Encoding ASCII

$frontendCmd = "`$env:PRISM_FRONTEND_DIST='" + (Join-Path $root "frontend\dist") + "'; `$env:BACKEND_TARGET='http://127.0.0.1:$backendPort'; `$env:FRONTEND_HOST='127.0.0.1'; `$env:FRONTEND_PORT='$frontendPortFinal'; & '$nodeCmd' '$frontendServer'"
$frontendProc = Start-Process powershell -ArgumentList @("-ExecutionPolicy","Bypass","-Command",$frontendCmd) -PassThru -WindowStyle Hidden
$frontendProc.Id | Set-Content -Path (Join-Path $runDir "frontend.pid") -Encoding ASCII

Write-Host "[INFO] Prism started in background" -ForegroundColor Green
Write-Host "[INFO] frontend: http://127.0.0.1:$frontendPortFinal" -ForegroundColor Green
Write-Host "[INFO] backend : http://127.0.0.1:$backendPort" -ForegroundColor Green
Write-Host "[INFO] run stop script to shutdown: .\stop-offline.ps1" -ForegroundColor Yellow
