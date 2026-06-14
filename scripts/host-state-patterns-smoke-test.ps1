
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/windows-host-state-patterns.md'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing host state-pattern file: $path"
  }
}

$manifest = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/host-shell.manifest.json') -Raw | ConvertFrom-Json
if ($manifest.hostShellFeatures.confirmationDialogs.destructiveActionsEnabled -ne $false) {
  throw 'Confirmation dialogs must not enable destructive actions in Wave 3E.'
}

$index = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/index.html') -Raw
foreach ($requiredPhrase in @(
  'Loading state',
  'No singers queued',
  'Action unavailable',
  'Host notifications',
  'Confirm Safe Placeholder Action',
  'No file operation was attempted'
)) {
  if ($index -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell is missing Wave 3E phrase: $requiredPhrase"
  }
}

$appScript = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/app.js') -Raw
foreach ($requiredPhrase in @(
  'showToast',
  'showConfirmationDialog',
  'loadingStateEnabled: true',
  'emptyStateEnabled: true',
  'errorStateEnabled: true',
  'toastNotificationsEnabled: true',
  'confirmationDialogPatternEnabled: true',
  'destructiveConfirmationActionsEnabled: false'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell app script is missing Wave 3E phrase: $requiredPhrase"
  }
}

Write-Host 'Host state-pattern smoke test passed: loading, empty, error, toast, and confirmation patterns are present and safe.'
