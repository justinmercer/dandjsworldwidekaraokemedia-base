
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/device-installer-preview-shell.md',
  'maintenance/demo-data/device-installer-preview-fixtures.json',
  'maintenance/src/device-installer-preview.html'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing device installer preview shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'maintenance/demo-data/device-installer-preview-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'probesAudioDevices',
  'probesVideoOutputs',
  'scansMachineInfo',
  'runsRestartCommand',
  'buildsInstaller',
  'runsUpdateCheck',
  'makesNetworkRequests',
  'writesFiles'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Device installer preview guard must remain false: $guard"
  }
}

$html = Get-Content -LiteralPath (Join-Path $root 'maintenance/src/device-installer-preview.html') -Raw
foreach ($requiredPhrase in @(
  'Audio device health check',
  'Video output health check',
  'Host machine info',
  'Diagnostics safe restart note',
  'Installer package placeholder',
  'Windows installer instructions',
  'First-run setup checklist',
  'Update-check placeholder',
  'No device probing',
  'No display probing',
  'No machine scanning',
  'No restart command',
  'No installer build',
  'No update check',
  'No network request',
  'No filesystem writes beyond fixtures'
)) {
  if ($html -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Device installer preview shell is missing Wave 12C phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/device-installer-preview-shell.md') -Raw
foreach ($requiredPhrase in @(
  'Wave 12C adds',
  'audio device health check preview',
  'video output health check preview',
  'host machine info preview',
  'diagnostics safe restart note',
  'installer package placeholder',
  'Windows installer instructions preview',
  'first-run setup checklist preview',
  'update-check placeholder'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Device installer preview doc is missing Wave 12C phrase: $requiredPhrase"
  }
}

Write-Host 'Device installer preview smoke test passed: audio, video, machine info, safe restart note, installer placeholder, Windows instructions, first-run checklist, update placeholder, and safety markers are present.'
