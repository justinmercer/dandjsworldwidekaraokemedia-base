
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/request-web-shell.md',
  'request/web-app/package.json',
  'request/web-app/README.md',
  'request/web-app/src/index.html',
  'request/web-app/src/app.js',
  'request/web-app/src/styles.css',
  'request/web-app/demo-data/request-web-shell-fixtures.json'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing request web shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'request/web-app/demo-data/request-web-shell-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'submitsRequests',
  'callsServerApis',
  'readsSingerRecords',
  'writesSingerRecords',
  'searchesRealCatalog',
  'storesPersonalData',
  'moderatesRequests',
  'enablesPwaInstall'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Request web fixture guard must remain false: $guard"
  }
}

$index = Get-Content -LiteralPath (Join-Path $root 'request/web-app/src/index.html') -Raw
foreach ($requiredPhrase in @(
  "D & J's Karaoke",
  'Request a song',
  'QR entry route',
  'Venue branding',
  'Who is singing?',
  'Returning singer lookup preview',
  'Privacy-safe match preview',
  'Find a song',
  'Shared tablet route',
  'Safety boundary'
)) {
  if ($index -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Request web shell is missing Wave 7A phrase: $requiredPhrase"
  }
}

$appScript = Get-Content -LiteralPath (Join-Path $root 'request/web-app/src/app.js') -Raw
foreach ($requiredPhrase in @(
  'requestWebSafety',
  'submitsRequests: false',
  'callsServerApis: false',
  'readsSingerRecords: false',
  'writesSingerRecords: false',
  'searchesRealCatalog: false',
  'storesPersonalData: false',
  'moderatesRequests: false',
  'enablesPwaInstall: false',
  'searchDebounceMs: 300'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Request web app script is missing Wave 7A phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/request-web-shell.md') -Raw
foreach ($requiredPhrase in @(
  'Wave 7A starts',
  'mobile-first',
  'QR-code entry route placeholders',
  'privacy-safe singer matching preview',
  'search debouncing preview',
  'does not submit requests'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Request web shell doc is missing Wave 7A phrase: $requiredPhrase"
  }
}

Write-Host 'Request web shell smoke test passed: project, mobile shell, branding, QR routes, singer entry, lookup preview, matching preview, search preview, debounce preview, and safety markers are present.'
