
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/request-session-status-shell.md',
  'request/web-app/demo-data/request-session-status-fixtures.json',
  'request/web-app/src/index.html',
  'request/web-app/src/app.js',
  'request/web-app/src/styles.css'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing request session/status shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'request/web-app/demo-data/request-session-status-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'submitsRequests',
  'callsServerApis',
  'writesQueueRecords',
  'writesSingerRecords',
  'storesPersonalData',
  'sendsNotifications',
  'changesNetworkMode'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Request session/status fixture guard must remain false: $guard"
  }
}

$index = Get-Content -LiteralPath (Join-Path $root 'request/web-app/src/index.html') -Raw
foreach ($requiredPhrase in @(
  'Optional note',
  'Request confirmation',
  'My request list',
  'Preview limit: 2 active requests',
  'Estimated wait: about 3 singers',
  'Draft preview',
  'Waiting preview',
  'Called preview',
  'Complete preview',
  'Venue access code',
  'Local network mode preview',
  'Cloud mode preview',
  'Automatic fallback message preview only',
  'No venue access-code validation',
  'No connection mode changes'
)) {
  if ($index -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Request session/status shell is missing Wave 7C phrase: $requiredPhrase"
  }
}

$appScript = Get-Content -LiteralPath (Join-Path $root 'request/web-app/src/app.js') -Raw
foreach ($requiredPhrase in @(
  'validatesVenueAccessCodes: false',
  'changesNetworkMode: false',
  'requestNoteInput',
  'venueAccessCodeInput',
  'Nothing was submitted',
  'No validation was performed',
  'No network mode was changed'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Request session/status script is missing Wave 7C phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/request-session-status-shell.md') -Raw
foreach ($requiredPhrase in @(
  'Wave 7C expands',
  'optional request note preview',
  'request confirmation preview',
  'personal request list preview',
  'request status labels',
  'estimated wait display',
  'request-limit messaging',
  'venue-access-code entry preview',
  'local-network mode label',
  'cloud mode label',
  'automatic mode fallback messaging'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Request session/status doc is missing Wave 7C phrase: $requiredPhrase"
  }
}

Write-Host 'Request session/status smoke test passed: note preview, confirmation, personal list, statuses, wait display, limit messaging, access-code entry, local/cloud labels, fallback messaging, and safety markers are present.'
