
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/windows-host-troubleshooting-checks.md',
  'host/windows-host-shell/demo-data/host-checks-demo-fixtures.json'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing host checks file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/demo-data/host-checks-demo-fixtures.json') -Raw | ConvertFrom-Json

foreach ($guard in @(
  'runsRealPlayback',
  'controlsLiveShow',
  'changesDisplayState',
  'reconnectsMonitors',
  'registersKeyboardHooks',
  'readsMediaFiles',
  'writesRuntimeState'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Host checks fixture guard must remain false: $guard"
  }
}

$manifest = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/host-shell.manifest.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'runsRealPlayback',
  'controlsLiveShow',
  'changesDisplayState',
  'reconnectsMonitors',
  'registersKeyboardHooks',
  'readsMediaFiles',
  'writesRuntimeState'
)) {
  if ($manifest.hostShellFeatures.hostChecksShell.$guard -ne $false) {
    throw "Host checks manifest guard must remain false: $guard"
  }
}

$index = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/index.html') -Raw
foreach ($requiredPhrase in @(
  'Host Checks',
  'Playback-control tests',
  'External-display state tests',
  'Monitor reconnect tests',
  'Keyboard shortcut tests',
  'Live-show troubleshooting',
  'Host Checks Preview'
)) {
  if ($index -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell is missing Wave 6E phrase: $requiredPhrase"
  }
}

$appScript = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/app.js') -Raw
foreach ($requiredPhrase in @(
  'appendHostChecksAudit',
  'showHostChecksPreview',
  'playbackControlTestsPreviewEnabled: true',
  'externalDisplayStateTestsPreviewEnabled: true',
  'monitorReconnectTestsPreviewEnabled: true',
  'keyboardShortcutTestsPreviewEnabled: true',
  'liveShowTroubleshootingDocsEnabled: true',
  'hostChecksRunRealPlayback: false',
  'hostChecksControlLiveShow: false',
  'hostChecksChangeDisplayState: false',
  'hostChecksReconnectMonitors: false',
  'hostChecksRegisterKeyboardHooks: false',
  'hostChecksReadMediaFiles: false',
  'hostChecksWriteRuntimeState: false'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell app script is missing Wave 6E phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/windows-host-troubleshooting-checks.md') -Raw
foreach ($requiredPhrase in @(
  'Operator troubleshooting checklist',
  'Wave 6E does not run real playback',
  'register global keyboard hooks',
  'write runtime state'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Troubleshooting doc is missing Wave 6E phrase: $requiredPhrase"
  }
}

Write-Host 'Host checks smoke test passed: control tests, display-state tests, reconnect tests, shortcut tests, troubleshooting docs, and safety markers are present.'
