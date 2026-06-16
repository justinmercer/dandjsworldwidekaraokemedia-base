$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'scripts/generate-replay-checklist.ps1',
  'docs/development/replay-checklist-v1.md'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing replay checklist file: $path"
  }
}

$scriptContent = Get-Content -LiteralPath (Join-Path $root 'scripts/generate-replay-checklist.ps1') -Raw
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
    throw "Replay checklist generator must not contain forbidden active integration/media command: $forbidden"
  }
}

$tempPlan = Join-Path $env:TEMP ("dandj-replay-checklist-plan-" + [guid]::NewGuid().ToString() + ".json")
$tempChecklist = Join-Path $env:TEMP ("dandj-replay-checklist-" + [guid]::NewGuid().ToString() + ".md")

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts/generate-replay-clip-plan.ps1') `
  -EventDate '2026-06-15' `
  -VenueName 'Smoke Test Venue' `
  -HostName 'Smoke Test Host' `
  -ShowSessionId 'smoke-test-show-session' `
  -SourceIntakeId 'smoke-test-intake' `
  -ClipCount 2 `
  -OutputPath $tempPlan

if ($LASTEXITCODE -ne 0) {
  throw 'Replay clip plan generator exited with a non-zero code while preparing checklist smoke test.'
}

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts/generate-replay-checklist.ps1') `
  -ClipPlanPath $tempPlan `
  -OutputPath $tempChecklist

if ($LASTEXITCODE -ne 0) {
  throw 'Replay checklist generator exited with a non-zero code.'
}

if (-not (Test-Path -LiteralPath $tempChecklist -PathType Leaf)) {
  throw 'Replay checklist was not generated.'
}

$checklist = Get-Content -LiteralPath $tempChecklist -Raw

foreach ($requiredPhrase in @(
  "D & J's Karaoke Replay Checklist",
  'Source intake id: smoke-test-intake',
  'Event date: 2026-06-15',
  'Venue: Smoke Test Venue',
  'Host: Smoke Test Host',
  'Operator review checklist',
  'Clip checklist',
  'manual-clip-001',
  'manual-clip-002',
  'operator-to-confirm-singer',
  'operator-to-confirm-song',
  'operator-to-confirm-artist',
  'operator-to-confirm-overlay-title',
  'not-reviewed',
  'not-approved',
  'Safety boundary',
  'This checklist reads the clip plan JSON only.',
  'This checklist does not open media files.',
  'This checklist does not read media metadata.',
  'This checklist does not split or transcode media.',
  'This checklist does not render title overlays.',
  'This checklist does not upload or publish anything.',
  'This checklist does not perform song recognition.',
  'This checklist does not identify people in video.',
  'This checklist does not read or write singer profiles.'
)) {
  if ($checklist -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Generated replay checklist is missing phrase: $requiredPhrase"
  }
}

Remove-Item -LiteralPath $tempPlan -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $tempChecklist -Force -ErrorAction SilentlyContinue

Write-Host 'Replay checklist smoke test passed: checklist generated from clip plan, manual review fields included, and safety boundaries are present.'
