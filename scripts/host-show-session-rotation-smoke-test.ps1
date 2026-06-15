
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/windows-host-show-session-rotation.md',
  'host/windows-host-shell/demo-data/show-session-rotation-demo-fixtures.json'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing show session rotation file: $path"
  }
}

$fixturePath = Join-Path $root 'host/windows-host-shell/demo-data/show-session-rotation-demo-fixtures.json'
$fixtures = Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json

if ($fixtures.writesShowSessionRecords -ne $false) {
  throw 'Show session rotation fixtures must not write show session records.'
}
if ($fixtures.writesRotationRecords -ne $false) {
  throw 'Show session rotation fixtures must not write rotation records.'
}

foreach ($requiredState in @(
  'temporary disable',
  'skip',
  'priority insert',
  'drag-and-drop ordering'
)) {
  if (-not ($fixtures.previewOnlyStates | Where-Object { $_ -eq $requiredState })) {
    throw "Missing preview-only rotation state: $requiredState"
  }
}

$manifest = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/host-shell.manifest.json') -Raw | ConvertFrom-Json
if ($manifest.hostShellFeatures.showSessionRotationShell.writesShowSessionRecords -ne $false) {
  throw 'Show session shell must not write show session records in Wave 5B.'
}
if ($manifest.hostShellFeatures.showSessionRotationShell.writesRotationRecords -ne $false) {
  throw 'Rotation shell must not write rotation records in Wave 5B.'
}
if ($manifest.hostShellFeatures.showSessionRotationShell.changesLiveRotation -ne $false) {
  throw 'Rotation shell must not change live rotation in Wave 5B.'
}

$index = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/index.html') -Raw
foreach ($requiredPhrase in @(
  'Show session model',
  'Start',
  'End',
  'Venue',
  'Rotation state',
  'Current singer',
  'Up next',
  'Rotation queue preview',
  'Temporary disable state',
  'Skip state',
  'Priority insert placeholder',
  'Drag-and-drop ordering placeholder',
  'Fair-round ordering rules',
  'Configurable rotation policies',
  'Estimated wait calculations',
  'Rotation Preview',
  'Rotation Policy Preview'
)) {
  if ($index -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell is missing Wave 5B show-session rotation phrase: $requiredPhrase"
  }
}

$appScript = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/app.js') -Raw
foreach ($requiredPhrase in @(
  'appendRotationAudit',
  'showRotationPreview',
  'showRotationPolicyPreview',
  'showSessionModelShellEnabled: true',
  'showSessionTimestampPreviewEnabled: true',
  'showSessionVenueAssociationPreviewEnabled: true',
  'activeRotationStatePreviewEnabled: true',
  'queuedSongsPerSingerPreviewEnabled: true',
  'currentSingerStatePreviewEnabled: true',
  'upNextStatePreviewEnabled: true',
  'temporaryDisableStatePreviewEnabled: true',
  'skipStatePreviewEnabled: true',
  'priorityInsertPreviewEnabled: true',
  'dragDropOrderingPreviewEnabled: true',
  'fairRoundOrderingRulesPreviewEnabled: true',
  'configurableRotationPoliciesPreviewEnabled: true',
  'estimatedWaitCalculationsPreviewEnabled: true',
  'rotationPreviewEnabled: true',
  'showSessionWritesRecords: false',
  'rotationWritesRecords: false',
  'rotationChangesLiveState: false'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell app script is missing Wave 5B show-session rotation phrase: $requiredPhrase"
  }
}

Write-Host 'Host show-session rotation smoke test passed: session model, rotation states, ordering rules, policies, wait estimates, and safe preview markers are present.'
