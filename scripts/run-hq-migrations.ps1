param(
  [string]$DatabaseUrl = $env:DATABASE_URL,
  [switch]$Seed
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$hqRoot = Join-Path (Join-Path $root 'server') 'hq'
$migrationRoot = Join-Path (Join-Path $hqRoot 'database') 'migrations'
$seedRoot = Join-Path (Join-Path $hqRoot 'database') 'seeds'

if (-not $DatabaseUrl) {
  throw 'Set DATABASE_URL or pass -DatabaseUrl to run HQ catalog migrations.'
}

$psql = Get-Command psql -ErrorAction SilentlyContinue
if (-not $psql) {
  throw 'psql is required to run HQ catalog migrations.'
}

$migrationFiles = Get-ChildItem -LiteralPath $migrationRoot -Filter '*.sql' -File | Sort-Object Name
if ($migrationFiles.Count -eq 0) {
  throw 'No HQ catalog migration files were found.'
}

foreach ($migration in $migrationFiles) {
  psql $DatabaseUrl -v ON_ERROR_STOP=1 -f $migration.FullName
  if ($LASTEXITCODE -ne 0) {
    throw "HQ catalog migration failed: $($migration.Name)"
  }
}

if ($Seed) {
  $seedFiles = Get-ChildItem -LiteralPath $seedRoot -Filter '*.sql' -File | Sort-Object Name
  foreach ($seed in $seedFiles) {
    psql $DatabaseUrl -v ON_ERROR_STOP=1 -f $seed.FullName
    if ($LASTEXITCODE -ne 0) {
      throw "HQ catalog seed failed: $($seed.Name)"
    }
  }
}

Write-Host 'HQ catalog migrations completed.'
