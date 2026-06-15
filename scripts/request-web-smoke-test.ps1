
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$smokeScripts = @(
  'request-web-shell-smoke-test.ps1',
  'request-workflow-smoke-test.ps1',
  'request-session-status-smoke-test.ps1',
  'mobile-pwa-kiosk-smoke-test.ps1',
  'kiosk-session-smoke-test.ps1'
)

foreach ($scriptName in $smokeScripts) {
  & (Join-Path $PSScriptRoot $scriptName)
}

Write-Host 'Request web aggregate smoke test passed: all request web shell smoke checks completed.'
