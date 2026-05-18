param(
  [string]$ConfigPath = ".\config\prism-config.json",
  [string]$BackendServerAddr = "",
  [int]$FrontendPort = 0
)

$ErrorActionPreference = "Continue"

function Resolve-PortFromAddr([string]$addr, [int]$fallback) {
  if ([string]::IsNullOrWhiteSpace($addr)) { return $fallback }
  $port = ($addr -replace "^.*:", "")
  if ($port -match "^\d+$") { return [int]$port }
  return $fallback
}

function Stop-IfRunning([int]$pid) {
  try {
    $p = Get-Process -Id $pid -ErrorAction Stop
    Stop-Process -Id $p.Id -Force
    Write-Host "[INFO] stopped pid=$pid"
  } catch {}
}

function Stop-ByPort([int]$port) {
  try {
    $items = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue
    if ($items) {
      $pids = $items | Select-Object -ExpandProperty OwningProcess -Unique
      foreach ($pid in $pids) { Stop-IfRunning ([int]$pid) }
    }
  } catch {}
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$runDir = Join-Path $root "run"

$resolvedConfig = if ([System.IO.Path]::IsPathRooted($ConfigPath)) { $ConfigPath } else { Join-Path $root $ConfigPath }
$cfg = $null
if (Test-Path $resolvedConfig) {
  $cfg = Get-Content -Path $resolvedConfig -Raw -Encoding UTF8 | ConvertFrom-Json
}
$backendAddr = if ($BackendServerAddr -ne "") { $BackendServerAddr } elseif ($cfg -and $cfg.backend.server_addr) { [string]$cfg.backend.server_addr } else { ":8081" }
$backendPort = Resolve-PortFromAddr $backendAddr 8081
$frontendPortFinal = if ($FrontendPort -gt 0) { $FrontendPort } elseif ($cfg -and $cfg.frontend.port) { [int]$cfg.frontend.port } else { 5173 }

$backendPidFile = Join-Path $runDir "backend.pid"
$frontendPidFile = Join-Path $runDir "frontend.pid"
if (Test-Path $backendPidFile) {
  $procIdValue = [int](Get-Content $backendPidFile -Raw)
  Stop-IfRunning $procIdValue
  Remove-Item $backendPidFile -Force -ErrorAction SilentlyContinue
}
if (Test-Path $frontendPidFile) {
  $procIdValue = [int](Get-Content $frontendPidFile -Raw)
  Stop-IfRunning $procIdValue
  Remove-Item $frontendPidFile -Force -ErrorAction SilentlyContinue
}

# Fallback by listening ports.
Stop-ByPort $frontendPortFinal
Stop-ByPort $backendPort

Write-Host "[INFO] Prism stop routine completed." -ForegroundColor Green
