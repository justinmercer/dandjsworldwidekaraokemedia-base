
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/windows-host-theme-shell.md',
  'host/windows-host-shell/demo-data/theme-shell-demo-fixtures.json'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing theme shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/demo-data/theme-shell-demo-fixtures.json') -Raw | ConvertFrom-Json

foreach ($guard in @(
  'loadsLogoFiles',
  'loadsBackgroundFiles',
  'usesCamera',
  'changesRealMonitorState',
  'controlsLiveShow',
  'readsMediaFiles',
  'writesThemeState'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Theme shell fixture guard must remain false: $guard"
  }
}

$manifest = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/host-shell.manifest.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'loadsLogoFiles',
  'loadsBackgroundFiles',
  'usesCamera',
  'changesRealMonitorState',
  'controlsLiveShow',
  'readsMediaFiles',
  'writesThemeState'
)) {
  if ($manifest.hostShellFeatures.themeShell.$guard -ne $false) {
    throw "Theme shell manifest guard must remain false: $guard"
  }
}

$index = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/index.html') -Raw
foreach ($requiredPhrase in @(
  'Theme Shell',
  'Venue logo overlay',
  'Custom background support',
  'Camera-background placeholder',
  'Theme selection',
  'Private Party',
  'Wedding',
  'Bar Night',
  'Fallback and failure isolation',
  'Theme Shell Preview'
)) {
  if ($index -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell is missing Wave 6D phrase: $requiredPhrase"
  }
}

$appScript = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/app.js') -Raw
foreach ($requiredPhrase in @(
  'appendThemeShellAudit',
  'showThemeShellPreview',
  'venueLogoOverlayPreviewEnabled: true',
  'customBackgroundSupportPreviewEnabled: true',
  'cameraBackgroundPlaceholderEnabled: true',
  'themeSelectionPreviewEnabled: true',
  'privatePartyThemePreviewEnabled: true',
  'weddingThemePreviewEnabled: true',
  'barNightThemePreviewEnabled: true',
  'monitorDisconnectFallbackPreviewEnabled: true',
  'failureIsolationPreviewEnabled: true',
  'demoFixturesOnlyEnabled: true',
  'themeShellLoadsLogoFiles: false',
  'themeShellLoadsBackgroundFiles: false',
  'themeShellUsesCamera: false',
  'themeShellChangesRealMonitorState: false',
  'themeShellControlsLiveShow: false',
  'themeShellReadsMediaFiles: false',
  'themeShellWritesState: false'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell app script is missing Wave 6D phrase: $requiredPhrase"
  }
}

Write-Host 'Host theme shell smoke test passed: logo, backgrounds, camera placeholder, themes, fallback, isolation, demo fixtures, and safety markers are present.'
