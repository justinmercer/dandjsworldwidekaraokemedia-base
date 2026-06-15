
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/request-workflow-shell.md',
  'request/web-app/demo-data/request-workflow-fixtures.json',
  'request/web-app/src/index.html',
  'request/web-app/src/app.js',
  'request/web-app/src/styles.css'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing request workflow shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'request/web-app/demo-data/request-workflow-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'submitsRequests',
  'callsServerApis',
  'writesQueueRecords',
  'writesSingerRecords',
  'searchesRealCatalog',
  'storesPersonalData',
  'moderatesRequests',
  'sendsNotifications'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Request workflow fixture guard must remain false: $guard"
  }
}

$index = Get-Content -LiteralPath (Join-Path $root 'request/web-app/src/index.html') -Raw
foreach ($requiredPhrase in @(
  'Try a title, artist, or duet keyword',
  'Recent songs',
  'Popular songs',
  'Favourites',
  'Singer history',
  'Duet:',
  'Alternate versions',
  'Request draft',
  'Key change',
  'Duet partner',
  'Preview request',
  'No live request submission'
)) {
  if ($index -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Request workflow shell is missing Wave 7B phrase: $requiredPhrase"
  }
}

$appScript = Get-Content -LiteralPath (Join-Path $root 'request/web-app/src/app.js') -Raw
foreach ($requiredPhrase in @(
  'writesQueueRecords: false',
  'sendsNotifications: false',
  'Draft preview only',
  'Nothing was submitted',
  'keyChangePreviewSelect',
  'duetPartnerInput',
  'requestPreviewButton'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Request workflow script is missing Wave 7B phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/request-workflow-shell.md') -Raw
foreach ($requiredPhrase in @(
  'Wave 7B expands',
  'search empty-state copy',
  'recent-song browsing preview',
  'popular-song browsing preview',
  'favourites browsing preview',
  'singer-history browsing preview',
  'duet indicators',
  'alternate-version display',
  'request submission preview',
  'key-change request preview',
  'duet-partner request preview'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Request workflow doc is missing Wave 7B phrase: $requiredPhrase"
  }
}

Write-Host 'Request workflow smoke test passed: empty states, browse previews, duet indicators, alternate versions, draft submission preview, key-change preview, duet-partner preview, and safety markers are present.'
