
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$index = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/index.html') -Raw
$appScript = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/app.js') -Raw

foreach ($requiredPhrase in @(
  'host-shell',
  'settingsForm',
  'shortcutDialog',
  'firstRunDialog',
  'confirmationDialog',
  'safeErrorDialog',
  'diagnosticsDialog'
)) {
  if ($index -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Startup smoke missing index marker: $requiredPhrase"
  }
}

foreach ($requiredPhrase in @(
  'songSearchInput',
  'applySettings(loadSettings())',
  'window.DJKaraokeHostShell',
  'liveShowMode: ''local-first''',
  'startupSmokeTestEnabled: true'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Startup smoke missing app marker: $requiredPhrase"
  }
}

Write-Host 'Host shell startup smoke test passed: required startup UI markers and app markers are present.'
