param(
  [string]$DatabaseUrl = $env:DATABASE_URL,
  [switch]$ResetFirst
)

$ErrorActionPreference = 'Stop'

if (-not $DatabaseUrl) {
  throw 'Set DATABASE_URL or pass -DatabaseUrl to reseed the HQ catalog database.'
}

if ($ResetFirst) {
  & (Join-Path $PSScriptRoot 'reset-hq-catalog.ps1') -DatabaseUrl $DatabaseUrl -Seed -ConfirmReset
} else {
  & (Join-Path $PSScriptRoot 'run-hq-migrations.ps1') -DatabaseUrl $DatabaseUrl -Seed
}

Write-Host 'Development HQ catalog reseed completed.'
