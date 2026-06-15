
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/admin-privacy-security-shell.md',
  'admin/security/demo-data/admin-privacy-security-fixtures.json',
  'admin/security/src/admin-privacy-security.html'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing admin privacy security shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'admin/security/demo-data/admin-privacy-security-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'signsOutUsers',
  'rateLimitsLogin',
  'writesSignInAuditLog',
  'writesAdminChangeAuditLog',
  'readsSingerData',
  'exportsSingerProfiles',
  'deletesSingerProfiles',
  'disablesStaffAccounts',
  'storesSecrets',
  'writesSecrets',
  'writesDatabase',
  'createsSessions',
  'destroysSessions'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Admin privacy security guard must remain false: $guard"
  }
}

$html = Get-Content -LiteralPath (Join-Path $root 'admin/security/src/admin-privacy-security.html') -Raw
foreach ($requiredPhrase in @(
  'Sign-out',
  'Failed-login rate limits',
  'Audit logging for sign-ins',
  'Audit logging for administrative changes',
  'Singer-data privacy notes',
  'Data-retention settings',
  'Singer-profile export',
  'Singer-profile deletion workflow',
  'Staff-account disable workflow',
  'Secrets-management documentation',
  'Security smoke tests',
  'No real sign-out',
  'No runtime login rate limiting',
  'No audit writes',
  'No singer-data reads',
  'No singer-profile export',
  'No singer-profile deletion',
  'No staff-account disable',
  'No secrets stored',
  'No database writes',
  'No session creation or destruction'
)) {
  if ($html -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Admin privacy security shell is missing Wave 11B phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/admin-privacy-security-shell.md') -Raw
foreach ($requiredPhrase in @(
  'Wave 11B adds',
  'sign-out preview',
  'failed-login rate-limit preview',
  'audit logging for sign-ins preview',
  'audit logging for administrative changes preview',
  'singer-data privacy notes',
  'data-retention settings preview',
  'singer-profile export preview',
  'singer-profile deletion workflow preview',
  'staff-account disable workflow preview',
  'secrets-management documentation placeholder',
  'security smoke tests'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Admin privacy security doc is missing Wave 11B phrase: $requiredPhrase"
  }
}

Write-Host 'Admin privacy security smoke test passed: sign-out, failed-login limits, audit previews, singer privacy, retention, export, deletion, staff disable, secrets docs, security tests, and safety markers are present.'
