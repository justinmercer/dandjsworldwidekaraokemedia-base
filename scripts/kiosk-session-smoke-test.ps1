
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/kiosk-session-shell.md',
  'docs/development/venue-router-local-request-mode.md',
  'request/web-app/demo-data/kiosk-session-fixtures.json',
  'request/web-app/demo-data/request-web-smoke-fixtures.json',
  'request/web-app/src/kiosk-responsive-test-plan.json',
  'request/web-app/src/index.html',
  'request/web-app/src/app.js',
  'request/web-app/src/styles.css'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing kiosk/session shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'request/web-app/demo-data/kiosk-session-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'performsRealTimeout',
  'resetsKioskSession',
  'generatesQrCodes',
  'changesRouterSettings',
  'callsServerApis',
  'storesPersonalData',
  'submitsRequests'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Kiosk session fixture guard must remain false: $guard"
  }
}

$requestWebSmoke = Get-Content -LiteralPath (Join-Path $root 'request/web-app/demo-data/request-web-smoke-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'callsServerApis',
  'writesQueueRecords',
  'writesSingerRecords',
  'storesPersonalData'
)) {
  if ($requestWebSmoke.$guard -ne $false) {
    throw "Request web smoke fixture guard must remain false: $guard"
  }
}

$responsivePlan = Get-Content -LiteralPath (Join-Path $root 'request/web-app/src/kiosk-responsive-test-plan.json') -Raw | ConvertFrom-Json
if ($responsivePlan.runsBrowserAutomation -ne $false) {
  throw 'Kiosk responsive plan must not run browser automation in Wave 7E.'
}

$index = Get-Content -LiteralPath (Join-Path $root 'request/web-app/src/index.html') -Raw
foreach ($requiredPhrase in @(
  'Kiosk session safety',
  'Idle timeout preview',
  'Automatic reset preview',
  'QR fallback preview',
  'Kiosk responsive test fixtures',
  'Tablet portrait',
  'Tablet landscape',
  'Small kiosk',
  'Large kiosk',
  'Venue-router local mode docs',
  'No kiosk data reset',
  'No router setting changes'
)) {
  if ($index -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Kiosk/session shell is missing Wave 7E phrase: $requiredPhrase"
  }
}

$appScript = Get-Content -LiteralPath (Join-Path $root 'request/web-app/src/app.js') -Raw
foreach ($requiredPhrase in @(
  'performsRealTimeout: false',
  'resetsKioskSession: false',
  'generatesQrCodes: false',
  'changesRouterSettings: false',
  'kioskSessionSafety'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Kiosk/session script is missing Wave 7E phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/venue-router-local-request-mode.md') -Raw
foreach ($requiredPhrase in @(
  'local request-mode router flow',
  'does not change any network device',
  'Local mode label',
  'Cloud mode label',
  'does not open router ports',
  'configure DNS'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Venue router doc is missing Wave 7E phrase: $requiredPhrase"
  }
}

Write-Host 'Kiosk/session smoke test passed: idle timeout preview, automatic reset preview, QR fallback, kiosk responsive fixtures, request-web smoke fixtures, venue-router docs, and safety markers are present.'
