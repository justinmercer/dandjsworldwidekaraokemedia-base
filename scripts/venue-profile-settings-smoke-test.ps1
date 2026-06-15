
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/venue-profile-settings-shell.md',
  'venue/profiles/demo-data/venue-profile-fixtures.json',
  'venue/profiles/src/index.html'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing venue profile settings shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'venue/profiles/demo-data/venue-profile-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'writesVenueProfile',
  'uploadsLogo',
  'storesLogoFile',
  'generatesAccessCode',
  'changesRouterConfig',
  'changesDns',
  'changesPorts',
  'changesFirewall',
  'writesRuntimeSettings'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Venue profile fixture guard must remain false: $guard"
  }
}

$html = Get-Content -LiteralPath (Join-Path $root 'venue/profiles/src/index.html') -Raw
foreach ($requiredPhrase in @(
  'Venue-profile model',
  'Venue name',
  'Venue address fields',
  'Venue logo',
  'Venue contact notes',
  'Venue request settings',
  'Venue access-code settings',
  'Venue local-router notes',
  'Venue default display theme',
  'Venue announcement text',
  'No venue database writes',
  'No logo uploads',
  'No file storage',
  'No access-code generation',
  'No router config changes',
  'No DNS changes',
  'No port changes',
  'No firewall changes'
)) {
  if ($html -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Venue profile settings shell is missing Wave 9A phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/venue-profile-settings-shell.md') -Raw
foreach ($requiredPhrase in @(
  'Wave 9A adds',
  'venue-profile model preview',
  'venue name preview',
  'venue address fields preview',
  'venue logo placeholder',
  'venue contact notes preview',
  'venue request settings preview',
  'venue access-code settings preview',
  'venue local-router notes preview',
  'venue default display theme preview',
  'venue announcement text preview'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Venue profile settings doc is missing Wave 9A phrase: $requiredPhrase"
  }
}

Write-Host 'Venue profile settings smoke test passed: model, name, address, logo, contact notes, request settings, access-code settings, router notes, theme, announcement, and safety markers are present.'
