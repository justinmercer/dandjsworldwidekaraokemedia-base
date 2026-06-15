param(
  [string]$OutputPath = 'reports/pilot-packet/latest-pilot-packet.md',
  [switch]$RunReports
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

  if ($RunReports) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot 'scripts/generate-readiness-report.ps1') -RunSmoke
    if ($LASTEXITCODE -ne 0) { throw 'Readiness report generation failed.' }

    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot 'scripts/generate-pilot-feedback-summary.ps1')
    if ($LASTEXITCODE -ne 0) { throw 'Pilot feedback summary generation failed.' }
  }

  $backlogPath = Join-Path $repoRoot 'docs/MASTER-BACKLOG-577.md'
  $backlog = Get-Content -LiteralPath $backlogPath -Raw

  $tick = [char]96
  $checkedPattern = '- ' + [regex]::Escape('[x]') + ' ' + [regex]::Escape($tick) + 'KARA-\d{3}' + [regex]::Escape($tick)
  $uncheckedPattern = '- ' + [regex]::Escape('[ ]') + ' ' + [regex]::Escape($tick) + 'KARA-\d{3}' + [regex]::Escape($tick)

  $checkedTasks = [regex]::Matches($backlog, $checkedPattern).Count
  $uncheckedTasks = [regex]::Matches($backlog, $uncheckedPattern).Count

  $readinessReport = Join-Path $repoRoot 'reports/readiness/latest-readiness-report.md'
  $feedbackSummary = Join-Path $repoRoot 'reports/pilot-feedback/latest-pilot-feedback-summary.md'

  $readinessState = if (Test-Path -LiteralPath $readinessReport -PathType Leaf) { 'Available' } else { 'Not generated yet' }
  $feedbackState = if (Test-Path -LiteralPath $feedbackSummary -PathType Leaf) { 'Available' } else { 'Not generated yet' }

  $outputFullPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath
  } else {
    Join-Path $repoRoot $OutputPath
  }

  $outputDirectory = Split-Path -Parent $outputFullPath
  if ($outputDirectory) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
  }

  $packet = @(
    '# D & J''s Karaoke Pilot Packet',
    '',
    "Generated: $((Get-Date).ToString('s'))",
    "Branch: $branch",
    "Commit: $commit",
    "Working tree: $workingTreeState",
    '',
    '## Current repo readiness',
    '',
    "Backlog checked tasks: $checkedTasks",
    "Backlog unchecked tasks: $uncheckedTasks",
    "Readiness report: $readinessState",
    "Pilot feedback summary: $feedbackState",
    '',
    '## Operator documents',
    '',
    '- docs/operations/operator-quick-start-guide.md',
    '- docs/operations/pre-show-checklist.md',
    '- docs/operations/post-show-checklist.md',
    '- docs/operations/host-troubleshooting-guide.md',
    '- docs/operations/venue-router-troubleshooting-guide.md',
    '- docs/operations/obs-companion-troubleshooting-guide.md',
    '- docs/operations/recovery-drill-guide.md',
    '- docs/operations/known-limitations.md',
    '- docs/operations/release-blocker-criteria.md',
    '',
    '## Suggested pilot flow',
    '',
    '1. Review known limitations and release blockers.',
    '2. Review pre-show checklist.',
    '3. Run readiness report with smoke test.',
    '4. Run the pilot.',
    '5. Fill out first-pilot feedback form.',
    '6. Generate pilot feedback summary.',
    '7. Review post-show checklist.',
    '',
    '## Optional local report commands',
    '',
    'PowerShell:',
    'powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-readiness-report.ps1 -RunSmoke',
    'powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-pilot-feedback-summary.ps1',
    'powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-pilot-packet.ps1 -RunReports',
    '',
    '## Safety summary',
    '',
    '- No media playback is started.',
    '- No display or device settings are changed.',
    '- No router, DNS, firewall, or port settings are changed.',
    '- No API request is made.',
    '- No network request is made.',
    '- No database is read or written.',
    '- No singer profile is read or written.',
    '- No media file is read, moved, copied, renamed, or deleted.',
    '- No cloud service is used.',
    '- No face recognition or biometric processing is performed.'
  )

  Set-Content -LiteralPath $outputFullPath -Value $packet -Encoding UTF8
  Write-Host "Pilot packet generated: $outputFullPath"
} finally {
  Pop-Location
}
