param(
  [ValidateSet("msi","portable")]
  [string]$Mode = "portable"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$installerDir = Join-Path $root "runtime\node-installer"
$portableDir = Join-Path $root "runtime\node-portable"

if ($Mode -eq "msi") {
  $msi = Get-ChildItem -Path $installerDir -Filter "node-*-x64.msi" | Select-Object -First 1
  if (-not $msi) { throw "node msi not found in $installerDir" }
  Write-Host "[INFO] Installing Node.js MSI: $($msi.FullName)" -ForegroundColor Green
  Start-Process msiexec.exe -ArgumentList @("/i", "`"$($msi.FullName)`"", "/qn", "/norestart") -Wait
  Write-Host "[INFO] Node.js MSI install completed" -ForegroundColor Green
  exit 0
}

$nodeExe = Get-ChildItem -Path $portableDir -Recurse -Filter node.exe | Select-Object -First 1
if (-not $nodeExe) { throw "portable node.exe not found in $portableDir" }
Write-Host "[INFO] Portable Node is ready: $($nodeExe.FullName)" -ForegroundColor Green
Write-Host "[INFO] Prism start script will auto-use portable Node first." -ForegroundColor Green
