
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/windows-host-display-shell.md',
  'host/windows-host-shell/demo-data/display-shell-demo-fixtures.json'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing display shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/demo-data/display-shell-demo-fixtures.json') -Raw | ConvertFrom-Json

foreach ($guard in @(
  'opensRealPreviewWindow',
  'opensRealExternalWindow',
  'entersFullscreen',
  'enumeratesDisplays',
  'selectsDisplay',
  'clonesDisplay',
  'loadsBackgroundFiles',
  'usesCamera',
  'writesDisplayState'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Display shell fixture guard must remain false: $guard"
  }
}

$manifest = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/host-shell.manifest.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'opensRealPreviewWindow',
  'opensRealExternalWindow',
  'entersFullscreen',
  'enumeratesDisplays',
  'selectsDisplay',
  'clonesDisplay',
  'loadsBackgroundFiles',
  'usesCamera',
  'writesDisplayState'
)) {
  if ($manifest.hostShellFeatures.displayShell.$guard -ne $false) {
    throw "Display shell manifest guard must remain false: $guard"
  }
}

$index = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/index.html') -Raw
foreach ($requiredPhrase in @(
  'Audience Display',
  'Filler-audio volume preview',
  'Preview-window plumbing',
  'External display shell',
  'Now singing card',
  'Up-next card',
  'Welcome screen and announcements',
  'Audience Display Preview'
)) {
  if ($index -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell is missing Wave 6C phrase: $requiredPhrase"
  }
}

$appScript = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/app.js') -Raw
foreach ($requiredPhrase in @(
  'appendDisplayShellAudit',
  'showDisplayShellPreview',
  'fillerAudioVolumePreviewEnabled: true',
  'previewWindowPlumbingPreviewEnabled: true',
  'externalDisplayWindowPreviewEnabled: true',
  'fullscreenExternalDisplayPreviewEnabled: true',
  'displaySelectionPreviewEnabled: true',
  'clonedDisplaySupportPreviewEnabled: true',
  'nowSingingCardPreviewEnabled: true',
  'upNextCardPreviewEnabled: true',
  'welcomeScreenPreviewEnabled: true',
  'scrollingAnnouncementPreviewEnabled: true',
  'displayShellOpensRealPreviewWindow: false',
  'displayShellOpensRealExternalWindow: false',
  'displayShellEntersFullscreen: false',
  'displayShellEnumeratesDisplays: false',
  'displayShellSelectsDisplay: false',
  'displayShellClonesDisplay: false',
  'displayShellLoadsBackgroundFiles: false',
  'displayShellUsesCamera: false',
  'displayShellWritesState: false'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell app script is missing Wave 6C phrase: $requiredPhrase"
  }
}

Write-Host 'Host display shell smoke test passed: filler volume, preview window, external display, cards, announcements, and safety markers are present.'
