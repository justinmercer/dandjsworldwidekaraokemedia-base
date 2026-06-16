param(
  [string]$EventDate = (Get-Date -Format 'yyyy-MM-dd'),
  [string]$VenueName = 'Unspecified venue',
  [string]$HostName = 'Unspecified host',
  [string]$ShowArchiveManifestPath = 'reports/show-archive/latest-show-archive-manifest.md',
  [string]$OutputPath = 'reports/post-show-processing/latest-post-show-processing-plan.md'
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $repoRoot

try {
  $branch = (& git branch --show-current 2>$null)
  if (-not $branch) { $branch = 'unknown' }

  $commit = (& git rev-parse --short HEAD 2>$null)
  if (-not $commit) { $commit = 'unknown' }

  $statusShort = (& git status --short 2>$null)
  $workingTreeState = if ($statusShort) { 'dirty' } else { 'clean' }

  $manifestFullPath = if ([System.IO.Path]::IsPathRooted($ShowArchiveManifestPath)) {
    $ShowArchiveManifestPath
  } else {
    Join-Path $repoRoot $ShowArchiveManifestPath
  }

  $manifestState = if (Test-Path -LiteralPath $manifestFullPath -PathType Leaf) {
    'available'
  } else {
    'not found; operator should generate or attach it before processing'
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

  $plan = @(
    '# D & J''s Karaoke Post-Show Processing Plan',
    '',
    "Generated: $((Get-Date).ToString('s'))",
    "Event date: $EventDate",
    "Venue: $VenueName",
    "Host: $HostName",
    "Show archive manifest path: $ShowArchiveManifestPath",
    "Show archive manifest state: $manifestState",
    "Branch: $branch",
    "Commit: $commit",
    "Working tree: $workingTreeState",
    '',
    '## Purpose',
    '',
    'Use this plan after the show archive manifest is created and before any replay clipping, title overlay, tagging, upload, or publishing work begins.',
    '',
    '## Required operator gates before processing',
    '',
    '- [ ] Main recording location has been written down by the operator.',
    '- [ ] Backup recording location has been written down by the operator.',
    '- [ ] Audio and video issues from the show have been reviewed.',
    '- [ ] Singer names that need follow-up have been marked manually.',
    '- [ ] Song titles and artists that need confirmation have been marked manually.',
    '- [ ] Privacy or permission concerns have been reviewed before clipping.',
    '- [ ] Release blockers have been checked before publishing anything.',
    '',
    '## Manual replay clip planning table',
    '',
    '| Clip # | Singer | Song | Artist | Approx start | Approx end | Overlay title | Privacy status | Publish decision | Notes |',
    '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |',
    '| 1 | Not reviewed | Not reviewed | Not reviewed | Not reviewed | Not reviewed | Not reviewed | Not reviewed | Not approved | Operator to fill in manually |',
    '| 2 | Not reviewed | Not reviewed | Not reviewed | Not reviewed | Not reviewed | Not reviewed | Not reviewed | Not approved | Operator to fill in manually |',
    '| 3 | Not reviewed | Not reviewed | Not reviewed | Not reviewed | Not reviewed | Not reviewed | Not reviewed | Not approved | Operator to fill in manually |',
    '',
    '## Replay processing stages',
    '',
    '1. Confirm the show archive manifest is complete.',
    '2. Manually review the full recording and write down candidate clip ranges.',
    '3. Confirm singer names, song titles, and artists before naming files or overlays.',
    '4. Decide the lower-left overlay title text for each clip.',
    '5. Review singer account/tagging status only after privacy and consent rules are satisfied.',
    '6. Watch each exported clip before publishing.',
    '7. Publish only clips that are explicitly approved.',
    '',
    '## Publishing boundary',
    '',
    '- This plan does not publish anything.',
    '- This plan does not upload anything.',
    '- This plan does not create, update, or read singer accounts.',
    '- This plan does not auto-tag singers.',
    '- This plan does not approve clips automatically.',
    '',
    '## Media handling boundary',
    '',
    '- This plan does not scan folders.',
    '- This plan does not open media files.',
    '- This plan does not read media metadata.',
    '- This plan does not split, transcode, rename, move, copy, or delete media files.',
    '- This plan does not perform song recognition.',
    '- This plan does not perform face recognition or biometric processing.',
    '',
    '## Future automation markers',
    '',
    '- Clip splitting can be automated later only after manual operator review is proven reliable.',
    '- Song and artist detection can be added later with a clear review step before file naming.',
    '- Face matching can be researched later only with privacy, consent, and account safety rules in place.',
    '- Title overlays can be automated later only after the operator confirms the text format.',
    '',
    '## Safety summary',
    '',
    '- No API request is made.',
    '- No network request is made.',
    '- No database is read or written.',
    '- No singer profile is read or written.',
    '- No media file is read, moved, copied, renamed, split, transcoded, or deleted.',
    '- No cloud service is used.',
    '- No song recognition is performed.',
    '- No face recognition or biometric processing is performed.'
  )

  Set-Content -LiteralPath $outputFullPath -Value $plan -Encoding UTF8
  Write-Host "Post-show processing plan generated: $outputFullPath"
} finally {
  Pop-Location
}
