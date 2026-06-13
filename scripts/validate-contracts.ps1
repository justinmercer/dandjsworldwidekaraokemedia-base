$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$schemaRoot = Join-Path (Join-Path $root 'packages') 'contracts'
$schemaRoot = Join-Path $schemaRoot 'schemas'

if (-not (Test-Path -LiteralPath $schemaRoot -PathType Container)) {
  throw 'Missing shared contract schema directory.'
}

$schemas = Get-ChildItem -LiteralPath $schemaRoot -Filter '*.schema.json' -File
if ($schemas.Count -lt 14) {
  throw "Expected at least 14 shared contract schemas, found $($schemas.Count)."
}

$issues = New-Object System.Collections.Generic.List[string]

foreach ($schemaFile in $schemas) {
  try {
    $schema = Get-Content -LiteralPath $schemaFile.FullName -Raw | ConvertFrom-Json
  } catch {
    $issues.Add("$($schemaFile.Name) is not valid JSON: $($_.Exception.Message)")
    continue
  }

  if (-not $schema.'$schema') {
    $issues.Add("$($schemaFile.Name) is missing `$schema.")
  }
  if (-not $schema.'$id' -or $schema.'$id' -notmatch '/v1/') {
    $issues.Add("$($schemaFile.Name) must include a v1 `$id.")
  }
  if (-not $schema.title) {
    $issues.Add("$($schemaFile.Name) is missing title.")
  }
  if ($schema.type -ne 'object') {
    $issues.Add("$($schemaFile.Name) must define an object schema.")
  }
  if (-not $schema.properties -or -not $schema.properties.contractVersion -or $schema.properties.contractVersion.const -ne 'v1') {
    $issues.Add("$($schemaFile.Name) must define contractVersion const v1.")
  }
  if (-not $schema.required -or $schema.required -notcontains 'contractVersion') {
    $issues.Add("$($schemaFile.Name) must require contractVersion.")
  }
}

if ($issues.Count -gt 0) {
  throw "Contract validation failed: $($issues -join '; ')"
}

Write-Host "Contract validation passed: $($schemas.Count) v1 JSON schemas are well formed."
