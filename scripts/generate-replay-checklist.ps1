param(
  [string]$ClipPlanPath = 'reports/replay-clip-plan/latest-replay-clip-plan.json',
  [string]$OutputPath = 'reports/replay-checklist/latest-replay-checklist.md'
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $repoRoot

try {
  $clipPlanFullPath = if ([System.IO.Path]::IsPathRooted($ClipPlanPath)) {
    $ClipPlanPath
  } else {
    Join-Path $repoRoot $ClipPlanPath
  }

  if (-not (Test-Path -LiteralPath $clipPlanFullPath -PathType Leaf)) {
    throw "Clip plan file not found: $ClipPlanPath"
  }

  $clipPlan = Get-Content -LiteralPath $clipPlanFullPath -Raw | ConvertFrom-Json

  if ($clipPlan.kind -ne 'replay-clip-plan') {
    throw 'Input file is not a replay clip plan.'
  }

  $outputFullPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath
  } else {
    Join-Path $repoRoot $OutputPath
  }

  $outputDirectory = Split-Path -Parent $outputFullPath
  if ($outputDirectory) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
  }

  $lines = @(
    '# D & J''s Karaoke Replay Checklist',
    '',
    "Generated: $((Get-Date).ToString('s'))",
    "Source clip plan: $ClipPlanPath",
    "Clip plan id: $($clipPlan.clipPlanId)",
    "Source intake id: $($clipPlan.sourceIntakeId)",
    "Event date: $($clipPlan.show.eventDate)",
    "Venue: $($clipPlan.show.venueName)",
    "Host: $($clipPlan.show.hostName)",
    "Show session id: $($clipPlan.show.showSessionId)",
    '',
    '## Operator review checklist',
    '',
    '- [ ] Every clip start time has been confirmed manually.',
    '- [ ] Every clip end time has been confirmed manually.',
    '- [ ] Singer display names have been reviewed.',
    '- [ ] Song titles have been reviewed.',
    '- [ ] Artist names have been reviewed.',
    '- [ ] Lower-left overlay titles have been reviewed.',
    '- [ ] Privacy status has been reviewed for every clip.',
    '- [ ] Only approved clips are marked for publishing.',
    '',
    '## Clip checklist',
    '',
    '| # | Clip id | Start | End | Singer | Song | Artist | Overlay | Privacy | Publish | Notes |',
    '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |'
  )

  foreach ($clip in $clipPlan.clips) {
    $lines += "| $($clip.clipNumber) | $($clip.clipId) | $($clip.approxStart) | $($clip.approxEnd) | $($clip.singerDisplayName) | $($clip.songTitle) | $($clip.artistName) | $($clip.overlayTitle) | $($clip.privacyStatus) | $($clip.publishDecision) | $($clip.operatorNotes) |"
  }

  $lines += @(
    '',
    '## Safety boundary',
    '',
    '- This checklist reads the clip plan JSON only.',
    '- This checklist does not open media files.',
    '- This checklist does not read media metadata.',
    '- This checklist does not split or transcode media.',
    '- This checklist does not render title overlays.',
    '- This checklist does not upload or publish anything.',
    '- This checklist does not perform song recognition.',
    '- This checklist does not identify people in video.',
    '- This checklist does not read or write singer profiles.'
  )

  Set-Content -LiteralPath $outputFullPath -Value $lines -Encoding UTF8
  Write-Host "Replay checklist generated: $outputFullPath"
} finally {
  Pop-Location
}
