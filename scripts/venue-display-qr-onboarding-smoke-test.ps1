
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/venue-display-qr-onboarding-shell.md',
  'venue/profiles/demo-data/venue-display-qr-fixtures.json',
  'venue/profiles/src/display-qr-onboarding.html'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing venue display QR onboarding shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'venue/profiles/demo-data/venue-display-qr-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'writesVenueDatabase',
  'writesRuntimeSettings',
  'generatesQrFile',
  'createsPrintableFile',
  'writesImportExportFiles',
  'changesAudioSystem',
  'changesVolume',
  'changesRotationPolicy',
  'changesRouterConfig'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Venue display QR onboarding fixture guard must remain false: $guard"
  }
}

$html = Get-Content -LiteralPath (Join-Path $root 'venue/profiles/src/display-qr-onboarding.html') -Raw
foreach ($requiredPhrase in @(
  'Venue scrolling-message settings',
  'Venue opening screen',
  'Venue closing screen',
  'Venue saved show preferences',
  'Venue default filler-audio settings',
  'Venue default volume settings',
  'Venue default rotation policy',
  'Venue QR-code generation',
  'Printable QR-code sheet',
  'Table-tent QR layout',
  'Venue profile import and export',
  'Venue theme preview',
  'Venue settings validation',
  'Venue profile tests',
  'Venue onboarding documentation',
  'No real QR file generation',
  'No printable file creation',
  'No import/export file writes',
  'No audio changes',
  'No volume changes',
  'No router changes',
  'No runtime settings writes',
  'No venue database writes'
)) {
  if ($html -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Venue display QR onboarding shell is missing Wave 9B phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/venue-display-qr-onboarding-shell.md') -Raw
foreach ($requiredPhrase in @(
  'Wave 9B adds',
  'venue scrolling-message settings preview',
  'venue opening screen preview',
  'venue closing screen preview',
  'venue saved show preferences preview',
  'venue default filler-audio settings preview',
  'venue default volume settings preview',
  'venue default rotation policy preview',
  'venue QR-code generation preview',
  'printable QR-code sheet preview',
  'table-tent QR layout preview',
  'venue profile import and export preview',
  'venue theme preview',
  'venue settings validation preview',
  'venue profile tests preview',
  'venue onboarding documentation preview'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Venue display QR onboarding doc is missing Wave 9B phrase: $requiredPhrase"
  }
}

Write-Host 'Venue display QR onboarding smoke test passed: scrolling message, opening/closing screens, show preferences, filler audio, volume, rotation, QR previews, import/export, theme, validation, tests, onboarding, and safety markers are present.'
