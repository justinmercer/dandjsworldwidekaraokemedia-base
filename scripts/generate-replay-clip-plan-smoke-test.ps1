$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'scripts/generate-replay-clip-plan.ps1',
  'packages/contracts/schemas/replay-clip-plan.v1.schema.json',
  'docs/development/replay-clip-plan-v1.md'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing replay clip plan file: $path"
  }
}

$scriptContent = Get-Content -LiteralPath (Join-Path $root 'scripts/generate-replay-clip-plan.ps1') -Raw
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
  'Remove-Item',
  'Get-Item',
  'Test-Path'
)) {
  if ($scriptContent -match [regex]::Escape($forbidden)) {
    throw "Replay clip plan generator must not contain forbidden active integration/media command: $forbidden"
  }
}

$tempPlan = Join-Path $env:TEMP ("dandj-replay-clip-plan-" + [guid]::NewGuid().ToString() + ".json")

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts/generate-replay-clip-plan.ps1') `
  -EventDate '2026-06-15' `
  -VenueName 'Smoke Test Venue' `
  -HostName 'Smoke Test Host' `
  -ShowSessionId 'smoke-test-show-session' `
  -SourceIntakeId 'smoke-test-intake' `
  -ClipCount 4 `
  -OutputPath $tempPlan

if ($LASTEXITCODE -ne 0) {
  throw 'Replay clip plan generator exited with a non-zero code.'
}

if (-not (Test-Path -LiteralPath $tempPlan -PathType Leaf)) {
  throw 'Replay clip plan was not generated.'
}

$plan = Get-Content -LiteralPath $tempPlan -Raw | ConvertFrom-Json

if ($plan.contractVersion -ne 'v1') { throw 'Unexpected replay clip plan contractVersion.' }
if ($plan.kind -ne 'replay-clip-plan') { throw 'Unexpected replay clip plan kind.' }
if (-not $plan.clipPlanId.StartsWith('replay-clip-plan-')) { throw 'Replay clip plan id was not generated.' }
if ($plan.sourceIntakeId -ne 'smoke-test-intake') { throw 'Replay clip plan source intake mismatch.' }
if ($plan.show.eventDate -ne '2026-06-15') { throw 'Replay clip plan event date mismatch.' }
if ($plan.show.venueName -ne 'Smoke Test Venue') { throw 'Replay clip plan venue mismatch.' }
if ($plan.show.hostName -ne 'Smoke Test Host') { throw 'Replay clip plan host mismatch.' }
if ($plan.show.showSessionId -ne 'smoke-test-show-session') { throw 'Replay clip plan show session mismatch.' }
if ($plan.clips.Count -ne 4) { throw 'Replay clip plan clip count mismatch.' }
if ($plan.clips[0].clipId -ne 'manual-clip-001') { throw 'First clip id mismatch.' }
if ($plan.clips[3].clipId -ne 'manual-clip-004') { throw 'Fourth clip id mismatch.' }
if ($plan.clips[0].approxStart -ne 'operator-to-fill-start') { throw 'Clip start placeholder mismatch.' }
if ($plan.clips[0].approxEnd -ne 'operator-to-fill-end') { throw 'Clip end placeholder mismatch.' }
if ($plan.clips[0].singerDisplayName -ne 'operator-to-confirm-singer') { throw 'Singer placeholder mismatch.' }
if ($plan.clips[0].songTitle -ne 'operator-to-confirm-song') { throw 'Song placeholder mismatch.' }
if ($plan.clips[0].artistName -ne 'operator-to-confirm-artist') { throw 'Artist placeholder mismatch.' }
if ($plan.clips[0].overlayTitle -ne 'operator-to-confirm-overlay-title') { throw 'Overlay placeholder mismatch.' }
if ($plan.clips[0].privacyStatus -ne 'not-reviewed') { throw 'Privacy status placeholder mismatch.' }
if ($plan.clips[0].publishDecision -ne 'not-approved') { throw 'Publish decision placeholder mismatch.' }
if ($plan.planStatus.clipRangesReviewed -ne 'not-reviewed') { throw 'Clip range status mismatch.' }
if ($plan.planStatus.publishApproval -ne 'not-approved') { throw 'Publish approval status mismatch.' }
if ($plan.processingBoundary.manualPlanOnly -ne $true) { throw 'manualPlanOnly boundary mismatch.' }

foreach ($falseBoundary in @(
  'mediaOpened',
  'metadataRead',
  'mediaSplitOrTranscoded',
  'overlayRendered',
  'uploadedOrPublished',
  'songRecognitionPerformed',
  'personRecognitionPerformed',
  'singerProfilesReadOrWritten'
)) {
  if ($plan.processingBoundary.$falseBoundary -ne $false) {
    throw "Replay clip plan boundary should be false: $falseBoundary"
  }
}

$schema = Get-Content -LiteralPath (Join-Path $root 'packages/contracts/schemas/replay-clip-plan.v1.schema.json') -Raw | ConvertFrom-Json
if ($schema.title -ne 'Replay Clip Plan') { throw 'Replay clip plan schema title mismatch.' }
if ($schema.properties.processingBoundary.properties.mediaSplitOrTranscoded.const -ne $false) { throw 'Schema must keep mediaSplitOrTranscoded false.' }
if ($schema.properties.processingBoundary.properties.overlayRendered.const -ne $false) { throw 'Schema must keep overlayRendered false.' }
if ($schema.properties.processingBoundary.properties.personRecognitionPerformed.const -ne $false) { throw 'Schema must keep personRecognitionPerformed false.' }

Remove-Item -LiteralPath $tempPlan -Force -ErrorAction SilentlyContinue

Write-Host 'Replay clip plan smoke test passed: manual clip placeholders generated, review states initialized, and media/overlay/publishing safety boundaries are false.'
