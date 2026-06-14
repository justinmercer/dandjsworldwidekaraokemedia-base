
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$appPath = Join-Path $root 'host/windows-host-shell/src/app.js'
$indexPath = Join-Path $root 'host/windows-host-shell/src/index.html'
$stylePath = Join-Path $root 'host/windows-host-shell/src/styles.css'

foreach ($path in @($appPath, $indexPath, $stylePath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "Missing host shell source file: $path"
  }
}

node --check $appPath

$index = Get-Content -LiteralPath $indexPath -Raw
foreach ($requiredPhrase in @(
  'app.js',
  'styles.css',
  'D & J',
  'toastRegion',
  'activityLogList'
)) {
  if ($index -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell static compile check missing marker: $requiredPhrase"
  }
}

Write-Host 'Host shell static compile check passed: JavaScript syntax and core source references are valid.'
