
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'scripts/generate-readiness-report.ps1',
  'docs/development/runtime-readiness-report-generator.md'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing readiness report generator file: $path"
  }
}

$scriptContent = Get-Content -LiteralPath (Join-Path $root 'scripts/generate-readiness-report.ps1') -Raw
foreach ($forbidden in @(
  'Invoke-WebRequest',
  'Invoke-RestMethod',
  'Start-BitsTransfer',
  'curl ',
  'wget ',
  'psql',
  'sqlite3',
  'sqlcmd'
)) {
  if ($scriptContent -match [regex]::Escape($forbidden)) {
    throw "Readiness report generator must not contain forbidden active integration command: $forbidden"
  }
}

$tempReport = Join-Path $env:TEMP ("dandj-readiness-report-" + [guid]::NewGuid().ToString() + ".md")

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts/generate-readiness-report.ps1') -OutputPath $tempReport

if ($LASTEXITCODE -ne 0) {
  throw 'Readiness report generator exited with a non-zero code.'
}

if (-not (Test-Path -LiteralPath $tempReport -PathType Leaf)) {
  throw 'Readiness report was not generated.'
}

$report = Get-Content -LiteralPath $tempReport -Raw

foreach ($requiredPhrase in @(
  "D & J's Karaoke Readiness Report",
  'Backlog total: 577',
  'Checked: 577',
  'Unchecked: 0',
  'Working tree:',
  'Smoke status: Not run',
  'Safety summary',
  'No media playback is started.',
  'No API request is made.',
  'No database is read or written.',
  'No face recognition or biometric processing is performed.'
)) {
  if ($report -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Generated readiness report is missing phrase: $requiredPhrase"
  }
}

Remove-Item -LiteralPath $tempReport -Force -ErrorAction SilentlyContinue

Write-Host 'Readiness report generator smoke test passed: report generated, backlog counts correct, Git state included, and safety markers are present.'
