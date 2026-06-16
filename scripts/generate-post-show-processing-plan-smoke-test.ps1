$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'scripts/generate-post-show-processing-plan.ps1',
  'docs/development/runtime-post-show-processing-plan-generator.md'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing post-show processing plan generator file: $path"
  }
}

$scriptContent = Get-Content -LiteralPath (Join-Path $root 'scripts/generate-post-show-processing-plan.ps1') -Raw
foreach ($forbidden in @(
  'Invoke-WebRequest',
  'Invoke-RestMethod',
  'Start-BitsTransfer',
  'Start-Process',
  'curl ',
  'wget ',
  'ffmpeg',
  'ffprobe',
  'python ',
  'node ',
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
    throw "Post-show processing plan generator must not contain forbidden active integration/media command: $forbidden"
  }
}

$tempPlan = Join-Path $env:TEMP ("dandj-post-show-processing-plan-" + [guid]::NewGuid().ToString() + ".md")

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts/generate-post-show-processing-plan.ps1') `
  -EventDate '2026-06-15' `
  -VenueName 'Smoke Test Venue' `
  -HostName 'Smoke Test Host' `
  -ShowArchiveManifestPath 'reports/show-archive/latest-show-archive-manifest.md' `
  -OutputPath $tempPlan

if ($LASTEXITCODE -ne 0) {
  throw 'Post-show processing plan generator exited with a non-zero code.'
}

if (-not (Test-Path -LiteralPath $tempPlan -PathType Leaf)) {
  throw 'Post-show processing plan was not generated.'
}

$plan = Get-Content -LiteralPath $tempPlan -Raw

foreach ($requiredPhrase in @(
  "D & J's Karaoke Post-Show Processing Plan",
  'Event date: 2026-06-15',
  'Venue: Smoke Test Venue',
  'Host: Smoke Test Host',
  'Show archive manifest path: reports/show-archive/latest-show-archive-manifest.md',
  'Required operator gates before processing',
  'Manual replay clip planning table',
  'Replay processing stages',
  'Publishing boundary',
  'Media handling boundary',
  'Future automation markers',
  'Safety summary',
  'This plan does not publish anything.',
  'This plan does not upload anything.',
  'This plan does not create, update, or read singer accounts.',
  'This plan does not auto-tag singers.',
  'This plan does not scan folders.',
  'This plan does not open media files.',
  'This plan does not read media metadata.',
  'This plan does not split, transcode, rename, move, copy, or delete media files.',
  'This plan does not perform song recognition.',
  'This plan does not perform face recognition or biometric processing.',
  'No API request is made.',
  'No network request is made.',
  'No database is read or written.',
  'No singer profile is read or written.',
  'No media file is read, moved, copied, renamed, split, transcoded, or deleted.'
)) {
  if ($plan -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Generated post-show processing plan is missing phrase: $requiredPhrase"
  }
}

Remove-Item -LiteralPath $tempPlan -Force -ErrorAction SilentlyContinue

Write-Host 'Post-show processing plan generator smoke test passed: plan generated, operator gates included, replay planning table included, and safety markers are present.'
