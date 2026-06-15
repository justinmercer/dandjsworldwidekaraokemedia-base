
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/windows-host-singer-profiles.md',
  'host/windows-host-shell/demo-data/singer-profile-demo-fixtures.json'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing singer profile file: $path"
  }
}

$fixturePath = Join-Path $root 'host/windows-host-shell/demo-data/singer-profile-demo-fixtures.json'
$fixtures = Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json

if ($fixtures.containsRealSingerData -ne $false) {
  throw 'Singer profile demo fixtures must not contain real singer data.'
}
if ($fixtures.privacyDefaults.optionalContactFieldsHiddenByDefault -ne $true) {
  throw 'Singer profile optional contact fields must be hidden by default.'
}
if ($fixtures.privacyDefaults.staffNotesVisibleToPublic -ne $false) {
  throw 'Singer staff-only notes must not be public.'
}

$manifest = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/host-shell.manifest.json') -Raw | ConvertFrom-Json
if ($manifest.hostShellFeatures.singerProfileModelShell.writesSingerRecords -ne $false) {
  throw 'Singer profile model shell must not write singer records in Wave 5A.'
}
if ($manifest.hostShellFeatures.singerProfileModelShell.mergesSingerRecords -ne $false) {
  throw 'Singer profile model shell must not merge singer records in Wave 5A.'
}
if ($manifest.hostShellFeatures.singerProfileModelShell.exposesContactPublicly -ne $false) {
  throw 'Singer profile model shell must not expose contact publicly.'
}

$index = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/index.html') -Raw
foreach ($requiredPhrase in @(
  'Singer Profiles',
  'Profile model',
  'Optional contact',
  'Hidden by default',
  'Staff notes',
  'Favourites and history',
  'Remembered key',
  'Duet and group support',
  'Aliases and repeat warnings',
  'Singer Alias Merge Preview',
  'Repeat Singer Warning Preview'
)) {
  if ($index -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell is missing Wave 5A singer profile phrase: $requiredPhrase"
  }
}

$appScript = Get-Content -LiteralPath (Join-Path $root 'host/windows-host-shell/src/app.js') -Raw
foreach ($requiredPhrase in @(
  'appendSingerProfileAudit',
  'showSingerAliasPreview',
  'showRepeatSingerPreview',
  'singerProfileModelShellEnabled: true',
  'singerDisplayNamesEnabled: true',
  'singerOptionalContactPrivacyDefaultsEnabled: true',
  'singerStaffOnlyNotesEnabled: true',
  'singerFavouritesPreviewEnabled: true',
  'singerSongHistoryPreviewEnabled: true',
  'singerRememberedKeyChangePreviewEnabled: true',
  'singerDuetGroupPerformancePreviewEnabled: true',
  'singerAliasMergePreviewEnabled: true',
  'repeatSingerDetectionPreviewEnabled: true',
  'singerProfileContainsRealSingerData: false',
  'singerProfileWritesRecords: false',
  'singerProfileMergesRecords: false',
  'singerContactPublicExposureEnabled: false'
)) {
  if ($appScript -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host shell app script is missing Wave 5A singer profile phrase: $requiredPhrase"
  }
}

Write-Host 'Host singer profile smoke test passed: profile model shell, privacy defaults, favourites/history, aliases, duet/group, and repeat warning markers are present.'
