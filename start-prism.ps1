param(
  [string]$ConfigPath = ".\config\prism-config.json",
  [int]$BackendPort = 8081,
  [int]$FrontendPort = 5173,
  [string]$MysqlHost = "127.0.0.1",
  [int]$MysqlPort = 3306,
  [string]$MysqlDSN = "",
  [string]$DeepseekApiBase = "https://api.deepseek.com/v1",
  [string]$DeepseekModel = "deepseek-chat",
  [string]$DeepseekApiKey = ""
)

$ErrorActionPreference = "Stop"

function Write-Info([string]$msg) {
  Write-Host "[INFO] $msg" -ForegroundColor Cyan
}

function Write-WarnMsg([string]$msg) {
  Write-Host "[WARN] $msg" -ForegroundColor Yellow
}

function Write-Err([string]$msg) {
  Write-Host "[ERROR] $msg" -ForegroundColor Red
}

function Load-JsonConfig([string]$Path) {
  if (-not (Test-Path $Path)) { return $null }
  try {
    return Get-Content -Path $Path -Raw | ConvertFrom-Json
  } catch {
    return $null
  }
}

function Test-TcpPort([string]$HostName, [int]$Port, [int]$TimeoutMs = 1200) {
  $client = New-Object System.Net.Sockets.TcpClient
  try {
    $iar = $client.BeginConnect($HostName, $Port, $null, $null)
    if (-not $iar.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) { return $false }
    $client.EndConnect($iar)
    return $true
  } catch {
    return $false
  } finally {
    $client.Close()
  }
}

function Test-HttpOk([string]$Url, [int]$TimeoutSec = 2) {
  try {
    $resp = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec $TimeoutSec
    return ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 500)
  } catch {
    return $false
  }
}

function Wait-HttpOk([string]$Url, [int]$MaxSeconds = 30) {
  $deadline = (Get-Date).AddSeconds($MaxSeconds)
  while ((Get-Date) -lt $deadline) {
    if (Test-HttpOk -Url $Url -TimeoutSec 2) { return $true }
    Start-Sleep -Milliseconds 700
  }
  return $false
}

function Require-Command([string]$Name, [string]$Hint) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Missing command '$Name'. $Hint"
  }
}

function Get-MySQLDPath {
  $candidates = @(
    "C:\\Program Files\\MySQL\\MySQL Server 8.4\\bin\\mysqld.exe",
    "C:\\Program Files\\MySQL\\MySQL Server 8.0\\bin\\mysqld.exe",
    "C:\\Program Files\\MariaDB 11.0\\bin\\mysqld.exe",
    "C:\\Program Files\\MariaDB 10.11\\bin\\mysqld.exe"
  )

  foreach ($p in $candidates) {
    if (Test-Path $p) { return $p }
  }

  $fromPath = Get-Command mysqld -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($fromPath -and (Test-Path $fromPath.Source)) {
    return $fromPath.Source
  }

  return $null
}

function Ensure-MySQLConfig([string]$MysqldPath) {
  $cfgDir = "C:\\ProgramData\\MySQL\\MySQL Server 8.4"
  if (-not (Test-Path $cfgDir)) {
    New-Item -ItemType Directory -Path $cfgDir -Force | Out-Null
  }

  $cfg = Join-Path $cfgDir "my.ini"
  if (Test-Path $cfg) {
    return $cfg
  }

  $binDir = Split-Path -Parent $MysqldPath
  $baseDir = Split-Path -Parent $binDir
  $baseDirIni = $baseDir -replace '\\','/'

  @"
[mysqld]
basedir=$baseDirIni
datadir=C:/ProgramData/MySQL/MySQL Server 8.4/Data
port=3306
bind-address=127.0.0.1
mysqlx=0

[client]
port=3306
"@ | Set-Content -Path $cfg -Encoding ASCII

  return $cfg
}

function Start-MySQLByProcessFallback {
  $mysqld = Get-MySQLDPath
  if (-not $mysqld) {
    throw "MySQL binary not found (mysqld.exe)."
  }

  $cfg = Ensure-MySQLConfig -MysqldPath $mysqld
  Write-WarnMsg "Trying mysqld process fallback with config: $cfg"

  $escapedMysqld = $mysqld.Replace("'", "''")
  $escapedCfg = $cfg.Replace("'", "''")
  $cmd = "& '$escapedMysqld' --defaults-file='$escapedCfg' --console"
  Start-Process -FilePath "powershell" -ArgumentList @("-Command", $cmd) -WindowStyle Hidden | Out-Null
}

function Ensure-MySQLRunning {
  if (Test-TcpPort -HostName $MysqlHost -Port $MysqlPort) {
    Write-Info "MySQL is reachable at $MysqlHost`:$MysqlPort."
    return
  }

  Write-WarnMsg "MySQL is not listening. Trying to start common Windows services..."
  $serviceCandidates = @("MySQL80", "MySQL", "MariaDB", "mariadb")

  foreach ($svc in $serviceCandidates) {
    try {
      $service = Get-Service -Name $svc -ErrorAction Stop
      if ($service.Status -ne "Running") {
        Start-Service -Name $svc -ErrorAction Stop
        Write-Info "Start-Service attempted: $svc"
      }
    } catch {
      # try next
    }
  }

  for ($i = 0; $i -lt 6; $i++) {
    if (Test-TcpPort -HostName $MysqlHost -Port $MysqlPort) {
      Write-Info "MySQL is available."
      return
    }
    Start-Sleep -Seconds 1
  }

  Start-MySQLByProcessFallback

  $ok = $false
  for ($i = 0; $i -lt 16; $i++) {
    if (Test-TcpPort -HostName $MysqlHost -Port $MysqlPort) {
      $ok = $true
      break
    }
    Start-Sleep -Seconds 1
  }

  if (-not $ok) {
    throw "MySQL is not running or not reachable at $MysqlHost`:$MysqlPort."
  }

  Write-Info "MySQL is available."
}

function Start-BackendIfNeeded([string]$BackendDir, [string]$HealthUrl) {
  if (Test-HttpOk -Url $HealthUrl -TimeoutSec 2) {
    Write-Info "Backend already running: $HealthUrl"
    return
  }

  if (Test-TcpPort -HostName "127.0.0.1" -Port $BackendPort) {
    throw "Port $BackendPort is occupied but backend health check failed: $HealthUrl"
  }

  $escapedBackendDir = $BackendDir.Replace("'", "''")

  $backendCommand = @"
Set-Location '$escapedBackendDir'
`$env:SERVER_ADDR=':$BackendPort'
`$env:PRISM_CONFIG_PATH='$resolvedConfigPath'
`$env:DEEPSEEK_API_BASE='$DeepseekApiBase'
`$env:DEEPSEEK_MODEL_NAME='$DeepseekModel'
if ('$DeepseekApiKey' -ne '') { `$env:DEEPSEEK_API_KEY='$DeepseekApiKey' }
go run .\cmd\server
"@

  Write-Info "Starting backend on port $BackendPort..."
  Start-Process -FilePath "powershell" -ArgumentList @(
    "-NoExit",
    "-ExecutionPolicy", "Bypass",
    "-Command", $backendCommand
  ) | Out-Null

  if (-not (Wait-HttpOk -Url $HealthUrl -MaxSeconds 35)) {
    throw "Backend startup timeout. Health check failed: $HealthUrl"
  }

  Write-Info "Backend started."
}

function Start-FrontendIfNeeded([string]$FrontendDir, [string]$FrontendUrl, [string]$ApiTarget) {
  if (Test-HttpOk -Url $FrontendUrl -TimeoutSec 2) {
    Write-Info "Frontend already running: $FrontendUrl"
    return
  }

  if (Test-TcpPort -HostName "127.0.0.1" -Port $FrontendPort) {
    throw "Port $FrontendPort is occupied but frontend URL is not available: $FrontendUrl"
  }

  $escapedFrontendDir = $FrontendDir.Replace("'", "''")
  $escapedApiTarget = $ApiTarget.Replace("'", "''")

  $frontendCommand = @"
Set-Location '$escapedFrontendDir'
if (-not (Test-Path '.\node_modules')) {
  npm install
}
`$env:VITE_API_TARGET='$escapedApiTarget'
npm run dev -- --host 0.0.0.0 --port $FrontendPort
"@

  Write-Info "Starting frontend on port $FrontendPort..."
  Start-Process -FilePath "powershell" -ArgumentList @(
    "-NoExit",
    "-ExecutionPolicy", "Bypass",
    "-Command", $frontendCommand
  ) | Out-Null

  if (-not (Wait-HttpOk -Url $FrontendUrl -MaxSeconds 45)) {
    throw "Frontend startup timeout. URL is not available: $FrontendUrl"
  }

  Write-Info "Frontend started."
}

try {
  $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  $resolvedConfigPath = if ([System.IO.Path]::IsPathRooted($ConfigPath)) { $ConfigPath } else { Join-Path $scriptRoot $ConfigPath }
  $cfg = Load-JsonConfig -Path $resolvedConfigPath

  if ($cfg) {
    if (-not $PSBoundParameters.ContainsKey('BackendPort') -and $cfg.backend.server_addr) {
      $addr = [string]$cfg.backend.server_addr
      if ($addr.StartsWith(':')) {
        $BackendPort = [int]($addr.TrimStart(':'))
      }
    }
    if (-not $PSBoundParameters.ContainsKey('FrontendPort') -and $cfg.frontend.port) {
      $FrontendPort = [int]$cfg.frontend.port
    }
    if (-not $PSBoundParameters.ContainsKey('MysqlDSN') -and $cfg.mysql.dsn) {
      $MysqlDSN = [string]$cfg.mysql.dsn
    }
    if (-not $PSBoundParameters.ContainsKey('DeepseekApiBase') -and $cfg.llm.api_base) {
      $DeepseekApiBase = [string]$cfg.llm.api_base
    }
    if (-not $PSBoundParameters.ContainsKey('DeepseekModel') -and $cfg.llm.model_name) {
      $DeepseekModel = [string]$cfg.llm.model_name
    }
    if (-not $PSBoundParameters.ContainsKey('DeepseekApiKey') -and $cfg.llm.api_key) {
      $DeepseekApiKey = [string]$cfg.llm.api_key
    }
  }

  $backendDir = Join-Path $scriptRoot "backend"
  $frontendDir = Join-Path $scriptRoot "frontend"

  if (-not (Test-Path $backendDir)) { throw "Backend directory not found: $backendDir" }
  if (-not (Test-Path $frontendDir)) { throw "Frontend directory not found: $frontendDir" }

  Require-Command -Name "go" -Hint "Install Go and add it to PATH."
  Require-Command -Name "npm" -Hint "Install Node.js/NPM and add npm to PATH."

  Ensure-MySQLRunning

  $backendHealthUrl = "http://127.0.0.1:$BackendPort/api/v1/health"
  $frontendUrl = "http://127.0.0.1:$FrontendPort"
  $apiPrefix = "http://127.0.0.1:$BackendPort/api/v1"
  $apiHealth = "http://127.0.0.1:$BackendPort/api/v1/health"
  $apiClues = "http://127.0.0.1:$BackendPort/api/v1/clues"

  Start-BackendIfNeeded -BackendDir $backendDir -HealthUrl $backendHealthUrl
  Start-FrontendIfNeeded -FrontendDir $frontendDir -FrontendUrl $frontendUrl -ApiTarget "http://127.0.0.1:$BackendPort"

  Write-Host ""
  Write-Host "========== STARTED ==========" -ForegroundColor Green
  Write-Host "Frontend: $frontendUrl" -ForegroundColor Green
  Write-Host "Backend Health: $backendHealthUrl" -ForegroundColor Green
  Write-Host "Backend API Root: $apiPrefix" -ForegroundColor Green
  Write-Host "Backend API Health: $apiHealth" -ForegroundColor Green
  Write-Host "Backend API Clues: $apiClues" -ForegroundColor Green
  Write-Host "=============================" -ForegroundColor Green
} catch {
  Write-Err $_.Exception.Message
  exit 1
}

