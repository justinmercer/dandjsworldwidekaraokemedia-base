$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$composeFile = Join-Path (Join-Path $root 'infra/local') 'docker-compose.yml'

if (-not (Test-Path -LiteralPath $composeFile -PathType Leaf)) {
  throw 'Missing local Docker Compose file.'
}

$docker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $docker) {
  Write-Host 'Docker is not available; Docker Compose syntax validation skipped.'
  exit 0
}

docker compose version | Out-Host
if ($LASTEXITCODE -ne 0) {
  throw 'Docker is available but the Compose plugin is not working.'
}

docker compose -f $composeFile config --quiet
if ($LASTEXITCODE -ne 0) {
  throw 'Docker Compose config validation failed.'
}

Write-Host 'Docker Compose syntax validation passed.'
