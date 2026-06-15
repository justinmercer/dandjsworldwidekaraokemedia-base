
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/mobile-pwa-kiosk-shell.md',
  'request/web-app/demo-data/mobile-pwa-kiosk-fixtures.json',
  'request/web-app/src/manifest.webmanifest',
  'request/web-app/src/offline.html',
  'request/web-app/src/static-cache-plan.json',
  'request/web-app/src/index.html',
  'request/web-app/src/app.js',
  'request/web-app/src/styles.css'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing mobile/PWA/kiosk shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'request/web-app/demo-data/mobile-pwa-kiosk-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'registersServiceWorker',
  'performsOfflineRuntimeCaching',
  'installsPwa',
  'callsServerApis',
  'storesPersonalData',
  'changesConnectionMode'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Mobile/PWA/kiosk fixture guard must remain false: $guard"
  }
}

$manifest = Get-Content -LiteralPath (Join-Path $root 'request/web-app/src/manifest.webmanifest') -Raw | ConvertFrom-Json
if ($manifest.name -ne "D & J's Karaoke Requests") {
  throw 'Manifest name mismatch.'
}
if ($manifest.display -ne 'standalone') {
  throw 'Manifest display mode must be standalone metadata.'
}

$cachePlan = Get-Content -LiteralPath (Join-Path $root 'request/web-app/src/static-cache-plan.json') -Raw | ConvertFrom-Json
if ($cachePlan.runtimeCachingEnabled -ne $false) {
  throw 'Runtime caching must remain disabled in Wave 7D.'
}
if ($cachePlan.serviceWorkerRegistered -ne $false) {
  throw 'Service worker registration must remain disabled in Wave 7D.'
}

$index = Get-Content -LiteralPath (Join-Path $root 'request/web-app/src/index.html') -Raw
foreach ($requiredPhrase in @(
  'Connection state',
  'Offline shell preview',
  'Installable PWA metadata preview',
  'Static shell cache plan',
  'No service worker is registered',
  'iPhone SE',
  'iPhone 15',
  'Pixel 7',
  'Galaxy S22',
  'Accessibility checks',
  'Large tap targets are styled',
  'Shared tablet route',
  'Kiosk controls',
  'Clear session preview',
  'No runtime offline caching'
)) {
  if ($index -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Mobile/PWA/kiosk shell is missing Wave 7D phrase: $requiredPhrase"
  }
}

$appScript = Get-Content -LiteralPath (Join-Path $root 'request/web-app/src/app.js') -Raw
foreach ($requiredPhrase in @(
  'registersServiceWorker: false',
  'performsOfflineRuntimeCaching: false',
  'installsPwa: false',
  'Nothing was submitted'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Mobile/PWA/kiosk script is missing Wave 7D phrase: $requiredPhrase"
  }
}

$styles = Get-Content -LiteralPath (Join-Path $root 'request/web-app/src/styles.css') -Raw
foreach ($requiredPhrase in @(
  'min-height: 44px',
  '.kiosk-controls',
  'min-height: 64px',
  '@media (max-width: 430px)'
)) {
  if ($styles -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Mobile/PWA/kiosk styles are missing Wave 7D phrase: $requiredPhrase"
  }
}

Write-Host 'Mobile/PWA/kiosk smoke test passed: connection state, static cache plan, PWA metadata, mobile fixtures, accessibility markers, large tap targets, shared tablet route, kiosk controls, and safety markers are present.'
