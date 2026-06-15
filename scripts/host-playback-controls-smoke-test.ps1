
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/windows-host-playback-controls.md',
  'host/windows-host-shell/demo-data/playback-controls-demo-fixtures.json'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing playback controls file: $path"
  }
}

$fixturePath = Join-Path $root 'host/windows-host-shell/demo-data/playback-controls-demo-fixtures.json'
$fixtures = Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json

if ($fixtures.startsAudio -ne $false) {
  throw 'Playback fixtures must not start audio.'
}
if ($fixtures.readsMediaFiles -ne $false) {
  throw 'Playback fixtures must not read media files.'
}
if ($fixtures.changesAudioOutput -ne $false) {
  throw 'Playback fixtures must not change audio output.'
}
if ($fixtures.writesPlaybackState -ne $false) {
  throw 'Playback fixtures must not write playback state.'
}

foreach ($requiredControl in @(
  'play',
  'pause',
  'stop',
  'next',
  'previous-safe',
  'fade-out',
  'emergency-skip',
  'volume'
)) {
  if (-not ($fixtures.controls | Where-Object { $_.id -eq $requiredControl })) {
    throw "Missing playback control fixture: $requiredControl"
  }
}

$manifest = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/host-shell.manifest.json') -Raw | ConvertFrom-Json
if ($manifest.hostShellFeatures.playbackControlsShell.startsAudio -ne $false) {
  throw 'Playback shell must not start audio in Wave 6A.'
}
if ($manifest.hostShellFeatures.playbackControlsShell.readsMediaFiles -ne $false) {
  throw 'Playback shell must not read media files in Wave 6A.'
}
if ($manifest.hostShellFeatures.playbackControlsShell.changesAudioOutput -ne $false) {
  throw 'Playback shell must not change audio output in Wave 6A.'
}
if ($manifest.hostShellFeatures.playbackControlsShell.writesPlaybackState -ne $false) {
  throw 'Playback shell must not write playback state in Wave 6A.'
}

$index = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/index.html') -Raw
foreach ($requiredPhrase in @(
  'Playback',
  'Local playback engine decision',
  'Local playback state',
  'Playback control previews',
  'Play',
  'Pause',
  'Stop',
  'Next',
  'Previous where safe',
  'Fade out',
  'Emergency skip',
  'Volume preview',
  'Playback Control Preview'
)) {
  if ($index -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell is missing Wave 6A playback phrase: $requiredPhrase"
  }
}

$appScript = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/app.js') -Raw
foreach ($requiredPhrase in @(
  'appendPlaybackAudit',
  'showPlaybackControlPreview',
  'showVolumePreview',
  'playbackEngineDecisionDocumented: true',
  'localPlaybackStatePreviewEnabled: true',
  'playActionPreviewEnabled: true',
  'pauseActionPreviewEnabled: true',
  'stopActionPreviewEnabled: true',
  'nextActionPreviewEnabled: true',
  'previousWhereSafeActionPreviewEnabled: true',
  'fadeOutActionPreviewEnabled: true',
  'emergencySkipActionPreviewEnabled: true',
  'volumeControlsPreviewEnabled: true',
  'playbackStartsAudio: false',
  'playbackReadsMediaFiles: false',
  'playbackChangesAudioOutput: false',
  'playbackWritesState: false'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell app script is missing Wave 6A playback phrase: $requiredPhrase"
  }
}

Write-Host 'Host playback controls smoke test passed: playback engine docs, state preview, controls, volume, and safety markers are present.'
