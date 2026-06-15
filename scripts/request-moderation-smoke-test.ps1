
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/request-moderation-shell.md',
  'request/moderation/demo-data/incoming-request-fixtures.json',
  'request/moderation/src/index.html'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing request moderation shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'request/moderation/demo-data/incoming-request-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'writesQueueRecords',
  'writesSingerRecords',
  'approvesRealRequests',
  'editsRealRequests',
  'rejectsRealRequests',
  'addsAllToQueue',
  'callsServerApis',
  'storesPersonalData'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Request moderation fixture guard must remain false: $guard"
  }
}

$html = Get-Content -LiteralPath (Join-Path $root 'request/moderation/src/index.html') -Raw
foreach ($requiredPhrase in @(
  'Incoming-request model',
  'Host-side incoming-request list',
  'Approve action preview',
  'Edit action preview',
  'Reject action preview',
  'Add-all action preview',
  'Singer-match suggestions',
  'Duplicate-request detection',
  'Per-singer request limits',
  'Host override for request limits',
  'No server API calls'
)) {
  if ($html -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Request moderation shell is missing Wave 8A phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/request-moderation-shell.md') -Raw
foreach ($requiredPhrase in @(
  'Wave 8A starts',
  'incoming-request model fixture',
  'host-side incoming-request list preview',
  'approve action preview',
  'edit action preview',
  'reject action preview',
  'add-all action preview',
  'singer-match suggestion preview',
  'duplicate-request detection preview',
  'per-singer request-limit preview',
  'host override for request limits preview'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Request moderation doc is missing Wave 8A phrase: $requiredPhrase"
  }
}

Write-Host 'Request moderation smoke test passed: incoming model, host list, approve/edit/reject/add-all previews, singer match, duplicates, limits, override, and safety markers are present.'
