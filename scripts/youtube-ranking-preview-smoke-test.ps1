
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/youtube-ranking-preview-controls-shell.md',
  'request/moderation/demo-data/youtube-ranking-preview-fixtures.json',
  'request/moderation/src/youtube-ranking-preview-controls.html'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing YouTube ranking preview file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'request/moderation/demo-data/youtube-ranking-preview-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'callsYouTubeDataApi',
  'performsExternalSearch',
  'embedsYouTubePlayer',
  'playsPreviewMedia',
  'pausesPreviewMedia',
  'downloadsMedia',
  'writesRuntimeCache',
  'writesQueueRecords'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "YouTube ranking preview fixture guard must remain false: $guard"
  }
}

$html = Get-Content -LiteralPath (Join-Path $root 'request/moderation/src/youtube-ranking-preview-controls.html') -Raw
foreach ($requiredPhrase in @(
  'Quota-friendly search behavior',
  'Candidate ranking',
  'Exact title matches',
  'Artist matches',
  'Karaoke keyword matches',
  'Instrumental keyword matches',
  'Down-rank tutorials or reactions',
  'Embedded YouTube preview player',
  'Preview play control',
  'Preview pause control',
  'No YouTube Data API calls',
  'No external search calls',
  'No embedded player runtime',
  'No play or pause media action'
)) {
  if ($html -notmatch [regex]::Escape($requiredPhrase)) {
    throw "YouTube ranking preview shell is missing Wave 8C phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/youtube-ranking-preview-controls-shell.md') -Raw
foreach ($requiredPhrase in @(
  'Wave 8C adds',
  'quota-friendly search behavior preview',
  'candidate ranking preview',
  'exact title match ranking',
  'artist match ranking',
  'karaoke keyword ranking',
  'instrumental keyword ranking',
  'tutorial or reaction down-ranking',
  'embedded YouTube preview player placeholder',
  'preview play control',
  'preview pause control'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "YouTube ranking preview doc is missing Wave 8C phrase: $requiredPhrase"
  }
}

Write-Host 'YouTube ranking preview smoke test passed: quota behavior, ranking, keyword scoring, down-ranking, player placeholder, preview controls, and safety markers are present.'
