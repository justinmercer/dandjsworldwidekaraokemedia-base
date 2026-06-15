
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/diagnostics-restore-preview-shell.md',
  'backup/demo-data/diagnostics-restore-preview-fixtures.json',
  'backup/src/diagnostics-restore-preview.html'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing diagnostics restore preview shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'backup/demo-data/diagnostics-restore-preview-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'performsRestore',
  'verifiesBackupFiles',
  'collectsDiagnosticLogs',
  'runsNetworkTests',
  'probesStorage',
  'connectsDatabase',
  'writesDatabase',
  'writesFiles'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Diagnostics restore preview guard must remain false: $guard"
  }
}

$html = Get-Content -LiteralPath (Join-Path $root 'backup/src/diagnostics-restore-preview.html') -Raw
foreach ($requiredPhrase in @(
  'Restore confirmation step',
  'Restore compatibility checks',
  'Backup verification checklist',
  'Diagnostics dashboard',
  'Diagnostics log bundle placeholder',
  'Internet connectivity check',
  'Storage health check',
  'Database health check',
  'No restore',
  'No backup verification against real files',
  'No diagnostic log collection',
  'No network tests',
  'No storage probing',
  'No database connection',
  'No filesystem writes beyond fixtures'
)) {
  if ($html -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Diagnostics restore preview shell is missing Wave 12B phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/diagnostics-restore-preview-shell.md') -Raw
foreach ($requiredPhrase in @(
  'Wave 12B adds',
  'restore confirmation step preview',
  'restore compatibility checks preview',
  'backup verification checklist preview',
  'diagnostics dashboard preview',
  'diagnostics log bundle placeholder',
  'internet connectivity check preview',
  'storage health check preview',
  'database health check preview'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Diagnostics restore preview doc is missing Wave 12B phrase: $requiredPhrase"
  }
}

Write-Host 'Diagnostics restore preview smoke test passed: confirmation, compatibility, verification checklist, dashboard, log bundle placeholder, internet, storage, database, and safety markers are present.'
