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

function Invoke-PsqlScalar {
  param([string]$Sql)

  $output = psql $DatabaseUrl -v ON_ERROR_STOP=1 -t -A -c $Sql
  if ($LASTEXITCODE -ne 0) {
    throw "psql scalar query failed: $Sql"
  }

  return ($output | Where-Object { $_ -and $_.Trim() } | Select-Object -First 1).Trim()
}

function Test-MigrationTrackingTableExists {
  $result = Invoke-PsqlScalar "SELECT CASE WHEN to_regclass('hq_catalog.schema_migrations') IS NULL THEN '0' ELSE '1' END;"
  return $result -eq '1'
}

function Test-MigrationApplied {
  param([string]$Version)

  if (-not (Test-MigrationTrackingTableExists)) {
    return $false
  }

  $result = Invoke-PsqlScalar "SELECT CASE WHEN EXISTS (SELECT 1 FROM hq_catalog.schema_migrations WHERE version = '$Version') THEN '1' ELSE '0' END;"
  return $result -eq '1'
}

foreach ($migration in $migrationFiles) {
  if ($migration.BaseName -notmatch '^([0-9]+)') {
    throw "HQ catalog migration file name must start with a numeric version: $($migration.Name)"
  }

  $version = $Matches[1]
  if (Test-MigrationApplied $version) {
    Write-Host "Skipping already-applied HQ catalog migration $($migration.Name)."
    continue
  }

  psql $DatabaseUrl -v ON_ERROR_STOP=1 -f $migration.FullName
  if ($LASTEXITCODE -ne 0) {
    throw "HQ catalog migration failed: $($migration.Name)"
  }

  if (-not (Test-MigrationApplied $version)) {
    throw "HQ catalog migration $($migration.Name) did not record schema_migrations version $version."
  }
}

foreach ($migration in $migrationFiles) {
  $migration.BaseName -match '^([0-9]+)' | Out-Null
  $version = $Matches[1]
  if (-not (Test-MigrationApplied $version)) {
    throw "HQ catalog migration tracking verification failed for version $version."
  }
}

if ($Seed) {
  $seedFiles = Get-ChildItem -LiteralPath $seedRoot -Filter '*.sql' -File | Sort-Object Name
  foreach ($seedFile in $seedFiles) {
    psql $DatabaseUrl -v ON_ERROR_STOP=1 -f $seedFile.FullName
    if ($LASTEXITCODE -ne 0) {
      throw "HQ catalog seed failed: $($seedFile.Name)"
    }
  }
}

Write-Host 'HQ catalog migrations completed.'
