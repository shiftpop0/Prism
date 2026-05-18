param(
  [string]$Dsn = "",
  [int]$Timeout = 5,
  [string]$ConfigPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Info([string]$msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Ok([string]$msg) { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-WarnMsg([string]$msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err([string]$msg) { Write-Host "[ERROR] $msg" -ForegroundColor Red }

function Mask-Dsn([string]$dsn) {
  if ([string]::IsNullOrWhiteSpace($dsn)) { return $dsn }
  $marker = "@tcp("
  $at = $dsn.IndexOf($marker)
  if ($at -le 0) { return $dsn }
  $left = $dsn.Substring(0, $at)
  $colon = $left.IndexOf(":")
  if ($colon -lt 0) { return $dsn }
  return $left.Substring(0, $colon + 1) + "******" + $dsn.Substring($at)
}

function Try-LoadConfig([string]$explicitPath) {
  $paths = @()
  if (-not [string]::IsNullOrWhiteSpace($explicitPath)) {
    $paths += $explicitPath
  }
  if (-not [string]::IsNullOrWhiteSpace($env:PRISM_CONFIG_PATH)) {
    $paths += $env:PRISM_CONFIG_PATH
  }
  $paths += @(
    (Join-Path $PSScriptRoot "..\config\prism-config.json"),
    (Join-Path (Get-Location) "config\prism-config.json")
  )
  foreach ($p in $paths) {
    if (Test-Path $p) {
      try {
        $json = Get-Content -Raw -Path $p | ConvertFrom-Json
        return $json
      } catch {
        continue
      }
    }
  }
  return $null
}

function Parse-GoDsn([string]$dsn) {
  $r = [ordered]@{
    User = ""
    Password = ""
    Host = ""
    Port = 3306
    Database = ""
  }
  if ([string]::IsNullOrWhiteSpace($dsn)) { return $r }
  $marker = "@tcp("
  $idx = $dsn.IndexOf($marker)
  if ($idx -lt 0) { return $r }

  $userInfo = $dsn.Substring(0, $idx)
  $rest = $dsn.Substring($idx + $marker.Length)

  $rightParen = $rest.IndexOf(")")
  if ($rightParen -lt 0) { return $r }
  $addr = $rest.Substring(0, $rightParen)
  $afterAddr = $rest.Substring($rightParen + 1)

  if (-not $afterAddr.StartsWith("/")) { return $r }
  $dbAndParams = $afterAddr.Substring(1)
  $qIdx = $dbAndParams.IndexOf("?")
  if ($qIdx -ge 0) {
    $r.Database = $dbAndParams.Substring(0, $qIdx)
  } else {
    $r.Database = $dbAndParams
  }

  $colonInUser = $userInfo.IndexOf(":")
  if ($colonInUser -ge 0) {
    $r.User = $userInfo.Substring(0, $colonInUser)
    $r.Password = $userInfo.Substring($colonInUser + 1)
  } else {
    $r.User = $userInfo
    $r.Password = ""
  }

  $lastColonInAddr = $addr.LastIndexOf(":")
  if ($lastColonInAddr -gt 0) {
    $r.Host = $addr.Substring(0, $lastColonInAddr)
    $portText = $addr.Substring($lastColonInAddr + 1)
    $portNum = 0
    if ([int]::TryParse($portText, [ref]$portNum)) {
      $r.Port = $portNum
    } else {
      $r.Port = 3306
    }
  } else {
    $r.Host = $addr
    $r.Port = 3306
  }

  return $r
}

function Test-Tcp([string]$h, [int]$pt, [int]$timeoutSec) {
  $client = New-Object System.Net.Sockets.TcpClient
  try {
    $iar = $client.BeginConnect($h, $pt, $null, $null)
    if (-not $iar.AsyncWaitHandle.WaitOne([TimeSpan]::FromSeconds($timeoutSec))) {
      return @{ Ok = $false; Message = "tcp timeout after ${timeoutSec}s" }
    }
    $client.EndConnect($iar) | Out-Null
    return @{ Ok = $true; Message = "tcp connect success: ${h}:$pt" }
  } catch {
    return @{ Ok = $false; Message = $_.Exception.Message }
  } finally {
    $client.Close()
  }
}

$dsnSource = ""
$resolvedDsn = $Dsn.Trim()
if (-not [string]::IsNullOrWhiteSpace($resolvedDsn)) {
  $dsnSource = "param -Dsn"
}

if ([string]::IsNullOrWhiteSpace($resolvedDsn)) {
  $cfg = Try-LoadConfig $ConfigPath
  if ($null -ne $cfg) {
    $cfgDsn = ""
    try { $cfgDsn = "$($cfg.mysql.dsn)".Trim() } catch {}
    if (-not [string]::IsNullOrWhiteSpace($cfgDsn)) {
      $resolvedDsn = $cfgDsn
      $dsnSource = "prism-config mysql.dsn"
    }
  }
}

if ([string]::IsNullOrWhiteSpace($resolvedDsn)) {
  Write-Err "No DSN found. Use -Dsn or configure prism-config.json mysql.dsn."
  exit 2
}

Write-Info "DSN source: $dsnSource"
Write-Info ("DSN (masked): " + (Mask-Dsn $resolvedDsn))

$parts = Parse-GoDsn $resolvedDsn
if ([string]::IsNullOrWhiteSpace($parts.Host) -or $parts.Port -le 0) {
  Write-Err "Cannot parse host/port from DSN. Supported format: user[:pass]@tcp(host[:port])/db"
  exit 1
}

$tcp = Test-Tcp $parts.Host $parts.Port $Timeout
if (-not $tcp.Ok) {
  Write-Err "TCP connect failed: $($tcp.Message)"
  exit 1
}
Write-Ok $tcp.Message

$mysqlCmd = Get-Command mysql -ErrorAction SilentlyContinue
if ($null -eq $mysqlCmd) {
  Write-WarnMsg "mysql.exe not found. TCP check completed; auth/SQL test skipped."
  Write-Info "Install MySQL Client and run again for full verification."
  exit 0
}

if ([string]::IsNullOrWhiteSpace($parts.User) -or [string]::IsNullOrWhiteSpace($parts.Database)) {
  Write-WarnMsg "DSN parse did not get user/database; SQL test skipped."
  exit 0
}

$mysqlArgs = @(
  "--connect-timeout=$Timeout"
  "--protocol=TCP"
  "-h", $parts.Host
  "-P", [string]$parts.Port
  "-u", $parts.User
  "-e", "SELECT NOW() as now_time;"
  $parts.Database
)
if (-not [string]::IsNullOrWhiteSpace($parts.Password)) {
  $mysqlArgs = @("--password=$($parts.Password)") + $mysqlArgs
}

Write-Info "mysql.exe detected. Running auth and SQL test..."
& $mysqlCmd.Source @mysqlArgs
if ($LASTEXITCODE -ne 0) {
  Write-Err "mysql client test failed (auth/permission/database name may be incorrect)."
  exit $LASTEXITCODE
}

Write-Ok "mysql auth and SQL test passed."
exit 0
