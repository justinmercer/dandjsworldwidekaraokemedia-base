
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/windows-host-catalog-import.md'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing host catalog import file: $path"
  }
}

$manifest = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/host-shell.manifest.json') -Raw | ConvertFrom-Json
if ($manifest.hostShellFeatures.catalogImportWizard.readsMediaFiles -ne $false) {
  throw 'Catalog import wizard must not read media files in Wave 4A.'
}

$index = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/index.html') -Raw
foreach ($requiredPhrase in @(
  'Catalog Import',
  'Select operator-owned folder',
  'supported file type detection',
  'Filename metadata parsing preview',
  'Manual correction and batch review',
  'Duplicate warning display',
  'Alternate-version warning display',
  'Import progress',
  'Cancel Import Preview',
  'Import error summary',
  'Import review queue'
)) {
  if ($index -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell is missing Wave 4A catalog import phrase: $requiredPhrase"
  }
}

$appScript = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/app.js') -Raw
foreach ($requiredPhrase in @(
  'parseImportFilenameCandidate',
  'renderFilenameParsePreview',
  'showImportCancelPreview',
  'catalogImportWizardEnabled: true',
  'filenameMetadataParsingPreviewEnabled: true',
  'manualMetadataCorrectionPreviewEnabled: true',
  'batchMetadataReviewPreviewEnabled: true',
  'duplicateWarningDisplayEnabled: true',
  'alternateVersionWarningDisplayEnabled: true',
  'importCancellationSafeRollbackPreviewEnabled: true',
  'importReadsMediaFiles: false'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell app script is missing Wave 4A catalog import phrase: $requiredPhrase"
  }
}

foreach ($forbiddenPhrase in @(
  'showOpenFilePicker',
  'FileSystemDirectoryHandle',
  'webkitdirectory',
  'readAsArrayBuffer',
  'fs.readFile',
  'unlink',
  'deleteFile'
)) {
  if ($index -match [regex]::Escape($forbiddenPhrase) -or $appScript -match [regex]::Escape($forbiddenPhrase)) {
    throw "Catalog import shell contains forbidden real file-operation marker: $forbiddenPhrase"
  }
}

Write-Host 'Host catalog import smoke test passed: wizard shell, review states, warnings, progress, cancellation preview, and safety markers are present.'
