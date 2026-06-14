$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$hqRoot = Join-Path (Join-Path $root 'server') 'hq'
$composeFile = Join-Path (Join-Path $root 'infra/local') 'docker-compose.yml'
$databaseUrl = $env:DATABASE_URL

if (-not $databaseUrl) {
  $databaseUrl = 'postgresql://dandjs_demo:demo_password_placeholder@localhost:15432/dandjs_demo'
}

$docker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $docker) {
  throw 'Docker is required for the live HQ PostgreSQL integration check.'
}

$npm = Get-Command npm -ErrorAction SilentlyContinue
if (-not $npm) {
  throw 'npm is required for the live HQ PostgreSQL integration check.'
}

function Invoke-Checked {
  param(
    [scriptblock]$Command,
    [string]$FailureMessage
  )

  & $Command
  if ($LASTEXITCODE -ne 0) {
    throw $FailureMessage
  }
}

Push-Location $root
try {
  Invoke-Checked { docker compose -f $composeFile up -d hq-db } 'Failed to start local PostgreSQL service.'

  $ready = $false
  for ($attempt = 1; $attempt -le 30; $attempt += 1) {
    docker compose -f $composeFile exec -T hq-db pg_isready -U dandjs_demo -d dandjs_demo | Out-Host
    if ($LASTEXITCODE -eq 0) {
      $ready = $true
      break
    }
    Start-Sleep -Seconds 2
  }

  if (-not $ready) {
    throw 'PostgreSQL did not become ready in time.'
  }

  $env:DATABASE_URL = $databaseUrl
  & (Join-Path $PSScriptRoot 'run-hq-migrations.ps1') -Seed
  & (Join-Path $PSScriptRoot 'run-hq-migrations.ps1') -Seed

  Push-Location $hqRoot
  try {
    npm ci
    if ($LASTEXITCODE -ne 0) {
      throw 'npm ci failed for server/hq.'
    }

    npm run test:postgres
    if ($LASTEXITCODE -ne 0) {
      throw 'PostgreSQL-backed HQ catalog tests failed.'
    }
  } finally {
    Pop-Location
  }
} finally {
  Push-Location $root
  try {
    docker compose -f $composeFile down
  } finally {
    Pop-Location
  }
}

Write-Host 'Live HQ PostgreSQL integration check passed: repeat-safe migrations, protected writes, normalization, audit history, host registration, manifest planning, manifest diffs, and public read safety are covered.'
