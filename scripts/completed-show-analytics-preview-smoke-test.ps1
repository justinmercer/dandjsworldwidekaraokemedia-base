
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/completed-show-analytics-preview-shell.md',
  'analytics/demo-data/completed-show-analytics-fixtures.json',
  'analytics/src/completed-show-analytics-preview.html'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing completed-show analytics preview shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'analytics/demo-data/completed-show-analytics-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'generatesAnalytics',
  'readsCompletedShows',
  'readsSingerDatabase',
  'readsRequestDatabase',
  'exportsCsv',
  'sendsTelemetry',
  'makesNetworkRequests',
  'writesFiles'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Completed-show analytics preview guard must remain false: $guard"
  }
}

$html = Get-Content -LiteralPath (Join-Path $root 'analytics/src/completed-show-analytics-preview.html') -Raw
foreach ($requiredPhrase in @(
  'Completed-show analytics model',
  'Singer-count metrics',
  'Request-volume metrics',
  'Most-requested-song metrics',
  'Repeat-singer metrics',
  'Average-wait metrics',
  'Venue trend metrics',
  'Library-gap metrics',
  'No real analytics generation',
  'No completed-show database reads',
  'No singer database reads',
  'No request database reads',
  'No CSV export',
  'No telemetry',
  'No network request',
  'No filesystem writes beyond fixtures'
)) {
  if ($html -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Completed-show analytics preview shell is missing Wave 13A phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/completed-show-analytics-preview-shell.md') -Raw
foreach ($requiredPhrase in @(
  'Wave 13A adds',
  'completed-show analytics model preview',
  'singer-count metrics preview',
  'request-volume metrics preview',
  'most-requested-song metrics preview',
  'repeat-singer metrics preview',
  'average-wait metrics preview',
  'venue trend metrics preview',
  'library-gap metrics preview'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Completed-show analytics preview doc is missing Wave 13A phrase: $requiredPhrase"
  }
}

Write-Host 'Completed-show analytics preview smoke test passed: completed-show model, singer count, request volume, most requested song, repeat singer, average wait, venue trend, library gap, and safety markers are present.'
