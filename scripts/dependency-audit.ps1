$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot

function Get-RelativePath {
  param([System.IO.FileInfo]$File)
  return $File.FullName.Substring($root.Length).TrimStart([char[]]@('\', '/'))
}

$packageLocks = Get-ChildItem -LiteralPath $root -Recurse -File -Filter 'package-lock.json' -Force |
  Where-Object { ((Get-RelativePath $_) -replace '\\', '/') -notmatch '(^|/)(node_modules|dist|build|coverage)(/|$)' }

if ($packageLocks) {
  $npm = Get-Command npm -ErrorAction SilentlyContinue
  if (-not $npm) {
    throw 'package-lock.json files are present but npm is not available for vulnerability scanning.'
  }

  foreach ($lock in $packageLocks) {
    Push-Location $lock.DirectoryName
    try {
      npm audit --audit-level=moderate
      if ($LASTEXITCODE -ne 0) {
        throw "npm audit failed for $(Get-RelativePath $lock)."
      }
    } finally {
      Pop-Location
    }
  }
} else {
  Write-Host 'No package-lock.json files found; npm vulnerability scan skipped.'
}

$projectFiles = Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.csproj' -Force |
  Where-Object { ((Get-RelativePath $_) -replace '\\', '/') -notmatch '(^|/)(bin|obj)(/|$)' }

if ($projectFiles) {
  $dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
  if (-not $dotnet) {
    throw '.NET project files are present but dotnet is not available for vulnerability scanning.'
  }

  foreach ($project in $projectFiles) {
    dotnet list $project.FullName package --vulnerable --include-transitive
    if ($LASTEXITCODE -ne 0) {
      throw "dotnet vulnerability scan failed for $(Get-RelativePath $project)."
    }
  }
} else {
  Write-Host 'No .NET project files found; .NET vulnerability scan skipped.'
}

Write-Host 'Dependency vulnerability scan completed for available dependency manifests.'
