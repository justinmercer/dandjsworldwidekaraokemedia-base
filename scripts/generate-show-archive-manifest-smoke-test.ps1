$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'scripts/generate-show-archive-manifest.ps1',
  'docs/development/runtime-show-archive-manifest-generator.md'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing show archive manifest generator file: $path"
  }
}

$scriptContent = Get-Content -LiteralPath (Join-Path $root 'scripts/generate-show-archive-manifest.ps1') -Raw
foreach ($forbidden in @(
  'Invoke-WebRequest',
  'Invoke-RestMethod',
  'Start-BitsTransfer',
  'curl ',
  'wget ',
  'psql',
  'sqlite3',
  'sqlcmd',
  'Get-ChildItem',
  'Copy-Item',
  'Move-Item',
  'Rename-Item',
  'Remove-Item'
)) {
  if ($scriptContent -match [regex]::Escape($forbidden)) {
    throw "Show archive manifest generator must not contain forbidden active integration/media command: $forbidden"
  }
}

$tempManifest = Join-Path $env:TEMP ("dandj-show-archive-manifest-" + [guid]::NewGuid().ToString() + ".md")

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts/generate-show-archive-manifest.ps1') `
  -EventDate '2026-06-15' `
  -VenueName 'Smoke Test Venue' `
  -HostName 'Smoke Test Host' `
  -RecordingLabel 'Smoke Test Recording' `
  -OutputPath $tempManifest

if ($LASTEXITCODE -ne 0) {
  throw 'Show archive manifest generator exited with a non-zero code.'
}

if (-not (Test-Path -LiteralPath $tempManifest -PathType Leaf)) {
  throw 'Show archive manifest was not generated.'
}

$manifest = Get-Content -LiteralPath $tempManifest -Raw

foreach ($requiredPhrase in @(
  "D & J's Karaoke Show Archive Manifest",
  'Event date: 2026-06-15',
  'Venue: Smoke Test Venue',
  'Host: Smoke Test Host',
  'Recording label: Smoke Test Recording',
  'Items to collect manually',
  'Media handling boundary',
  'Later processing placeholders',
  'Suggested next steps',
  'Safety summary',
  'This manifest does not scan folders.',
  'This manifest does not open media files.',
  'This manifest does not read media metadata.',
  'No API request is made.',
  'No network request is made.',
  'No database is read or written.',
  'No singer profile is read or written.',
  'No media file is read, moved, copied, renamed, or deleted.',
  'No face recognition or biometric processing is performed.'
)) {
  if ($manifest -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Generated show archive manifest is missing phrase: $requiredPhrase"
  }
}

Remove-Item -LiteralPath $tempManifest -Force -ErrorAction SilentlyContinue

Write-Host 'Show archive manifest generator smoke test passed: manifest generated, manual collection checklist included, placeholders included, and safety markers are present.'
