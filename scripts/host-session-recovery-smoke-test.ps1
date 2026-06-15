
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/windows-host-session-recovery.md',
  'host/windows-host-shell/demo-data/session-recovery-demo-fixtures.json'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing session recovery file: $path"
  }
}

$fixturePath = Join-Path $root 'host/windows-host-shell/demo-data/session-recovery-demo-fixtures.json'
$fixtures = Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json

if ($fixtures.writesSessionRecords -ne $false) {
  throw 'Session recovery fixtures must not write session records.'
}
if ($fixtures.writesRecoveryFiles -ne $false) {
  throw 'Session recovery fixtures must not write recovery files.'
}
if ($fixtures.restoresRealSession -ne $false) {
  throw 'Session recovery fixtures must not restore real sessions.'
}
if ($fixtures.discardsRealSession -ne $false) {
  throw 'Session recovery fixtures must not discard real sessions.'
}

foreach ($requiredTest in @(
  'rotation-rule tests',
  'estimated-wait tests',
  'crash-recovery tests'
)) {
  if (-not ($fixtures.testCoveragePreview | Where-Object { $_ -eq $requiredTest })) {
    throw "Missing recovery test marker: $requiredTest"
  }
}

$manifest = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/host-shell.manifest.json') -Raw | ConvertFrom-Json
if ($manifest.hostShellFeatures.sessionRecoveryShell.writesSessionRecords -ne $false) {
  throw 'Session recovery shell must not write session records in Wave 5D.'
}
if ($manifest.hostShellFeatures.sessionRecoveryShell.writesRecoveryFiles -ne $false) {
  throw 'Session recovery shell must not write recovery files in Wave 5D.'
}
if ($manifest.hostShellFeatures.sessionRecoveryShell.restoresRealSession -ne $false) {
  throw 'Session recovery shell must not restore real sessions in Wave 5D.'
}
if ($manifest.hostShellFeatures.sessionRecoveryShell.discardsRealSession -ne $false) {
  throw 'Session recovery shell must not discard real sessions in Wave 5D.'
}

$index = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/index.html') -Raw
foreach ($requiredPhrase in @(
  'Session Recovery',
  'Unclean shutdown recovery prompt',
  'Restore or discard stale session',
  'Preview restore session',
  'Preview discard stale session',
  'Rotation-rule tests',
  'Estimated-wait tests',
  'Crash-recovery tests',
  'Restore Session Preview',
  'Discard Stale Session Preview'
)) {
  if ($index -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell is missing Wave 5D session recovery phrase: $requiredPhrase"
  }
}

$appScript = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/app.js') -Raw
foreach ($requiredPhrase in @(
  'appendSessionRecoveryAudit',
  'showRestoreSessionPreview',
  'showDiscardSessionPreview',
  'uncleanShutdownRecoveryPromptPreviewEnabled: true',
  'restoreSessionFlowPreviewEnabled: true',
  'discardStaleSessionFlowPreviewEnabled: true',
  'rotationRuleTestsPreviewEnabled: true',
  'estimatedWaitTestsPreviewEnabled: true',
  'crashRecoveryTestsPreviewEnabled: true',
  'sessionRecoveryWritesRecords: false',
  'sessionRecoveryWritesFiles: false',
  'sessionRecoveryRestoresRealSession: false',
  'sessionRecoveryDiscardsRealSession: false'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell app script is missing Wave 5D session recovery phrase: $requiredPhrase"
  }
}

Write-Host 'Host session recovery smoke test passed: unclean shutdown prompt, restore/discard preview, recovery test markers, and safety markers are present.'
