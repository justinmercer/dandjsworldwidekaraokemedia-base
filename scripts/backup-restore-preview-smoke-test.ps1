
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/backup-restore-preview-shell.md',
  'backup/demo-data/backup-restore-preview-fixtures.json',
  'backup/src/backup-restore-preview.html'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing backup restore preview shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'backup/demo-data/backup-restore-preview-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'performsBackup',
  'performsRestore',
  'createsExportFiles',
  'readsDatabase',
  'writesDatabase',
  'readsSingerHistory',
  'readsHostSettings',
  'writesBackupStorage'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Backup restore preview guard must remain false: $guard"
  }
}

$html = Get-Content -LiteralPath (Join-Path $root 'backup/src/backup-restore-preview.html') -Raw
foreach ($requiredPhrase in @(
  'HQ metadata backup',
  'Singer-history backup',
  'Venue-profile backup',
  'Show-session snapshot export',
  'Host settings backup',
  'Restore preview',
  'No real backup',
  'No restore',
  'No export files',
  'No database reads',
  'No database writes',
  'No singer-history access',
  'No host-settings access',
  'No backup storage writes'
)) {
  if ($html -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Backup restore preview shell is missing Wave 12A phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/backup-restore-preview-shell.md') -Raw
foreach ($requiredPhrase in @(
  'Wave 12A adds',
  'HQ metadata backup preview',
  'singer-history backup preview',
  'venue-profile backup preview',
  'show-session snapshot export preview',
  'host settings backup preview',
  'restore preview'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Backup restore preview doc is missing Wave 12A phrase: $requiredPhrase"
  }
}

Write-Host 'Backup restore preview smoke test passed: HQ metadata, singer history, venue profile, show-session snapshot, host settings, restore preview, and safety markers are present.'
