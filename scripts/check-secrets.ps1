$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot

function Get-RelativePath {
  param([System.IO.FileInfo]$File)
  return $File.FullName.Substring($root.Length).TrimStart([char[]]@('\', '/'))
}

function Test-IsTextFile {
  param([System.IO.FileInfo]$File)

  $textExtensions = @(
    '.md', '.txt', '.json', '.yml', '.yaml', '.ps1', '.psm1', '.psd1',
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

$patterns = @(
  @{ Name = 'GitHub token'; Pattern = 'gh[pousr]_[A-Za-z0-9_]{20,}' },
  @{ Name = 'GitHub fine-grained token'; Pattern = 'github_pat_[A-Za-z0-9_]{20,}' },
  @{ Name = 'OpenAI-style API key'; Pattern = 'sk-[A-Za-z0-9]{32,}' },
  @{ Name = 'AWS access key'; Pattern = 'AKIA[0-9A-Z]{16}' },
  @{ Name = 'Private key block'; Pattern = '-----BEGIN ([A-Z ]+ )?PRIVATE KEY-----' },
  @{ Name = 'Secret assignment'; Pattern = '(?i)(password|secret|token|api[_-]?key)\s*[:=]\s*["'']?(?!demo|placeholder|example|local|changeme|tbd|false|true|null)[A-Za-z0-9_./+=:@-]{16,}' }
)

$findings = New-Object System.Collections.Generic.List[string]

$files = Get-ChildItem -LiteralPath $root -Recurse -File -Force |
  Where-Object {
    $relative = (Get-RelativePath $_) -replace '\\', '/'
    $relative -notmatch '(^|/)(\.git|node_modules|bin|obj|artifacts|reports)(/|$)' -and (Test-IsTextFile $_)
  }

foreach ($file in $files) {
  $relative = Get-RelativePath $file
  $lineNumber = 0
  foreach ($line in [System.IO.File]::ReadAllLines($file.FullName)) {
    $lineNumber += 1
    foreach ($pattern in $patterns) {
      if ($line -match $pattern.Pattern) {
        $findings.Add("{0}:{1} matched {2}" -f $relative, $lineNumber, $pattern.Name)
      }
    }
  }
}

if ($findings.Count -gt 0) {
  throw "Potential secrets found: $($findings -join '; ')"
}

Write-Host "Secret scan passed: no high-risk token, key, or secret assignment patterns found."
