function Get-G6DeveloperProfile {
  [CmdletBinding()]
  param([string]$PackageRoot = $PSScriptRoot)
  $metadataPath = Join-Path $PackageRoot 'developer.json'
  if (-not (Test-Path -LiteralPath $metadataPath -PathType Leaf)) { throw 'developer.json is missing from this G6 package.' }
  $profile = Get-Content -Raw -LiteralPath $metadataPath | ConvertFrom-Json
  return Assert-G6DeveloperProfile -Profile $profile
}

function Assert-G6DeveloperProfile {
  [CmdletBinding()]
  param([Parameter(Mandatory=$true)][object]$Profile)
  if ($Profile.Login -notmatch '^g6_(castilla|poma|taco|vera|cueva|lopez)$' -or $Profile.KeyName -notmatch '^g6_[a-z0-9_]+$' -or [int]$Profile.Port -lt 5673 -or [int]$Profile.Port -gt 5678 -or $Profile.Vhost -ne 'g6-productos-ofertas' -or -not $Profile.Services) {
    throw 'developer.json does not contain a valid G6 developer profile.'
  }
  $Profile.Port = [int]$Profile.Port
  return $Profile
}

function Test-G6DeveloperEnvIgnored {
  [CmdletBinding()]
  param([Parameter(Mandatory=$true)][string]$Path)
  $fullPath = [IO.Path]::GetFullPath($Path)
  $directory = Split-Path -Parent $fullPath
  if (-not (Test-Path -LiteralPath $directory -PathType Container)) { return $false }
  $gitRoot = & git.exe -C $directory rev-parse --show-toplevel 2>$null
  if ($LASTEXITCODE -ne 0) { return $true }
  $relative = [IO.Path]::GetRelativePath($gitRoot, $fullPath).Replace('\','/')
  & git.exe -C $gitRoot ls-files --error-unmatch -- $relative *> $null
  if ($LASTEXITCODE -eq 0) { return $false }
  & git.exe -C $gitRoot check-ignore --quiet -- $relative
  return ($LASTEXITCODE -eq 0)
}

function Get-G6PackageInstallFilePlan {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][System.Collections.IDictionary]$Files,
    [Parameter(Mandatory=$true)][object[]]$Credentials,
    [Parameter(Mandatory=$true)][object]$Profile,
    [Parameter(Mandatory=$true)][string]$UserProfile,
    [Parameter(Mandatory=$true)][string]$LocalAppData
  )
  $sshDir = Join-Path $UserProfile '.ssh'
  $localRoot = Join-Path $LocalAppData "G6\RabbitMQ\$($Profile.Login)"
  $destinations = [Collections.Generic.List[string]]::new()
  $destinations.Add([IO.Path]::GetFullPath($localRoot))
  foreach ($name in $Files.Keys) {
    if ($name -in @('developer.json','ssh-config')) { continue }
    if ($name -notmatch '^(ssh|scripts|templates|install)/[A-Za-z0-9._/-]+$' -or $name -match '(^|/)\.\.(/|$)') { throw "Unexpected package member: $name" }
    if ($name -match '^ssh/(.+)$') { $dest = Join-Path $sshDir $Matches[1] }
    elseif ($name -match '^templates/(.+)$') { $dest = Join-Path (Join-Path $localRoot 'templates') $Matches[1] }
    else { $dest = Join-Path $localRoot ($name -replace '^(scripts|install)/','') }
    $destinations.Add([IO.Path]::GetFullPath($dest))
  }
  $destinations.Add([IO.Path]::GetFullPath((Join-Path $localRoot 'developer.json')))
  foreach ($credential in $Credentials) {
    if ($credential.username -notmatch '^g6_[a-z_]+$') { throw 'Invalid credential identity in package.' }
    $destinations.Add([IO.Path]::GetFullPath((Join-Path (Join-Path $localRoot 'secrets') "$($credential.username).clixml")))
  }
  $destinations.Add([IO.Path]::GetFullPath((Join-Path (Join-Path $localRoot 'secrets') 'key-passphrase.clixml')))
  $sshConfig = Join-Path $sshDir 'config'
  if (-not (Test-Path -LiteralPath $sshConfig)) { $destinations.Add([IO.Path]::GetFullPath($sshConfig)) }
  return ,$destinations.ToArray()
}

function Assert-G6PackageInstallFilePlanAvailable {
  [CmdletBinding()]
  param([Parameter(Mandatory=$true)][string[]]$Destinations)
  $collision = $Destinations | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
  if ($collision) { throw "Installation target already exists; refusing to overwrite: $collision" }
}

function Write-G6NewFile {
  [CmdletBinding()]
  param([Parameter(Mandatory=$true)][string]$Path,[Parameter(Mandatory=$true)][byte[]]$Content)
  $stream = [IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
  try { $stream.Write($Content,0,$Content.Length) } finally { $stream.Dispose() }
}

function Export-G6SecureStringNewFile {
  [CmdletBinding()]
  param([Parameter(Mandatory=$true)][Security.SecureString]$Value,[Parameter(Mandatory=$true)][string]$Path)
  $temporaryPath = Join-Path (Split-Path -Parent $Path) ('.g6-dpapi-' + [Guid]::NewGuid().ToString('N') + '.tmp')
  try {
    Export-Clixml -InputObject $Value -LiteralPath $temporaryPath
    [IO.File]::Move($temporaryPath,$Path)
  } finally {
    if (Test-Path -LiteralPath $temporaryPath) { Remove-Item -LiteralPath $temporaryPath -Force }
  }
}
