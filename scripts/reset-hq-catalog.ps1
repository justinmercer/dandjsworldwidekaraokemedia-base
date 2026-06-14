param(
  [string]$DatabaseUrl = $env:DATABASE_URL,
  [switch]$Seed,
  [switch]$ConfirmReset
)

$ErrorActionPreference = 'Stop'

if (-not $DatabaseUrl) {
  throw 'Set DATABASE_URL or pass -DatabaseUrl to reset the HQ catalog database.'
}

if (-not $ConfirmReset) {
  throw 'Pass -ConfirmReset to drop and rebuild the development HQ catalog schema.'
}

$psql = Get-Command psql -ErrorAction SilentlyContinue
if (-not $psql) {
  throw 'psql is required to reset the HQ catalog database.'
}

psql $DatabaseUrl -v ON_ERROR_STOP=1 -c 'DROP SCHEMA IF EXISTS hq_catalog CASCADE;'
if ($LASTEXITCODE -ne 0) {
  throw 'Failed to drop the development HQ catalog schema.'
}

& (Join-Path $PSScriptRoot 'run-hq-migrations.ps1') -DatabaseUrl $DatabaseUrl -Seed:$Seed
Write-Host 'Development HQ catalog schema reset completed.'
