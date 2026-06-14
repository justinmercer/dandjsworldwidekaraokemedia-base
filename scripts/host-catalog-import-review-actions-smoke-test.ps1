
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/windows-host-catalog-import-review-actions.md',
  'host/windows-host-shell/demo-data/catalog-import-demo-fixtures.json'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing catalog import review file: $path"
  }
}

$fixturePath = Join-Path $root 'host/windows-host-shell/demo-data/catalog-import-demo-fixtures.json'
$fixtures = Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json

if ($fixtures.containsRealMedia -ne $false) {
  throw 'Catalog import demo fixtures must not contain real media.'
}

foreach ($requiredCase in @(
  'malformed-filename',
  'duplicate-candidate',
  'alternate-version',
  'cancellation-preview'
)) {
  if (-not ($fixtures.cases | Where-Object { $_.id -eq $requiredCase })) {
    throw "Missing catalog import demo fixture case: $requiredCase"
  }
}

$manifest = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/host-shell.manifest.json') -Raw | ConvertFrom-Json
if ($manifest.hostShellFeatures.catalogImportReviewActions.writesCatalogRecords -ne $false) {
  throw 'Catalog import review actions must not write catalog records in Wave 4B.'
}

$index = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/index.html') -Raw
foreach ($requiredPhrase in @(
  'Needs manual review',
  'Skip for now',
  'Mark preferred',
  'Keep both versions',
  'Preview duplicate merge confirmation',
  'Safe Duplicate Merge Preview',
  'Import audit log preview'
)) {
  if ($index -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell is missing Wave 4B review action phrase: $requiredPhrase"
  }
}

$appScript = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/app.js') -Raw
foreach ($requiredPhrase in @(
  'appendImportAudit',
  'setImportReviewState',
  'showMergeDuplicatePreview',
  'importNeedsManualReviewStateEnabled: true',
  'importSkipForNowActionEnabled: true',
  'importMarkPreferredVersionActionEnabled: true',
  'importKeepBothVersionsActionEnabled: true',
  'importMergeDuplicateRecordsPreviewEnabled: true',
  'importSafeMergeConfirmationEnabled: true',
  'importAuditLogPreviewEnabled: true',
  'importDemoFixturesForTestsOnly: true',
  'catalogImportTestsEnabled: true',
  'malformedFilenameTestsEnabled: true',
  'duplicateDetectionTestsEnabled: true',
  'alternateVersionTestsEnabled: true',
  'importCancellationTestsEnabled: true',
  'importWritesCatalogRecords: false'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell app script is missing Wave 4B review action phrase: $requiredPhrase"
  }
}

Write-Host 'Host catalog import review-actions smoke test passed: review states, actions, fixture cases, and safe audit markers are present.'
