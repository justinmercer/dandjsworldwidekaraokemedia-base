
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/windows-host-output-controls.md',
  'host/windows-host-shell/demo-data/output-controls-demo-fixtures.json'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing output controls file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/demo-data/output-controls-demo-fixtures.json') -Raw | ConvertFrom-Json

foreach ($guard in @(
  'enumeratesDevices',
  'selectsRealOutputDevice',
  'accessesMicrophone',
  'startsRecording',
  'playsAudio',
  'readsMediaFiles',
  'writesControlState'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Output controls fixture guard must remain false: $guard"
  }
}

$manifest = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/host-shell.manifest.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'enumeratesDevices',
  'selectsRealOutputDevice',
  'accessesMicrophone',
  'startsRecording',
  'playsAudio',
  'readsMediaFiles',
  'writesControlState'
)) {
  if ($manifest.hostShellFeatures.outputControlsShell.$guard -ne $false) {
    throw "Output controls manifest guard must remain false: $guard"
  }
}

$index = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/index.html') -Raw
foreach ($requiredPhrase in @(
  'Output Controls',
  'Output-device selection',
  'Microphone-recording placeholders',
  'Key and tempo controls',
  'Progress and end-of-track preview',
  'Filler hooks',
  'Output Control Preview'
)) {
  if ($index -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell is missing Wave 6B phrase: $requiredPhrase"
  }
}

$appScript = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/app.js') -Raw
foreach ($requiredPhrase in @(
  'appendOutputControlsAudit',
  'showOutputControlPreview',
  'outputDeviceSelectionPreviewEnabled: true',
  'microphoneRecordingControlPlaceholdersEnabled: true',
  'keyChangeControlsPreviewEnabled: true',
  'tempoControlsPreviewEnabled: true',
  'resetToDefaultControlsPreviewEnabled: true',
  'playbackProgressPreviewEnabled: true',
  'remainingTimeDisplayPreviewEnabled: true',
  'endOfTrackDetectionPreviewEnabled: true',
  'fillerHooksPreviewEnabled: true',
  'fillerEnableDisablePreviewEnabled: true',
  'outputControlsEnumerateDevices: false',
  'outputControlsSelectRealDevice: false',
  'outputControlsAccessMicrophone: false',
  'outputControlsStartRecording: false',
  'outputControlsPlayAudio: false',
  'outputControlsReadMediaFiles: false',
  'outputControlsWriteState: false'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell app script is missing Wave 6B phrase: $requiredPhrase"
  }
}

Write-Host 'Host output controls smoke test passed: output, mic placeholders, tuning, progress, filler toggles, and safety markers are present.'
