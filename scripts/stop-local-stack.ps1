$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$composeFile = Join-Path (Join-Path $root 'infra/local') 'docker-compose.yml'

if (-not (Test-Path -LiteralPath $composeFile -PathType Leaf)) {
  throw 'Missing local Docker Compose file.'
}

$docker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $docker) {
  throw 'Docker is required to stop the local stack.'
}

docker compose -f $composeFile down
if ($LASTEXITCODE -ne 0) {
  throw 'Docker Compose failed to stop the local stack.'
}
Write-Host 'Local development stack stopped.'
