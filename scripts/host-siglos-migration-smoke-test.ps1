
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/windows-host-siglos-migration.md',
  'host/windows-host-shell/demo-data/siglos-export-demo-fixtures.json'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing Siglos migration file: $path"
  }
}

$fixturePath = Join-Path $root 'host/windows-host-shell/demo-data/siglos-export-demo-fixtures.json'
$fixtures = Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json

if ($fixtures.containsRealSiglosExport -ne $false -or $fixtures.readsLocalFiles -ne $false) {
  throw 'Siglos demo fixtures must not contain real exports or read local files.'
}

foreach ($requiredCase in @(
  'song-metadata-export',
  'singer-profile-export',
  'singer-history-export',
  'key-change-and-preferences',
  'duplicate-warning-preview'
)) {
  if (-not ($fixtures.cases | Where-Object { $_.id -eq $requiredCase })) {
    throw "Missing Siglos migration fixture case: $requiredCase"
  }
}

$manifest = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/host-shell.manifest.json') -Raw | ConvertFrom-Json
if ($manifest.hostShellFeatures.siglosMigrationWizard.readsSiglosExports -ne $false) {
  throw 'Siglos migration wizard must not read exports in Wave 4C.'
}
if ($manifest.hostShellFeatures.siglosMigrationWizard.writesCatalogRecords -ne $false) {
  throw 'Siglos migration wizard must not write catalog records in Wave 4C.'
}

$index = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/index.html') -Raw
foreach ($requiredPhrase in @(
  'Siglos Migration',
  'Song metadata export',
  'Singer profiles export',
  'Singer history export',
  'Remembered key changes',
  'Venue entries',
  'Saved preferences',
  'Migration preview',
  'Validation and duplicate warnings',
  'Backup',
  'Migration summary report',
  'Siglos Migration Preview'
)) {
  if ($index -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell is missing Wave 4C Siglos phrase: $requiredPhrase"
  }
}

$appScript = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/app.js') -Raw
foreach ($requiredPhrase in @(
  'showSiglosMigrationPreview',
  'siglosMigrationWizardEnabled: true',
  'siglosSongMetadataExportPreviewEnabled: true',
  'siglosSingerProfileExportPreviewEnabled: true',
  'siglosSingerHistoryExportPreviewEnabled: true',
  'siglosRememberedKeyChangePreviewEnabled: true',
  'siglosVenueEntryPreviewEnabled: true',
  'siglosSavedPreferencePreviewEnabled: true',
  'siglosMigrationPreviewEnabled: true',
  'siglosMigrationValidationEnabled: true',
  'siglosDuplicateWarningPreviewEnabled: true',
  'siglosBackupFirstMessagingEnabled: true',
  'siglosMigrationSummaryReportPreviewEnabled: true',
  'siglosDemoExportFixturesEnabled: true',
  'siglosMigrationTestsEnabled: true',
  'siglosMigrationReadsFiles: false',
  'siglosMigrationWritesRecords: false'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell app script is missing Wave 4C Siglos phrase: $requiredPhrase"
  }
}

Write-Host 'Host Siglos migration smoke test passed: wizard shell, fixtures, preview, validation, duplicate warnings, backup messaging, and safety markers are present.'
