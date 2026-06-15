
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/admin-auth-security-shell.md',
  'admin/security/demo-data/admin-auth-security-fixtures.json',
  'admin/security/src/admin-auth-security.html'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing admin auth security shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'admin/security/demo-data/admin-auth-security-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'implementsAuthentication',
  'hashesPasswords',
  'storesPasswords',
  'storesSecrets',
  'createsSessions',
  'writesUsers',
  'writesDatabase',
  'protectsRuntimeRoutes',
  'accessesBackups',
  'changesHostDevices'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Admin auth security guard must remain false: $guard"
  }
}

$html = Get-Content -LiteralPath (Join-Path $root 'admin/security/src/admin-auth-security.html') -Raw
foreach ($requiredPhrase in @(
  'Basic admin sign-in',
  'Host role',
  'Admin role',
  'Read-only staff role',
  'Protected admin-only routes',
  'Protected catalog-management routes',
  'Protected venue-settings routes',
  'Protected backup routes',
  'Protected host-device-management routes',
  'Password hashing placeholder',
  'Development-safe initial setup flow',
  'Password-change flow',
  'Require password update after first sign-in',
  'Session expiration',
  'No real authentication',
  'No password hashing implementation',
  'No passwords or secrets',
  'No session creation',
  'No database writes',
  'No protected route runtime',
  'No backup access',
  'No host-device changes'
)) {
  if ($html -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Admin auth security shell is missing Wave 11A phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/admin-auth-security-shell.md') -Raw
foreach ($requiredPhrase in @(
  'Wave 11A adds',
  'basic admin sign-in preview',
  'host role preview',
  'admin role preview',
  'read-only staff role preview',
  'protected admin-only routes preview',
  'protected catalog-management routes preview',
  'protected venue-settings routes preview',
  'protected backup routes preview',
  'protected host-device-management routes preview',
  'password hashing placeholder',
  'development-safe initial setup flow preview',
  'password-change flow preview',
  'require password update after first sign-in preview',
  'session expiration preview'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Admin auth security doc is missing Wave 11A phrase: $requiredPhrase"
  }
}

Write-Host 'Admin auth security smoke test passed: sign-in, roles, protected route previews, password placeholders, setup, password-change, first-login update, session expiration, and safety markers are present.'
