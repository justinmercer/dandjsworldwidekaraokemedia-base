
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/missing-song-safe-youtube-shell.md',
  'request/moderation/demo-data/missing-song-safe-youtube-fixtures.json',
  'request/moderation/src/missing-song-safe-youtube.html'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing missing-song safe YouTube shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'request/moderation/demo-data/missing-song-safe-youtube-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'callsYouTubeDataApi',
  'performsExternalSearch',
  'embedsYouTubePlayer',
  'downloadsMedia',
  'cachesRuntimeResults',
  'writesQueueRecords',
  'writesSingerRecords',
  'writesAuditHistory',
  'updatesGuestStatus',
  'modifiesVenueDefaultLimits'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Missing-song safe YouTube fixture guard must remain false: $guard"
  }
}

$html = Get-Content -LiteralPath (Join-Path $root 'request/moderation/src/missing-song-safe-youtube.html') -Raw
foreach ($requiredPhrase in @(
  'Venue default request limits',
  'Request-status updates back to guests',
  'Request audit history',
  'Missing-song state',
  'Missing-song review queue',
  'Authorized catalog first',
  'Search the authorized catalog before any external search',
  'Official YouTube Data API configuration placeholders',
  'Official YouTube search integration shell',
  'Limited to host-reviewed missing-song workflows',
  'Cached search results preview only',
  'No real YouTube API calls are made',
  'No external search calls',
  'No downloads'
)) {
  if ($html -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Missing-song safe YouTube shell is missing Wave 8B phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/missing-song-safe-youtube-shell.md') -Raw
foreach ($requiredPhrase in @(
  'Wave 8B adds',
  'venue default request limits preview',
  'request-status updates back to guests preview',
  'request audit history preview',
  'missing-song state preview',
  'missing-song review queue preview',
  'authorized catalog before external search rule',
  'official YouTube Data API configuration placeholders',
  'official YouTube search integration shell',
  'host-reviewed missing-song workflow limit',
  'cached search results preview'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Missing-song safe YouTube doc is missing Wave 8B phrase: $requiredPhrase"
  }
}

Write-Host 'Missing-song safe YouTube smoke test passed: missing-song state, review queue, catalog-first rule, YouTube placeholders/search shell, cached results preview, and safety markers are present.'
