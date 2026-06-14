
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$appScript = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/app.js') -Raw

foreach ($requiredPhrase in @(
  'settingsSchemaVersion = 1',
  'legacySettingsKeys',
  'migrateSavedSettings',
  'settingsSchemaVersion',
  'localStorage.setItem(settingsKey',
  'settingsMigrationTestEnabled: true'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Settings migration smoke missing marker: $requiredPhrase"
  }
}

Write-Host 'Host settings migration smoke test passed: versioned localStorage migration markers are present.'
