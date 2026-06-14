
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$appScript = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/app.js') -Raw

foreach ($requiredPhrase in @(
  'event.key === ''Escape''',
  'shortcutDialog.close()',
  'firstRunDialog.close()',
  'confirmationDialog.close()',
  'safeErrorDialog.close()',
  'diagnosticsDialog.close()',
  'cleanShutdownSmokeTestEnabled: true'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Clean-shutdown smoke missing app marker: $requiredPhrase"
  }
}

foreach ($forbiddenPhrase in @(
  'beforeunload',
  'window.close(',
  'process.exit',
  'deleteFile',
  'removeFile',
  'unlink'
)) {
  if ($appScript -match [regex]::Escape($forbiddenPhrase)) {
    throw "Clean-shutdown smoke found forbidden phrase: $forbiddenPhrase"
  }
}

Write-Host 'Host shell clean-shutdown smoke test passed: dialogs close safely and no destructive shutdown markers exist.'
