
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/obs-replay-reliability-boundary-shell.md',
  'obs/companion/demo-data/companion-replay-reliability-fixtures.json',
  'obs/companion/src/reliability-replay-boundary.html'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing OBS Replay reliability boundary shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'obs/companion/demo-data/companion-replay-reliability-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'connectsToObs',
  'opensWebSocket',
  'sendsNetworkRequests',
  'callsReplay',
  'controlsPlayback',
  'writesRetryQueue',
  'writesAuditHistory',
  'writesRuntimeSettings',
  'startsTimers'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "OBS Replay reliability boundary guard must remain false: $guard"
  }
}

$html = Get-Content -LiteralPath (Join-Path $root 'obs/companion/src/reliability-replay-boundary.html') -Raw
foreach ($requiredPhrase in @(
  'Retry-safe event queue',
  'Backoff for companion outages',
  'Mock companion receiver',
  'Companion-isolation tests',
  'Companion failures never interrupt playback',
  'Existing separate-recording-computer topology',
  'OBS WebSocket port configuration as an operator setting',
  'Future Replay adapter interface',
  'Minimal Replay event fields',
  'Mock Replay adapter',
  'Retry expectations for Replay',
  'Failure-isolation rules for Replay',
  'No OBS connection',
  'No WebSocket calls',
  'No network requests',
  'No Replay calls',
  'No playback control',
  'No retry queue writes',
  'No audit writes',
  'No runtime settings writes',
  'No timers started'
)) {
  if ($html -notmatch [regex]::Escape($requiredPhrase)) {
    throw "OBS Replay reliability boundary shell is missing Wave 10B phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/obs-replay-reliability-boundary-shell.md') -Raw
foreach ($requiredPhrase in @(
  'Wave 10B adds',
  'retry-safe event queue preview',
  'backoff for companion outages preview',
  'mock companion receiver preview',
  'companion-isolation tests preview',
  'companion failures never interrupt playback rule',
  'existing separate-recording-computer topology documentation',
  'OBS WebSocket port configuration as an operator setting preview',
  'future Replay adapter interface preview',
  'minimal Replay event fields preview',
  'mock Replay adapter preview',
  'retry expectations for Replay preview',
  'failure-isolation rules for Replay preview'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "OBS Replay reliability boundary doc is missing Wave 10B phrase: $requiredPhrase"
  }
}

Write-Host 'OBS Replay reliability boundary smoke test passed: retry queue, backoff, mock receiver, isolation tests, playback-failure rule, recording topology, OBS port setting, Replay adapter, event fields, mock adapter, retry expectations, failure isolation, and safety markers are present.'
