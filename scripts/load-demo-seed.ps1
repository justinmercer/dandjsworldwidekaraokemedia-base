param(
  [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$fixtureRoot = Join-Path (Join-Path $root 'tests') 'fixtures'
$seedRoot = Join-Path $fixtureRoot 'demo-seed'
$catalogSeedPath = Join-Path (Join-Path (Join-Path $root 'server') 'hq') 'data/demo-catalog.json'

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
  reason = 'This script summarizes safe demo fixtures only. Use scripts/run-hq-migrations.ps1 -Seed to insert SQL seed metadata.'
  fixtures = @()
  catalog = $null
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

if (Test-Path -LiteralPath $catalogSeedPath -PathType Leaf) {
  $catalog = Get-Content -LiteralPath $catalogSeedPath -Raw | ConvertFrom-Json
  $mediaCount = 0
  foreach ($song in $catalog.songs) {
    $mediaCount += $song.media.Count
  }

  $summary.catalog = [ordered]@{
    file = 'server/hq/data/demo-catalog.json'
    mode = $catalog.mode
    songs = $catalog.songs.Count
    providers = $catalog.providers.Count
    authorizedMediaFiles = $mediaCount
    alternateVersions = $catalog.alternateVersions.Count
  }
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
  New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

$summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host "Demo seed fixtures loaded and summarized at $OutputPath"
