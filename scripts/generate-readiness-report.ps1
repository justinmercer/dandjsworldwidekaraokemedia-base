
param(
  [string]$OutputPath = 'reports/readiness/latest-readiness-report.md',
  [switch]$RunSmoke
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $repoRoot

try {
  $backlogPath = Join-Path $repoRoot 'docs/MASTER-BACKLOG-577.md'
  if (-not (Test-Path -LiteralPath $backlogPath -PathType Leaf)) {
    throw 'Backlog file not found.'
  }

  $backlog = Get-Content -LiteralPath $backlogPath -Raw

  $allTasks = [regex]::Matches($backlog, '- \[[ x]\] `KARA-\d{3}`')
  $checkedTasks = [regex]::Matches($backlog, '- \[x\] `KARA-\d{3}`')
  $uncheckedTasks = [regex]::Matches($backlog, '- \[ \] `KARA-\d{3}`')

  $branch = (& git branch --show-current 2>$null)
  if (-not $branch) { $branch = 'unknown' }

  $commit = (& git rev-parse --short HEAD 2>$null)
  if (-not $commit) { $commit = 'unknown' }

  $statusShort = (& git status --short 2>$null)
  $workingTreeState = if ($statusShort) { 'dirty' } else { 'clean' }

  $smokeStatus = 'Not run'
  if ($RunSmoke) {
    $smokeOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot 'scripts/smoke-test.ps1') 2>&1
    if ($LASTEXITCODE -ne 0) {
      $smokeStatus = 'Failed'
      throw ($smokeOutput -join [Environment]::NewLine)
    }
    $smokeStatus = 'Passed'
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

  $report = @(
    '# D & J''s Karaoke Readiness Report',
    '',
    "Generated: $((Get-Date).ToString('s'))",
    "Branch: $branch",
    "Commit: $commit",
    "Working tree: $workingTreeState",
    "Smoke status: $smokeStatus",
    '',
    '## Backlog',
    '',
    "Backlog total: $($allTasks.Count)",
    "Checked: $($checkedTasks.Count)",
    "Unchecked: $($uncheckedTasks.Count)",
    '',
    '## Readiness summary',
    '',
    '- The completed backlog count is calculated from docs/MASTER-BACKLOG-577.md.',
    '- The report records the local branch, commit, and working tree state.',
    '- Smoke testing is optional and only runs when -RunSmoke is supplied.',
    '',
    '## Safety summary',
    '',
    '- No media playback is started.',
    '- No display or device settings are changed.',
    '- No router, DNS, firewall, or port settings are changed.',
    '- No API request is made.',
    '- No database is read or written.',
    '- No cloud service is provisioned.',
    '- No face recognition or biometric processing is performed.',
    '',
    '## Operator note',
    '',
    'Use this report as a local readiness snapshot before a pilot or demo. Review any dirty working tree state before sharing results.'
  )

  Set-Content -LiteralPath $outputFullPath -Value $report -Encoding UTF8
  Write-Host "Readiness report generated: $outputFullPath"
} finally {
  Pop-Location
}
