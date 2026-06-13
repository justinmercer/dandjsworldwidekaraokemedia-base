$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot

function Get-RelativePath {
  param([System.IO.FileInfo]$File)
  return $File.FullName.Substring($root.Length).TrimStart([char[]]@('\', '/'))
}

$dotnetFiles = Get-ChildItem -LiteralPath $root -Recurse -File -Force |
  Where-Object {
    $_.Extension -in @('.sln', '.csproj') -and
      ((Get-RelativePath $_) -replace '\\', '/') -notmatch '(^|/)(bin|obj)(/|$)'
  }

if ($dotnetFiles) {
  $dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
  if (-not $dotnet) {
    throw '.NET build files are present but dotnet is not available.'
  }

  $solutions = $dotnetFiles | Where-Object { $_.Extension -eq '.sln' }
  if ($solutions) {
    foreach ($solution in $solutions) {
      dotnet build $solution.FullName --configuration Release
      if ($LASTEXITCODE -ne 0) {
        throw "dotnet build failed for $(Get-RelativePath $solution)."
      }
    }
  } else {
    foreach ($project in ($dotnetFiles | Where-Object { $_.Extension -eq '.csproj' })) {
      dotnet build $project.FullName --configuration Release
      if ($LASTEXITCODE -ne 0) {
        throw "dotnet build failed for $(Get-RelativePath $project)."
      }
    }
  }

  $testProjects = $dotnetFiles | Where-Object { $_.Name -match '(?i)test' -and $_.Extension -eq '.csproj' }
  foreach ($testProject in $testProjects) {
    dotnet test $testProject.FullName --configuration Release --no-build
    if ($LASTEXITCODE -ne 0) {
      throw "dotnet test failed for $(Get-RelativePath $testProject)."
    }
  }
} else {
  Write-Host 'No .NET solution or project files found; .NET build/test skipped.'
}

$packageFiles = Get-ChildItem -LiteralPath $root -Recurse -File -Filter 'package.json' -Force |
  Where-Object { ((Get-RelativePath $_) -replace '\\', '/') -notmatch '(^|/)(node_modules|dist|build|coverage)(/|$)' }

if ($packageFiles) {
  $npm = Get-Command npm -ErrorAction SilentlyContinue
  if (-not $npm) {
    throw 'Node package files are present but npm is not available.'
  }

  foreach ($packageFile in $packageFiles) {
    Push-Location $packageFile.DirectoryName
    try {
      npm run build --if-present
      if ($LASTEXITCODE -ne 0) {
        throw "npm build failed for $(Get-RelativePath $packageFile)."
      }
      npm test --if-present
      if ($LASTEXITCODE -ne 0) {
        throw "npm test failed for $(Get-RelativePath $packageFile)."
      }
    } finally {
      Pop-Location
    }
  }
} else {
  Write-Host 'No package.json files found; Node build/test skipped.'
}

& (Join-Path $PSScriptRoot 'validate-contracts.ps1')

Write-Host 'Build/test foundation check passed.'
