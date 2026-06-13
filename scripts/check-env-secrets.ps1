$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot

function Get-RelativePath {
  param([System.IO.FileInfo]$File)
  return $File.FullName.Substring($root.Length).TrimStart([char[]]@('\', '/'))
}

$allFiles = Get-ChildItem -LiteralPath $root -Recurse -File -Force |
  Where-Object {
    $relative = (Get-RelativePath $_) -replace '\\', '/'
    $relative -notmatch '(^|/)(\.git|node_modules|bin|obj|artifacts|reports)(/|$)'
  }

$nonExampleEnvFiles = $allFiles | Where-Object {
  $_.Name -like '.env*' -and $_.Name -ne '.env.example' -and $_.Name -notlike '*.env.example'
}

if ($nonExampleEnvFiles) {
  $names = ($nonExampleEnvFiles | ForEach-Object { Get-RelativePath $_ }) -join ', '
  throw "Non-example environment files are not allowed in source control: $names"
}

$exampleEnvFiles = $allFiles | Where-Object { $_.Name -eq '.env.example' -or $_.Name -like '*.env.example' }
$badExampleLines = New-Object System.Collections.Generic.List[string]

foreach ($file in $exampleEnvFiles) {
  $lineNumber = 0
  foreach ($line in [System.IO.File]::ReadAllLines($file.FullName)) {
    $lineNumber += 1
    if ($line -match '^\s*#' -or $line -notmatch '=') {
      continue
    }

    $parts = $line.Split('=', 2)
    $name = $parts[0].Trim()
    $value = $parts[1].Trim().Trim('"').Trim("'")
    if ($name -match '(?i)(password|secret|token|api[_-]?key|connection|string)' -and
      $value -and
      $value -notmatch '(?i)(demo|placeholder|example|local|changeme|tbd|false|true|null)') {
      $badExampleLines.Add("{0}:{1}" -f (Get-RelativePath $file), $lineNumber)
    }
  }
}

if ($badExampleLines.Count -gt 0) {
  throw "Environment example files contain secret-like values that are not obvious placeholders: $($badExampleLines -join ', ')"
}

Write-Host "Environment file check passed: only .env.example placeholders are present."
