
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'host/windows-host-shell/demo-data/host-demo-data.json',
  'docs/development/windows-host-demo-and-settings.md'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing host demo/settings file: $path"
  }
}

$demoData = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/demo-data/host-demo-data.json') -Raw | ConvertFrom-Json

if ($demoData.settings.demoMode -ne $true) {
  throw 'Demo data must explicitly mark demo mode as true.'
}

$demoRaw = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/demo-data/host-demo-data.json') -Raw
foreach ($forbiddenPhrase in @('.mp3', '.mp4', '.zip', 'password', 'secret', 'token')) {
  if ($demoRaw -match [regex]::Escape($forbiddenPhrase)) {
    throw "Demo data must not contain forbidden phrase: $forbiddenPhrase"
  }
}

$index = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/index.html') -Raw
foreach ($requiredPhrase in @(
  'First-Run Setup',
  'Demo mode',
  'Local authorized media folder',
  'HQ server URL',
  'Local request server port',
  'UI scaling'
)) {
  if ($index -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell is missing Wave 3D phrase: $requiredPhrase"
  }
}

$appScript = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/app.js') -Raw
foreach ($requiredPhrase in @(
  'demoModeEnabled: true',
  'firstRunSetupEnabled: true',
  'uiScalingEnabled: true',
  'No folder scan or server connection was started'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell app script is missing Wave 3D phrase: $requiredPhrase"
  }
}

Write-Host 'Host demo/settings smoke test passed: demo mode, first-run setup, folder/server placeholders, and UI scaling are present.'
