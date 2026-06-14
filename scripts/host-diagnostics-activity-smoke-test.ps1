
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/windows-host-diagnostics-and-activity.md',
  'docs/development/windows-host-build.md'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing host diagnostics/activity file: $path"
  }
}

$manifest = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/host-shell.manifest.json') -Raw | ConvertFrom-Json
if ($manifest.hostShellFeatures.diagnosticsExport.writesFiles -ne $false) {
  throw 'Diagnostics export must not write files in Wave 3F.'
}

$index = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/index.html') -Raw
foreach ($requiredPhrase in @(
  'Activity Log',
  'Show safe error',
  'Show toast follow-up',
  'Diagnostics export preview',
  'Safe Error Message',
  'does not generate, write, upload, or download diagnostic files'
)) {
  if ($index -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell is missing Wave 3F phrase: $requiredPhrase"
  }
}

$appScript = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/app.js') -Raw
foreach ($requiredPhrase in @(
  'appendActivityLog',
  'showSafeErrorDialog',
  'showDiagnosticsPreview',
  'safeErrorDialogsEnabled: true',
  'notificationFollowUpEnabled: true',
  'activityLogPanelEnabled: true',
  'diagnosticsExportPlaceholderEnabled: true',
  'diagnosticsExportWritesFiles: false'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell app script is missing Wave 3F phrase: $requiredPhrase"
  }
}

Write-Host 'Host diagnostics/activity smoke test passed: safe error, toast follow-up, activity log, diagnostics preview, and build docs are present.'
