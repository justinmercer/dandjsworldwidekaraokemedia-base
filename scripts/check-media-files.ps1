$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot

function Get-RelativePath {
  param([System.IO.FileInfo]$File)
  return $File.FullName.Substring($root.Length).TrimStart([char[]]@('\', '/'))
}

$forbiddenExtensions = @(
  '.cdg', '.kar', '.mid', '.midi',
  '.mp3', '.mp4', '.m4a', '.m4v', '.mkv', '.mov', '.avi',
  '.wav', '.flac', '.aac', '.ogg', '.wma', '.wmv', '.vob',
  '.cue', '.lrc', '.srt',
  '.db', '.sqlite', '.sqlite3', '.dump', '.bak', '.backup'
)

$blocked = Get-ChildItem -LiteralPath $root -Recurse -File -Force |
  Where-Object {
    $relative = (Get-RelativePath $_) -replace '\\', '/'
    $relative -notmatch '(^|/)(\.git|node_modules|bin|obj|artifacts|reports)(/|$)' -and
      $forbiddenExtensions -contains $_.Extension.ToLowerInvariant()
  }

if ($blocked) {
  $names = ($blocked | ForEach-Object { Get-RelativePath $_ }) -join ', '
  throw "Forbidden media, database, subtitle, backup, or dump files found: $names"
}

Write-Host "Media file block passed: no forbidden media, database, subtitle, backup, or dump files found."
