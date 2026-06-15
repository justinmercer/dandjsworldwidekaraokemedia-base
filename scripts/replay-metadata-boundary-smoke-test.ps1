
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/replay-metadata-boundary-shell.md',
  'obs/companion/demo-data/replay-metadata-boundary-fixtures.json',
  'obs/companion/src/replay-metadata-boundary.html'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing Replay metadata boundary shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'obs/companion/demo-data/replay-metadata-boundary-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'processesClips',
  'rendersLowerThirds',
  'renamesFiles',
  'writesFiles',
  'writesAuditHistory',
  'writesPerformanceEvents',
  'callsReplay',
  'sendsNetworkRequests',
  'controlsPlayback'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Replay metadata boundary guard must remain false: $guard"
  }
}

$html = Get-Content -LiteralPath (Join-Path $root 'obs/companion/src/replay-metadata-boundary.html') -Raw
foreach ($requiredPhrase in @(
  'Future clip-processing status placeholder',
  'Future lower-third metadata placeholder',
  'Future filename metadata placeholder',
  'Performance-event audit history',
  'Performance-event tests',
  'Replay integration boundary',
  'No clip processing',
  'No lower-third rendering',
  'No file renaming',
  'No file writes',
  'No audit writes',
  'No performance-event writes',
  'No Replay calls',
  'No network requests',
  'No playback control'
)) {
  if ($html -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Replay metadata boundary shell is missing Wave 10C phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/replay-metadata-boundary-shell.md') -Raw
foreach ($requiredPhrase in @(
  'Wave 10C adds',
  'future clip-processing status placeholder',
  'future lower-third metadata placeholder',
  'future filename metadata placeholder',
  'performance-event audit history preview',
  'performance-event tests preview',
  'Replay integration boundary documentation'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Replay metadata boundary doc is missing Wave 10C phrase: $requiredPhrase"
  }
}

Write-Host 'Replay metadata boundary smoke test passed: clip status, lower-third metadata, filename metadata, audit preview, tests, Replay boundary, and safety markers are present.'
