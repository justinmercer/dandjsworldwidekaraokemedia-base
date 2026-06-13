param(
  [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$fixtureRoot = Join-Path (Join-Path $root 'tests') 'fixtures'
$seedRoot = Join-Path $fixtureRoot 'demo-seed'

if (-not $OutputPath) {
  $OutputPath = Join-Path (Join-Path $root 'artifacts') 'demo-seed'
  $OutputPath = Join-Path $OutputPath 'seed-summary.json'
}

if (-not (Test-Path -LiteralPath $seedRoot -PathType Container)) {
  throw 'Missing demo seed fixture directory.'
}

$fixtureFiles = Get-ChildItem -LiteralPath $seedRoot -Filter '*.json' -File
if ($fixtureFiles.Count -eq 0) {
  throw 'No demo seed fixture files found.'
}

$summary = [ordered]@{
  generatedAt = (Get-Date).ToUniversalTime().ToString('o')
  mode = 'development-only'
  insertedIntoDatabase = $false
  reason = 'Wave 0B has no database schema or HQ API implementation.'
  fixtures = @()
}

foreach ($fixtureFile in $fixtureFiles) {
  $json = Get-Content -LiteralPath $fixtureFile.FullName -Raw | ConvertFrom-Json
  $count = 1
  if ($json -is [System.Array]) {
    $count = $json.Count
  }

  $summary.fixtures += [ordered]@{
    file = $fixtureFile.Name
    recordCount = $count
  }
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
  New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

$summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host "Demo seed fixtures loaded and summarized at $OutputPath"
