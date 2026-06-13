$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$requestWebRoot = Join-Path $root 'apps/request-web'
$proxyPath = Join-Path $requestWebRoot 'dev-proxy.config.json'

if (-not (Test-Path -LiteralPath $proxyPath -PathType Leaf)) {
  throw 'Missing request-web development proxy configuration.'
}

$proxy = Get-Content -LiteralPath $proxyPath -Raw | ConvertFrom-Json
if ($proxy.mode -ne 'development-only') {
  throw 'Request-web proxy config must be marked development-only.'
}

foreach ($route in $proxy.proxies) {
  if ($route.target -notlike 'http://localhost:*' -and $route.target -notlike 'http://127.0.0.1:*') {
    throw "Proxy target must stay local-only. Invalid target: $($route.target)"
  }
}

$packagePath = Join-Path $requestWebRoot 'package.json'
if (Test-Path -LiteralPath $packagePath -PathType Leaf) {
  $npm = Get-Command npm -ErrorAction SilentlyContinue
  if (-not $npm) {
    throw 'apps/request-web/package.json exists but npm is not available for web linting.'
  }

  Push-Location $requestWebRoot
  try {
    npm run lint --if-present
    if ($LASTEXITCODE -ne 0) {
      throw 'npm lint failed for apps/request-web.'
    }
  } finally {
    Pop-Location
  }
} else {
  Write-Host 'No request-web package.json found; web lint command skipped until the UI project exists.'
}

Write-Host 'Web lint foundation check passed.'
