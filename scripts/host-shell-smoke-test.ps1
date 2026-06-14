
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'host/windows-host-shell/README.md',
  'host/windows-host-shell/host-shell.manifest.json',
  'host/windows-host-shell/src/index.html',
  'host/windows-host-shell/src/styles.css',
  'host/windows-host-shell/src/app.js',
  'docs/development/windows-host-shell.md'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing host shell file: $path"
  }
}

$manifestPath = Join-Path $root 'host/windows-host-shell/host-shell.manifest.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json

if ($manifest.shellKind -ne 'local-webview-shell') {
  throw 'Host shell manifest must use local-webview-shell.'
}

if ($manifest.safetyBoundaries.playsMedia -ne $false) {
  throw 'Wave 3A host shell must not enable playback.'
}

if ($manifest.safetyBoundaries.downloadsMedia -ne $false) {
  throw 'Wave 3A host shell must not enable media downloads.'
}

if ($manifest.safetyBoundaries.deletesMedia -ne $false) {
  throw 'Wave 3A host shell must not enable media deletion.'
}

$index = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/index.html') -Raw
foreach ($requiredPhrase in @(
  'Show Dashboard',
  'Rotation',
  'Now Playing',
  'Incoming Requests',
  'Song Search',
  'Sync Health',
  'Play Placeholder',
  'Venue selector',
  'Show Not Started',
  'Online Ready',
  'Local-Only Safe',
  'Offline Capable'
)) {
  if ($index -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell index is missing required phrase: $requiredPhrase"
  }
}

$appScript = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/app.js') -Raw
foreach ($requiredPhrase in @(
  'local-first',
  'mediaPlaybackEnabled: false',
  'mediaDownloadEnabled: false',
  'mediaDeletionEnabled: false'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell app script is missing required phrase: $requiredPhrase"
  }
}

Write-Host 'Host shell smoke test passed: local-first shell files and safety boundaries are present.'
