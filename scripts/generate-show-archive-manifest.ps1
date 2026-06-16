param(
  [string]$EventDate = (Get-Date -Format 'yyyy-MM-dd'),
  [string]$VenueName = 'Unspecified venue',
  [string]$HostName = 'Unspecified host',
  [string]$RecordingLabel = 'Unspecified recording label',
  [string]$OutputPath = 'reports/show-archive/latest-show-archive-manifest.md'
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

  $outputFullPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath
  } else {
    Join-Path $repoRoot $OutputPath
  }

  $outputDirectory = Split-Path -Parent $outputFullPath
  if ($outputDirectory) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
  }

  $manifest = @(
    '# D & J''s Karaoke Show Archive Manifest',
    '',
    "Generated: $((Get-Date).ToString('s'))",
    "Event date: $EventDate",
    "Venue: $VenueName",
    "Host: $HostName",
    "Recording label: $RecordingLabel",
    "Branch: $branch",
    "Commit: $commit",
    "Working tree: $workingTreeState",
    '',
    '## Purpose',
    '',
    'Use this manifest as a local post-show checklist before any later editing, clipping, upload, tagging, or publishing work begins.',
    '',
    '## Items to collect manually',
    '',
    '- [ ] Main venue recording file path noted by the operator',
    '- [ ] Backup recording file path noted by the operator',
    '- [ ] Host notes copied into the pilot notes document',
    '- [ ] Singer sign-up sheet or rotation notes collected',
    '- [ ] Song request notes collected',
    '- [ ] Known audio/video issues written down',
    '- [ ] Any permission or privacy concerns written down',
    '- [ ] Any missing performer names marked for follow-up',
    '',
    '## Media handling boundary',
    '',
    '- This manifest does not scan folders.',
    '- This manifest does not open media files.',
    '- This manifest does not read media metadata.',
    '- This manifest does not move, copy, rename, or delete media files.',
    '- This manifest does not upload anything.',
    '- This manifest does not perform face recognition or biometric processing.',
    '',
    '## Later processing placeholders',
    '',
    '| Item | Status | Notes |',
    '| --- | --- | --- |',
    '| Full recording available | Not reviewed | Operator to confirm manually |',
    '| Backup recording available | Not reviewed | Operator to confirm manually |',
    '| Audio quality | Not reviewed | Operator to confirm manually |',
    '| Video quality | Not reviewed | Operator to confirm manually |',
    '| Singer list | Not reviewed | Operator to confirm manually |',
    '| Song list | Not reviewed | Operator to confirm manually |',
    '| Privacy concerns | Not reviewed | Operator to confirm manually |',
    '',
    '## Suggested next steps',
    '',
    '1. Store the recording safely according to the operator workflow.',
    '2. Fill in the manual checklist above.',
    '3. Generate the pilot packet if needed.',
    '4. Review known limitations and release blockers before doing any publishing work.',
    '5. Only proceed to media processing after the operator confirms the show archive is ready.',
    '',
    '## Safety summary',
    '',
    '- No API request is made.',
    '- No network request is made.',
    '- No database is read or written.',
    '- No singer profile is read or written.',
    '- No media file is read, moved, copied, renamed, or deleted.',
    '- No cloud service is used.',
    '- No face recognition or biometric processing is performed.'
  )

  Set-Content -LiteralPath $outputFullPath -Value $manifest -Encoding UTF8
  Write-Host "Show archive manifest generated: $outputFullPath"
} finally {
  Pop-Location
}
