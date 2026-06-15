
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/reliability-scenario-preview-shell.md',
  'qa/demo-data/reliability-scenario-preview-fixtures.json',
  'qa/src/reliability-scenario-preview.html'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing reliability scenario preview shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'qa/demo-data/reliability-scenario-preview-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'probesStorage',
  'runsRestartCommand',
  'runsShutdownCommand',
  'connectsObs',
  'connectsReplay',
  'probesMonitors',
  'readsCatalogDatabase',
  'readsShowDatabase',
  'makesNetworkRequests',
  'writesFiles'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Reliability scenario preview guard must remain false: $guard"
  }
}

$html = Get-Content -LiteralPath (Join-Path $root 'qa/src/reliability-scenario-preview.html') -Raw
foreach ($requiredPhrase in @(
  'Insufficient-storage test scenario',
  'Host-restart recovery test scenario',
  'Unclean-shutdown recovery test scenario',
  'OBS companion outage test scenario',
  'Replay adapter outage test scenario',
  'External-monitor disconnect test scenario',
  'Empty-library startup test scenario',
  'Empty-show startup test scenario',
  'No storage probing',
  'No restart command',
  'No shutdown command',
  'No OBS connection',
  'No Replay connection',
  'No monitor probing',
  'No catalog database reads',
  'No show database reads',
  'No network request',
  'No filesystem writes beyond fixtures'
)) {
  if ($html -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Reliability scenario preview shell is missing Wave 13C phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/reliability-scenario-preview-shell.md') -Raw
foreach ($requiredPhrase in @(
  'Wave 13C adds',
  'insufficient-storage test scenario preview',
  'host-restart recovery test scenario preview',
  'unclean-shutdown recovery test scenario preview',
  'OBS companion outage test scenario preview',
  'Replay adapter outage test scenario preview',
  'external-monitor disconnect test scenario preview',
  'empty-library startup test scenario preview',
  'empty-show startup test scenario preview'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Reliability scenario preview doc is missing Wave 13C phrase: $requiredPhrase"
  }
}

Write-Host 'Reliability scenario preview smoke test passed: insufficient storage, host restart, unclean shutdown, OBS outage, Replay outage, external monitor disconnect, empty library, empty show, and safety markers are present.'
