
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/obs-companion-event-export-shell.md',
  'obs/companion/demo-data/performance-event-export-fixtures.json',
  'obs/companion/src/performance-event-export.html'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing OBS companion event export shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'obs/companion/demo-data/performance-event-export-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'connectsToObs',
  'opensWebSocket',
  'sendsNetworkRequests',
  'callsReplay',
  'controlsPlayback',
  'writesQueue',
  'writesPerformanceEvents',
  'writesAuditHistory',
  'storesSecrets'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "OBS companion event export fixture guard must remain false: $guard"
  }
}

$html = Get-Content -LiteralPath (Join-Path $root 'obs/companion/src/performance-event-export.html') -Raw
foreach ($requiredPhrase in @(
  'Performance-start event payload',
  'Performance-end event payload',
  'Singer, song, artist, venue, show ID, and timestamps',
  'Configurable companion endpoint settings',
  'Optional OBS event export module',
  'Event-export enable and disable switch',
  'Export connection status',
  'No OBS connection',
  'No WebSocket calls',
  'No network requests',
  'No Replay calls',
  'No playback control',
  'No queue writes',
  'No performance-event writes',
  'No audit writes',
  'No secrets'
)) {
  if ($html -notmatch [regex]::Escape($requiredPhrase)) {
    throw "OBS companion event export shell is missing Wave 10A phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/obs-companion-event-export-shell.md') -Raw
foreach ($requiredPhrase in @(
  'Wave 10A adds',
  'performance-start event payload preview',
  'performance-end event payload preview',
  'singer name, song, artist, venue, show ID, and timestamp fields',
  'configurable companion endpoint settings preview',
  'optional OBS event export module shell',
  'event-export enable and disable switch preview',
  'export connection status preview'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "OBS companion event export doc is missing Wave 10A phrase: $requiredPhrase"
  }
}

Write-Host 'OBS companion event export smoke test passed: start/end payloads, required fields, endpoint settings, module shell, enable switch, status, and safety markers are present.'
