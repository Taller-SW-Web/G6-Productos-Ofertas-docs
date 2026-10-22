function Get-G6DeveloperProfileCatalog {
  [CmdletBinding()]
  param()
  return @(
    [pscustomobject]@{ Developer='Castilla'; Login='g6_castilla'; KeyName='g6_castilla_dist'; Services=@('g6_masivos','g6_combos'); Port=5673 },
    [pscustomobject]@{ Developer='Poma'; Login='g6_poma'; KeyName='g6_poma'; Services=@('g6_catalogo'); Port=5674 },
    [pscustomobject]@{ Developer='Taco'; Login='g6_taco'; KeyName='g6_taco'; Services=@('g6_inventario'); Port=5675 },
    [pscustomobject]@{ Developer='Vera'; Login='g6_vera'; KeyName='g6_vera'; Services=@('g6_precios','g6_auditoria_precios'); Port=5676 },
    [pscustomobject]@{ Developer='Cueva'; Login='g6_cueva'; KeyName='g6_cueva'; Services=@('g6_promociones'); Port=5677 },
    [pscustomobject]@{ Developer='López'; Login='g6_lopez'; KeyName='g6_lopez'; Services=@('g6_taxonomia'); Port=5678 }
  )
}

function Get-G6PrivateAclPrincipals {
  $current = [Security.Principal.WindowsIdentity]::GetCurrent().User
  if (-not $current) { throw 'Could not resolve the effective Windows identity.' }
  return @($current.Value,'S-1-5-18')
}

function Assert-G6PrivateAcl {
  [CmdletBinding()]
  param([Parameter(Mandatory=$true)][string]$Path)
  $acl = Get-Acl -LiteralPath $Path
  $allowed = @(Get-G6PrivateAclPrincipals)
  $currentSid = $allowed[0]
  $ownerSid = $acl.GetOwner([Security.Principal.SecurityIdentifier]).Value
  if (-not $acl.AreAccessRulesProtected -or $ownerSid -ne $currentSid) { throw 'Protected onboarding path has unexpected inheritance or owner; no ACL was changed.' }
  $rules = @($acl.GetAccessRules($true,$true,[Security.Principal.SecurityIdentifier]))
  $fullControl = [int][Security.AccessControl.FileSystemRights]::FullControl
  foreach ($rule in $rules) {
    $rights = [int]$rule.FileSystemRights
    if ($rule.AccessControlType -ne [Security.AccessControl.AccessControlType]::Allow -or $rule.IdentityReference.Value -notin $allowed -or ($rights -band (-bnot $fullControl)) -ne 0) {
      throw "Protected onboarding path has an unexpected ACL entry for SID $($rule.IdentityReference.Value) with access type $($rule.AccessControlType) and rights mask $rights; no ACL was changed."
    }
  }
  foreach ($sid in $allowed) {
    $principalRights = 0
    foreach ($rule in @($rules | Where-Object { $_.IdentityReference.Value -eq $sid })) { $principalRights = $principalRights -bor [int]$rule.FileSystemRights }
    if (($principalRights -band $fullControl) -ne $fullControl) {
      throw 'Protected onboarding path is missing a required ACL; no ACL was changed.'
    }
  }
  return $true
}

function Set-G6PrivateAclOnNewPath {
  [CmdletBinding()]
  param([Parameter(Mandatory=$true)][string]$Path,[switch]$Directory)
  $principals = @(Get-G6PrivateAclPrincipals)
  $scope = if ($Directory) { '(OI)(CI)' } else { '' }
  $currentRule="*$($principals[0]):${scope}F"
  $systemRule="*$($principals[1]):${scope}F"
  & icacls.exe $Path /inheritance:r /remove:g '*S-1-5-32-544' '*S-1-5-32-545' '*S-1-5-11' '*S-1-1-0' /grant:r $currentRule $systemRule | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'Could not set the ACL on a newly created onboarding path.' }
  Assert-G6PrivateAcl -Path $Path | Out-Null
}

function Ensure-G6PrivateDirectory {
  [CmdletBinding()]
  param([Parameter(Mandatory=$true)][string]$Path)
  if (Test-Path -LiteralPath $Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { throw 'Expected protected onboarding directory is not a directory.' }
    Assert-G6PrivateAcl -Path $Path | Out-Null
    return
  }
  $null = New-Item -ItemType Directory -Path $Path
  Set-G6PrivateAclOnNewPath -Path $Path -Directory | Out-Null
}

function Write-G6PrivateFileAtomically {
  [CmdletBinding()]
  param([Parameter(Mandatory=$true)][string]$Path,[Parameter(Mandatory=$true)][byte[]]$Content)
  $parent = Split-Path -Parent $Path
  $temporary = Join-Path $parent ('.g6-private-' + [Guid]::NewGuid().ToString('N') + '.tmp')
  try {
    $stream = [IO.File]::Open($temporary,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try { $stream.Write($Content,0,$Content.Length) } finally { $stream.Dispose() }
    Set-G6PrivateAclOnNewPath -Path $temporary | Out-Null
    if (Test-Path -LiteralPath $Path) {
      Assert-G6PrivateAcl -Path $Path | Out-Null
      $replacementBackup="$Path.g6-replace-$([Guid]::NewGuid().ToString('N'))"
      [IO.File]::Replace($temporary,$Path,$replacementBackup,$true)
      try { Assert-G6PrivateAcl -Path $replacementBackup | Out-Null }
      finally { if (Test-Path -LiteralPath $replacementBackup) { Remove-Item -LiteralPath $replacementBackup -Force } }
    } else { [IO.File]::Move($temporary,$Path) }
    Assert-G6PrivateAcl -Path $Path | Out-Null
  } finally {
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
  }
}

function Set-G6VerifiedOnboardingState {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][string]$VaultPath,
    [Parameter(Mandatory=$true)][ValidateSet('AccountCreated','PublicKeyRegistered','TunnelTestedFromAdminPc')][string]$Field,
    [Parameter(Mandatory=$true)][string]$Login
  )
  Assert-G6PrivateAcl -Path $VaultPath | Out-Null
  $vault = Get-Content -Raw -LiteralPath $VaultPath | ConvertFrom-Json
  $entries = @($vault.developers | Where-Object Login -CEQ $Login)
  if ($entries.Count -ne 1) { throw 'Onboarding inventory does not contain exactly one matching developer.' }
  $entries[0].$Field = $true
  $entries[0] | Add-Member -NotePropertyName "${Field}VerifiedUtc" -NotePropertyValue ([DateTime]::UtcNow.ToString('o')) -Force
  $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($vault | ConvertTo-Json -Depth 10))
  try { Write-G6PrivateFileAtomically -Path $VaultPath -Content $bytes } finally { [Security.Cryptography.CryptographicOperations]::ZeroMemory($bytes) }
}

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
  Set-G6PrivateAclOnNewPath -Path $Path | Out-Null
}

function Export-G6SecureStringNewFile {
  [CmdletBinding()]
  param([Parameter(Mandatory=$true)][Security.SecureString]$Value,[Parameter(Mandatory=$true)][string]$Path)
  $temporaryPath = Join-Path (Split-Path -Parent $Path) ('.g6-dpapi-' + [Guid]::NewGuid().ToString('N') + '.tmp')
  try {
    Export-Clixml -InputObject $Value -LiteralPath $temporaryPath
    Set-G6PrivateAclOnNewPath -Path $temporaryPath | Out-Null
    [IO.File]::Move($temporaryPath,$Path)
  } finally {
    if (Test-Path -LiteralPath $temporaryPath) { Remove-Item -LiteralPath $temporaryPath -Force }
  }
}
