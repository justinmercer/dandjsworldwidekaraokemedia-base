
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/youtube-candidate-actions-boundary-shell.md',
  'request/moderation/demo-data/youtube-candidate-actions-fixtures.json',
  'request/moderation/src/youtube-candidate-actions-boundary.html'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing YouTube candidate action boundary file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'request/moderation/demo-data/youtube-candidate-actions-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'callsYouTubeDataApi',
  'opensYouTube',
  'importsApprovedCopy',
  'copiesFiles',
  'movesFiles',
  'downloadsMedia',
  'writesRuntimeCache',
  'writesAnalytics',
  'writesQueueRecords',
  'writesSingerRecords',
  'writesDatabaseRecords'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "YouTube candidate action fixture guard must remain false: $guard"
  }
}

$html = Get-Content -LiteralPath (Join-Path $root 'request/moderation/src/youtube-candidate-actions-boundary.html') -Raw
foreach ($requiredPhrase in @(
  'Channel display',
  'Mark preferred candidate action',
  'Open in YouTube action',
  'Approved local copy still needed state',
  'Approved-copy import action preview',
  'Source-note capture',
  'Search-result cache expiry',
  'Missing-song analytics',
  'Missing-song workflow tests',
  'YouTube-disabled fallback tests',
  'Safe YouTube-preview boundary',
  'No real YouTube API calls',
  'No opening YouTube',
  'No file imports',
  'No file copies',
  'No file moves',
  'No downloads'
)) {
  if ($html -notmatch [regex]::Escape($requiredPhrase)) {
    throw "YouTube candidate action boundary shell is missing Wave 8D phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/youtube-candidate-actions-boundary-shell.md') -Raw
foreach ($requiredPhrase in @(
  'Wave 8D adds',
  'channel display preview',
  'mark preferred candidate action preview',
  'open in YouTube action preview',
  'approved local copy still needed state preview',
  'approved-copy import action preview',
  'source-note capture preview',
  'search-result cache expiry preview',
  'missing-song analytics preview',
  'missing-song workflow tests preview',
  'YouTube-disabled fallback tests preview',
  'safe YouTube-preview boundary documentation'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "YouTube candidate action boundary doc is missing Wave 8D phrase: $requiredPhrase"
  }
}

Write-Host 'YouTube candidate action boundary smoke test passed: channel display, preferred candidate, open-in-YouTube placeholder, local-copy-needed state, authorized-copy import shell, notes, expiry, analytics, workflow tests, fallback tests, and safety markers are present.'
