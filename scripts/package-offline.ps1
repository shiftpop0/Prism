param(
  [string]$OutputDir = ".\release",
  [string]$BundleName = "prism-offline",
  [string]$BackendServerAddr = "",
  [int]$FrontendPort = 0,
  [switch]$SkipNodeRuntime,
  [string]$NodeVersion = "v20.11.1",
  [switch]$SkipFrontendBuild,
  [switch]$SkipBackendBuild
)

$ErrorActionPreference = "Stop"

function Info([string]$msg) {
  Write-Host "[INFO] $msg" -ForegroundColor Cyan
}

function Resolve-PortFromAddr([string]$addr, [int]$fallback) {
  if ([string]::IsNullOrWhiteSpace($addr)) { return $fallback }
  $port = ($addr -replace "^.*:", "")
  if ($port -match "^\d+$") { return [int]$port }
  return $fallback
}

function Ensure-FileDownload([string]$url, [string]$path) {
  if (Test-Path $path) { return }
  Info "Downloading $url"
  Invoke-WebRequest -Uri $url -OutFile $path
}

function Ensure-NodeArtifacts([string]$cacheDir, [string]$version) {
  New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
  $msiName = "node-$version-x64.msi"
  $zipName = "node-$version-win-x64.zip"
  $msiPath = Join-Path $cacheDir $msiName
  $zipPath = Join-Path $cacheDir $zipName
  $base = "https://nodejs.org/dist/$version"
  Ensure-FileDownload "$base/$msiName" $msiPath
  Ensure-FileDownload "$base/$zipName" $zipPath
  return @{
    MsiPath = $msiPath
    ZipPath = $zipPath
    MsiName = $msiName
    ZipName = $zipName
  }
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$appRoot = Resolve-Path (Join-Path $scriptRoot "..")
$frontendDir = Join-Path $appRoot "frontend"
$backendDir = Join-Path $appRoot "backend"
$configDir = Join-Path $appRoot "config"
$runtimeCacheDir = Join-Path $appRoot "runtime\node-cache\$NodeVersion"

if (-not (Test-Path $frontendDir)) { throw "frontend dir not found: $frontendDir" }
if (-not (Test-Path $backendDir)) { throw "backend dir not found: $backendDir" }

if (-not (Test-Path $OutputDir)) {
  New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$stagingRoot = Join-Path (Resolve-Path $OutputDir) "$BundleName-$ts"
$bundleRoot = Join-Path $stagingRoot "bundle"
$finalOutputDir = (Resolve-Path $OutputDir).Path

New-Item -ItemType Directory -Path $bundleRoot -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $bundleRoot "backend") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $bundleRoot "frontend") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $bundleRoot "config") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $bundleRoot "docs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $bundleRoot "run") -Force | Out-Null

if (-not $SkipFrontendBuild) {
  Info "Building frontend dist..."
  Push-Location $frontendDir
  try {
    if (-not (Test-Path ".\node_modules")) {
      npm install
    }
    npm run build
  } finally {
    Pop-Location
  }
}

if (-not $SkipBackendBuild) {
  Info "Building backend executable..."
  Push-Location $backendDir
  try {
    go build -o (Join-Path $bundleRoot "backend\server.exe") .\cmd\server
  } finally {
    Pop-Location
  }
} else {
  $existingExe = Join-Path $backendDir "server.exe"
  if (-not (Test-Path $existingExe)) {
    throw "SkipBackendBuild is set but backend/server.exe does not exist"
  }
  Copy-Item $existingExe (Join-Path $bundleRoot "backend\server.exe") -Force
}

Info "Copying runtime files..."
Copy-Item (Join-Path $frontendDir "dist") (Join-Path $bundleRoot "frontend\dist") -Recurse -Force
Copy-Item (Join-Path $configDir "prism-config.json") (Join-Path $bundleRoot "config\prism-config.json") -Force
Copy-Item (Join-Path $backendDir "scripts\read_case_snapshot.go") (Join-Path $bundleRoot "backend\read_case_snapshot.go") -Force
if (Test-Path (Join-Path $appRoot "README.md")) {
  Copy-Item (Join-Path $appRoot "README.md") (Join-Path $bundleRoot "docs\README.md") -Force
}
if (Test-Path (Join-Path $appRoot "OFFLINE_PACKAGING.md")) {
  Copy-Item (Join-Path $appRoot "OFFLINE_PACKAGING.md") (Join-Path $bundleRoot "docs\OFFLINE_PACKAGING.md") -Force
}

$bundleConfigPath = Join-Path $bundleRoot "config\prism-config.json"
$cfgObj = Get-Content -Path $bundleConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($BackendServerAddr -ne "") {
  $cfgObj.backend.server_addr = $BackendServerAddr
}
if ($FrontendPort -gt 0) {
  $cfgObj.frontend.port = $FrontendPort
}
$backendPort = Resolve-PortFromAddr $cfgObj.backend.server_addr 8081
if (-not $cfgObj.frontend.port) {
  $cfgObj.frontend.port = 5173
}
$cfgObj.frontend.api_target = "http://127.0.0.1:$backendPort"
$cfgJson = $cfgObj | ConvertTo-Json -Depth 20
[System.IO.File]::WriteAllText($bundleConfigPath, $cfgJson, (New-Object System.Text.UTF8Encoding($false)))

if (-not $SkipNodeRuntime) {
  $nodeMeta = Ensure-NodeArtifacts $runtimeCacheDir $NodeVersion
  $nodeInstallerDir = Join-Path $bundleRoot "runtime\node-installer"
  $nodePortableDir = Join-Path $bundleRoot "runtime\node-portable"
  New-Item -ItemType Directory -Path $nodeInstallerDir -Force | Out-Null
  New-Item -ItemType Directory -Path $nodePortableDir -Force | Out-Null
  Copy-Item $nodeMeta.MsiPath (Join-Path $nodeInstallerDir $nodeMeta.MsiName) -Force
  Copy-Item $nodeMeta.ZipPath (Join-Path $nodeInstallerDir $nodeMeta.ZipName) -Force
  Expand-Archive -Path $nodeMeta.ZipPath -DestinationPath $nodePortableDir -Force

  $installNodePs1 = @'
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
'@
  Set-Content -Path (Join-Path $bundleRoot "install-node-offline.ps1") -Value $installNodePs1 -Encoding UTF8
}

$frontendServerJs = @'
const http = require("http");
const fs = require("fs");
const path = require("path");
const { URL } = require("url");

const frontendPort = Number(process.env.FRONTEND_PORT || "5173");
const frontendHost = process.env.FRONTEND_HOST || "0.0.0.0";
const backendTarget = process.env.BACKEND_TARGET || "http://127.0.0.1:8081";
const staticDir = process.env.PRISM_FRONTEND_DIST || path.join(__dirname, "dist");

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
};

function send(res, code, body, contentType) {
  res.writeHead(code, { "Content-Type": contentType || "text/plain; charset=utf-8" });
  res.end(body);
}

function proxyApi(req, res) {
  const base = new URL(backendTarget);
  const options = {
    protocol: base.protocol,
    hostname: base.hostname,
    port: base.port,
    method: req.method,
    path: req.url,
    headers: { ...req.headers, host: base.host },
  };
  const proxyReq = http.request(options, (proxyRes) => {
    res.writeHead(proxyRes.statusCode || 502, proxyRes.headers);
    proxyRes.pipe(res);
  });
  proxyReq.on("error", (err) => send(res, 502, "proxy error: " + err.message));
  req.pipe(proxyReq);
}

function serveStatic(req, res) {
  let pathname = req.url || "/";
  if (pathname.includes("?")) pathname = pathname.split("?")[0];
  if (pathname === "/") pathname = "/index.html";
  const normalized = path.normalize(pathname).replace(/^(\.\.[\\/])+/, "");
  let filePath = path.join(staticDir, normalized);
  if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
    filePath = path.join(staticDir, "index.html");
  }
  fs.readFile(filePath, (err, data) => {
    if (err) return send(res, 404, "not found");
    const ext = path.extname(filePath).toLowerCase();
    send(res, 200, data, MIME[ext] || "application/octet-stream");
  });
}

const server = http.createServer((req, res) => {
  if (!req.url) return send(res, 400, "bad request");
  if (req.url.startsWith("/api/")) return proxyApi(req, res);
  return serveStatic(req, res);
});

server.listen(frontendPort, frontendHost, () => {
  console.log(`[frontend] static+proxy server listening on http://${frontendHost}:${frontendPort}`);
  console.log(`[frontend] proxy target: ${backendTarget}`);
});
'@
Set-Content -Path (Join-Path $bundleRoot "frontend\server.js") -Value $frontendServerJs -Encoding UTF8

$startOfflinePs1 = @'
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

$backendLog = Join-Path $runDir "backend.log"
$frontendLog = Join-Path $runDir "frontend.log"
[System.IO.File]::WriteAllText($backendLog, "", (New-Object System.Text.UTF8Encoding($false)))
[System.IO.File]::WriteAllText($frontendLog, "", (New-Object System.Text.UTF8Encoding($false)))
$backendCmd = "`$Utf8NoBom = New-Object System.Text.UTF8Encoding(`$false); [Console]::InputEncoding = `$Utf8NoBom; [Console]::OutputEncoding = `$Utf8NoBom; `$OutputEncoding = `$Utf8NoBom; `$PSDefaultParameterValues['Out-File:Encoding']='utf8'; `$env:PRISM_CONFIG_PATH='$resolvedConfig'; `$env:SERVER_ADDR='$backendAddr'; `$env:PRISM_STATIC_DIR=''; & '$backendExe' 2>&1 | Out-File -FilePath '$backendLog' -Append -Encoding utf8"
$backendProc = Start-Process powershell -ArgumentList @("-ExecutionPolicy","Bypass","-Command",$backendCmd) -PassThru -WindowStyle Hidden
$backendProc.Id | Set-Content -Path (Join-Path $runDir "backend.pid") -Encoding ASCII

$frontendCmd = "`$Utf8NoBom = New-Object System.Text.UTF8Encoding(`$false); [Console]::InputEncoding = `$Utf8NoBom; [Console]::OutputEncoding = `$Utf8NoBom; `$OutputEncoding = `$Utf8NoBom; `$PSDefaultParameterValues['Out-File:Encoding']='utf8'; `$env:PRISM_FRONTEND_DIST='" + (Join-Path $root "frontend\dist") + "'; `$env:BACKEND_TARGET='http://127.0.0.1:$backendPort'; `$env:FRONTEND_HOST='0.0.0.0'; `$env:FRONTEND_PORT='$frontendPortFinal'; & '$nodeCmd' '$frontendServer' 2>&1 | Out-File -FilePath '$frontendLog' -Append -Encoding utf8"
$frontendProc = Start-Process powershell -ArgumentList @("-ExecutionPolicy","Bypass","-Command",$frontendCmd) -PassThru -WindowStyle Hidden
$frontendProc.Id | Set-Content -Path (Join-Path $runDir "frontend.pid") -Encoding ASCII

Write-Host "[INFO] Prism started in background" -ForegroundColor Green
Write-Host "[INFO] frontend: http://127.0.0.1:$frontendPortFinal" -ForegroundColor Green
Write-Host "[INFO] backend : http://127.0.0.1:$backendPort" -ForegroundColor Green
Write-Host "[INFO] logs: $backendLog / $frontendLog" -ForegroundColor Yellow
Write-Host "[INFO] run stop script to shutdown: .\stop-offline.ps1" -ForegroundColor Yellow
'@
Set-Content -Path (Join-Path $bundleRoot "start-offline.ps1") -Value $startOfflinePs1 -Encoding UTF8

$stopOfflinePs1 = @'
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

function Stop-IfRunning([int]$procId) {
  try {
    $p = Get-Process -Id $procId -ErrorAction Stop
    Stop-Process -Id $p.Id -Force
    Write-Host "[INFO] stopped pid=$procId"
  } catch {}
}

function Stop-ByPort([int]$port) {
  try {
    $items = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue
    if ($items) {
      $pids = $items | Select-Object -ExpandProperty OwningProcess -Unique
      foreach ($portProcId in $pids) { Stop-IfRunning ([int]$portProcId) }
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
'@
Set-Content -Path (Join-Path $bundleRoot "stop-offline.ps1") -Value $stopOfflinePs1 -Encoding UTF8

Set-Content -Path (Join-Path $bundleRoot "start-offline.bat") -Value "@echo off
powershell -ExecutionPolicy Bypass -File `%~dp0start-offline.ps1
" -Encoding ASCII
Set-Content -Path (Join-Path $bundleRoot "stop-offline.bat") -Value "@echo off
powershell -ExecutionPolicy Bypass -File `%~dp0stop-offline.ps1
" -Encoding ASCII

$zipPath = Join-Path $finalOutputDir "$BundleName-$ts.zip"
Info "Creating zip package: $zipPath"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath
Remove-Item -Path $stagingRoot -Recurse -Force

Write-Host ""
Write-Host "========== PACK DONE ==========" -ForegroundColor Green
Write-Host "Zip File : $zipPath" -ForegroundColor Green
Write-Host "===============================" -ForegroundColor Green
