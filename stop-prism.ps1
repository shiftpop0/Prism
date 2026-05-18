param(
  [string]$ConfigPath = ".\config\prism-config.json",
  [int]$BackendPort = 8081,
  [int]$FrontendPort = 5173
)

$ErrorActionPreference = "Continue"

function Write-Info([string]$msg) {
  Write-Host "[INFO] $msg" -ForegroundColor Cyan
}

function Resolve-PortFromAddr([string]$addr, [int]$fallback) {
  if ([string]::IsNullOrWhiteSpace($addr)) { return $fallback }
  $port = ($addr -replace "^.*:", "")
  if ($port -match "^\d+$") { return [int]$port }
  return $fallback
}

function Stop-IfRunning([int]$procId) {
  try {
    $p = Get-Process -Id $procId -ErrorAction Stop
    Stop-Process -Id $p.Id -Force
    Write-Info "stopped pid=$procId"
  } catch {}
}

function Stop-ByPort([int]$port) {
  try {
    $items = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue
    if ($items) {
      $pids = $items | Select-Object -ExpandProperty OwningProcess -Unique
      foreach ($portProcId in $pids) {
        Stop-IfRunning ([int]$portProcId)
      }
    }
  } catch {}
}

try {
  $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  $resolvedConfigPath = if ([System.IO.Path]::IsPathRooted($ConfigPath)) { $ConfigPath } else { Join-Path $scriptRoot $ConfigPath }
  if (Test-Path $resolvedConfigPath) {
    $cfg = Get-Content -Path $resolvedConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $PSBoundParameters.ContainsKey('BackendPort') -and $cfg.backend.server_addr) {
      $BackendPort = Resolve-PortFromAddr ([string]$cfg.backend.server_addr) $BackendPort
    }
    if (-not $PSBoundParameters.ContainsKey('FrontendPort') -and $cfg.frontend.port) {
      $FrontendPort = [int]$cfg.frontend.port
    }
  }

  Stop-ByPort $FrontendPort
  Stop-ByPort $BackendPort

  Write-Info "Prism stop routine completed (frontend=$FrontendPort backend=$BackendPort)."
} catch {
  Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}

