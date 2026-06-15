
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/windows-host-rotation-actions-session-notes.md',
  'host/windows-host-shell/demo-data/rotation-actions-demo-fixtures.json'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing rotation action session notes file: $path"
  }
}

$fixturePath = Join-Path $root 'host/windows-host-shell/demo-data/rotation-actions-demo-fixtures.json'
$fixtures = Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json

if ($fixtures.writesRotationRecords -ne $false) {
  throw 'Rotation action fixtures must not write rotation records.'
}
if ($fixtures.writesCompletedPerformanceRecords -ne $false) {
  throw 'Rotation action fixtures must not write completed performance records.'
}
if ($fixtures.writesSessionSnapshots -ne $false) {
  throw 'Rotation action fixtures must not write session snapshots.'
}
if ($fixtures.persistsAutosave -ne $false) {
  throw 'Autosave preview must not persist changes in Wave 5C.'
}

foreach ($requiredAction in @(
  'call-singer',
  'singer-not-ready',
  'move-to-next-round',
  'remove-from-tonight',
  'restore-singer'
)) {
  if (-not ($fixtures.actions | Where-Object { $_.id -eq $requiredAction -and $_.changesLiveRotation -eq $false })) {
    throw "Missing safe rotation action fixture: $requiredAction"
  }
}

$manifest = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/host-shell.manifest.json') -Raw | ConvertFrom-Json
if ($manifest.hostShellFeatures.rotationActionSessionNotesShell.changesLiveRotation -ne $false) {
  throw 'Rotation action shell must not change live rotation in Wave 5C.'
}
if ($manifest.hostShellFeatures.rotationActionSessionNotesShell.writesCompletedPerformanceRecords -ne $false) {
  throw 'Rotation action shell must not write completed performance records in Wave 5C.'
}
if ($manifest.hostShellFeatures.rotationActionSessionNotesShell.writesSessionSnapshots -ne $false) {
  throw 'Rotation action shell must not write session snapshots in Wave 5C.'
}
if ($manifest.hostShellFeatures.rotationActionSessionNotesShell.persistsAutosave -ne $false) {
  throw 'Rotation action shell must not persist autosave in Wave 5C.'
}

$index = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/index.html') -Raw
foreach ($requiredPhrase in @(
  'Host rotation actions',
  'Call singer',
  'Singer not ready',
  'Move to next round',
  'Remove from tonight',
  'Restore singer',
  'Completed performance record preview',
  'Show notes and session snapshots',
  'Manual Session Snapshot Preview',
  'Autosave Trigger Preview',
  'Rotation Action Preview'
)) {
  if ($index -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell is missing Wave 5C rotation action phrase: $requiredPhrase"
  }
}

$appScript = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/app.js') -Raw
foreach ($requiredPhrase in @(
  'showRotationActionPreview',
  'showSessionSnapshotPreview',
  'showAutosavePreview',
  'noteShowNotesEdited',
  'callSingerActionPreviewEnabled: true',
  'singerNotReadyActionPreviewEnabled: true',
  'moveToNextRoundActionPreviewEnabled: true',
  'removeFromTonightActionPreviewEnabled: true',
  'restoreSingerActionPreviewEnabled: true',
  'completedPerformanceRecordPreviewEnabled: true',
  'showNotesFieldPreviewEnabled: true',
  'manualSessionSnapshotPreviewEnabled: true',
  'autosaveTriggerPreviewEnabled: true',
  'rotationActionChangesLiveState: false',
  'completedPerformanceWritesRecords: false',
  'showNotesWritesRecords: false',
  'manualSessionSnapshotWritesFiles: false',
  'autosavePersistsChanges: false'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell app script is missing Wave 5C rotation action phrase: $requiredPhrase"
  }
}

Write-Host 'Host rotation actions/session notes smoke test passed: action previews, completed-performance preview, notes, snapshot, autosave, and safety markers are present.'
