$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot

function Get-RelativePath {
  param([System.IO.FileInfo]$File)
  return $File.FullName.Substring($root.Length).TrimStart([char[]]@('\', '/'))
}

function Test-IsTextFile {
  param([System.IO.FileInfo]$File)

  $textExtensions = @(
    '.md', '.txt', '.json', '.yml', '.yaml', '.sql', '.ps1', '.psm1', '.psd1',
    '.cs', '.csproj', '.sln', '.props', '.targets', '.js', '.jsx',
    '.ts', '.tsx', '.mjs', '.cjs', '.css', '.html', '.editorconfig',
    '.gitattributes', '.gitignore', '.example'
  )

  if ($textExtensions -contains $File.Extension.ToLowerInvariant()) {
    return $true
  }

  if ($File.Name -in @('.gitignore', '.gitattributes', '.editorconfig')) {
    return $true
  }

  return $false
}

$formatIssues = New-Object System.Collections.Generic.List[string]

$files = Get-ChildItem -LiteralPath $root -Recurse -File -Force |
  Where-Object {
    $relative = (Get-RelativePath $_) -replace '\\', '/'
    $relative -notmatch '(^|/)(\.git|node_modules|bin|obj|artifacts|reports)(/|$)' -and (Test-IsTextFile $_)
  }

foreach ($file in $files) {
  $relative = Get-RelativePath $file
  $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
  if ($bytes.Length -gt 0 -and $bytes[$bytes.Length - 1] -ne 10) {
    $formatIssues.Add("$relative does not end with a newline.")
  }

  $lineNumber = 0
  foreach ($line in [System.IO.File]::ReadAllLines($file.FullName)) {
    $lineNumber += 1
    if ($file.Extension.ToLowerInvariant() -ne '.md' -and $line -match '[ \t]+$') {
      $formatIssues.Add("{0}:{1} has trailing whitespace." -f $relative, $lineNumber)
    }
  }

  if ($file.Extension.ToLowerInvariant() -eq '.json') {
    try {
      Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json | Out-Null
    } catch {
      $node = Get-Command node -ErrorAction SilentlyContinue
      if ($node) {
        node -e "const fs = require('node:fs'); JSON.parse(fs.readFileSync(process.argv[1], 'utf8'));" $file.FullName
        if ($LASTEXITCODE -ne 0) {
          $formatIssues.Add(('{0} is not valid JSON: {1}' -f $relative, $_.Exception.Message))
        }
      } else {
        $formatIssues.Add(('{0} is not valid JSON: {1}' -f $relative, $_.Exception.Message))
      }
    }
  }
}

if ($formatIssues.Count -gt 0) {
  throw "Format check failed: $($formatIssues -join '; ')"
}

$dotnetProjects = Get-ChildItem -LiteralPath $root -Recurse -File -Force |
  Where-Object {
    $_.Extension -in @('.sln', '.csproj') -and
      ((Get-RelativePath $_) -replace '\\', '/') -notmatch '(^|/)(bin|obj)(/|$)'
  }

if ($dotnetProjects) {
  $dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
  if (-not $dotnet) {
    throw '.NET projects are present but dotnet is not available for formatting checks.'
  }

  dotnet format --verify-no-changes --verbosity minimal
  if ($LASTEXITCODE -ne 0) {
    throw 'dotnet format reported formatting issues.'
  }
} else {
  Write-Host 'No .NET projects found; dotnet format check skipped.'
}

Write-Host "Format check passed: text files and JSON files are well formed."
