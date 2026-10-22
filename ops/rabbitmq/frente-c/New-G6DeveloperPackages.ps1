#requires -Version 7.0
[CmdletBinding()]
param(
  [string]$Root = (Join-Path $env:LOCALAPPDATA 'G6\RabbitMQ\onboarding'),
  [string]$CredentialVaultPath = (Join-Path $env:LOCALAPPDATA 'G6\RabbitMQ\frontb-credentials.dpapi.json'),
  [string]$ManifestPath = (Join-Path $PSScriptRoot '..\rbac-rc3.json'),
  [ValidateRange(0,6)][int]$TestOnlyFailAfterCandidates = 0,
  [ValidateRange(0,12)][int]$TestOnlyFailDuringCommitAfter = 0
)
$ErrorActionPreference='Stop'
$iterations=600000
. (Join-Path $PSScriptRoot 'G6DeveloperProfile.ps1')

function Write-NewPrivateBytes {
  param([string]$Path,[byte[]]$Bytes)
  $stream=[IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
  try { $stream.Write($Bytes,0,$Bytes.Length) } finally { $stream.Dispose() }
  Set-G6PrivateAclOnNewPath -Path $Path | Out-Null
}

function Move-VerifiedPrivateFile {
  param([string]$Source,[string]$Destination)
  Assert-G6PrivateAcl -Path $Source | Out-Null
  if (Test-Path -LiteralPath $Destination) {
    Assert-G6PrivateAcl -Path $Destination | Out-Null
    $replacementBackup="$Destination.g6-replace-$([Guid]::NewGuid().ToString('N'))"
    [IO.File]::Replace($Source,$Destination,$replacementBackup,$true)
    try { Assert-G6PrivateAcl -Path $replacementBackup | Out-Null }
    finally { if (Test-Path -LiteralPath $replacementBackup) { Remove-Item -LiteralPath $replacementBackup -Force } }
  } else { [IO.File]::Move($Source,$Destination) }
  Assert-G6PrivateAcl -Path $Destination | Out-Null
}

function Add-ZipBytes {
  param([IO.Compression.ZipArchive]$Archive,[string]$Name,[byte[]]$Bytes)
  $entry=$Archive.CreateEntry($Name,[IO.Compression.CompressionLevel]::Optimal)
  $stream=$entry.Open()
  try { $stream.Write($Bytes,0,$Bytes.Length) } finally { $stream.Dispose() }
}

function Assert-CandidatePackage {
  param([string]$PayloadPath,[string]$Passphrase,[object]$Profile,[string[]]$AssignedIdentities)
  $bytes=[IO.File]::ReadAllBytes($PayloadPath)
  $plain=$null; $derived=$null; $aes=$null; $archive=$null; $memory=$null
  try {
    if ($bytes.Length -lt 54 -or [Text.Encoding]::ASCII.GetString($bytes,0,5) -cne 'G6PK1') { throw 'Candidate package header is invalid.' }
    $salt=[byte[]]::new(16); [Array]::Copy($bytes,5,$salt,0,16)
    $rounds=[BitConverter]::ToInt32($bytes,21)
    if ($rounds -ne $iterations) { throw 'Candidate package KDF metadata is invalid.' }
    $nonce=[byte[]]::new(12); [Array]::Copy($bytes,25,$nonce,0,12)
    $cipherLength=$bytes.Length-37-16
    if ($cipherLength -le 0) { throw 'Candidate package ciphertext is empty.' }
    $cipher=[byte[]]::new($cipherLength); [Array]::Copy($bytes,37,$cipher,0,$cipherLength)
    $tag=[byte[]]::new(16); [Array]::Copy($bytes,$bytes.Length-16,$tag,0,16)
    $header=[byte[]]::new(37); [Array]::Copy($bytes,0,$header,0,37)
    $derived=[Security.Cryptography.Rfc2898DeriveBytes]::Pbkdf2($Passphrase,$salt,$rounds,[Security.Cryptography.HashAlgorithmName]::SHA256,32)
    $plain=[byte[]]::new($cipherLength); $aes=[Security.Cryptography.AesGcm]::new($derived,16)
    $aes.Decrypt($nonce,$cipher,$tag,$plain,$header)
    $memory=[IO.MemoryStream]::new($plain,$false)
    $archive=[IO.Compression.ZipArchive]::new($memory,[IO.Compression.ZipArchiveMode]::Read,$false)
    $entries=@{}; foreach ($entry in $archive.Entries) { if ($entries.ContainsKey($entry.FullName)) { throw 'Candidate package contains a duplicate member.' }; $entries[$entry.FullName]=$entry }
    $required=@('developer.json','ssh-config',"ssh/$($Profile.KeyName)","ssh/$($Profile.KeyName).pub",'scripts/Start-G6RabbitMqTunnel.ps1','scripts/Test-G6RabbitMqTunnel.ps1','scripts/Test-G6DeveloperAccess.ps1','scripts/Set-G6DeveloperRabbitMqUrl.ps1','scripts/G6DeveloperProfile.ps1','scripts/verify-pilot-amqp.mjs','scripts/rbac-rc3.json','install/Install-G6DeveloperPackage.ps1','install/README.txt','secrets/credentials.json')
    foreach ($name in $required) { if (-not $entries.ContainsKey($name)) { throw 'Candidate package is missing a required member.' } }
    $reader=[IO.StreamReader]::new($entries['developer.json'].Open(),[Text.Encoding]::UTF8,$true)
    try { $metadata=$reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
    if ($metadata.Login -cne $Profile.Login -or $metadata.KeyName -cne $Profile.KeyName -or [int]$metadata.Port -ne [int]$Profile.Port -or $metadata.Vhost -cne 'g6-productos-ofertas' -or @(Compare-Object @($metadata.Services) $AssignedIdentities).Count -ne 0) { throw 'Candidate package metadata does not match the assigned profile.' }
    $credentialReader=[IO.StreamReader]::new($entries['secrets/credentials.json'].Open(),[Text.Encoding]::UTF8,$true)
    try { $credentials=@($credentialReader.ReadToEnd() | ConvertFrom-Json) } finally { $credentialReader.Dispose() }
    if (@(Compare-Object $AssignedIdentities @($credentials.username)).Count -ne 0 -or @($credentials.username | Select-Object -Unique).Count -ne $AssignedIdentities.Count -or @($credentials | Where-Object { $_.vhost -cne 'g6-productos-ofertas' -or [string]::IsNullOrEmpty($_.password) }).Count -gt 0) { throw 'Candidate package credentials do not match the assigned identities.' }
    foreach ($credential in $credentials) { $credential.password=$null }
    $credentials=$null
    return $true
  } catch { throw 'Candidate package authentication, metadata, or structure validation failed; details omitted.' }
  finally {
    if ($archive) { $archive.Dispose() }; if ($memory) { $memory.Dispose() }; if ($aes) { $aes.Dispose() }
    foreach ($item in @($bytes,$plain,$derived,$cipher,$tag,$header,$salt,$nonce)) { if ($item -is [byte[]]) { [Security.Cryptography.CryptographicOperations]::ZeroMemory($item) } }
  }
}

function Restore-PackageSet {
  param([string[]]$Destinations,[hashtable]$BackupFiles,[string[]]$HadOriginal)
  foreach ($destination in @($Destinations)) {
    if ($destination -in $HadOriginal) {
      $backup=$BackupFiles[$destination]
      if (-not $backup -or -not (Test-Path -LiteralPath $backup)) { throw 'Verified package backup is missing; manual recovery is required.' }
      $temporary="$destination.rollback-$([Guid]::NewGuid().ToString('N'))"
      [IO.File]::Copy($backup,$temporary,$false)
      Set-G6PrivateAclOnNewPath -Path $temporary | Out-Null
      Move-VerifiedPrivateFile -Source $temporary -Destination $destination
      if ((Get-FileHash -Algorithm SHA256 -LiteralPath $destination).Hash -ne (Get-FileHash -Algorithm SHA256 -LiteralPath $backup).Hash) { throw 'Restored package hash mismatch; manual recovery is required.' }
    } elseif (Test-Path -LiteralPath $destination) { Remove-Item -LiteralPath $destination -Force }
  }
}

$rootFull=[IO.Path]::GetFullPath($Root)
if ($TestOnlyFailAfterCandidates -gt 0 -or $TestOnlyFailDuringCommitAfter -gt 0) {
  $tempBase=[IO.Path]::GetFullPath($env:TEMP).TrimEnd([IO.Path]::DirectorySeparatorChar)+[IO.Path]::DirectorySeparatorChar
  if (-not $rootFull.StartsWith($tempBase,[StringComparison]::OrdinalIgnoreCase) -or (Split-Path -Leaf $rootFull) -notlike 'g6-package-generation-fixtures-*') { throw 'Test-only failure injection is restricted to synthetic temporary roots.' }
}
Ensure-G6PrivateDirectory -Path $rootFull
$keyDirectory=Join-Path $rootFull 'keys'; $packageDirectory=Join-Path $rootFull 'packages'
Ensure-G6PrivateDirectory -Path $keyDirectory; Ensure-G6PrivateDirectory -Path $packageDirectory
$vaultPath=Join-Path $rootFull 'admin-vault.dpapi.json'
foreach ($protectedPath in @($vaultPath,$CredentialVaultPath)) { if (-not (Test-Path -LiteralPath $protectedPath -PathType Leaf)) { throw 'A required protected onboarding inventory is missing.' }; Assert-G6PrivateAcl -Path $protectedPath | Out-Null }
$vault=Get-Content -Raw -LiteralPath $vaultPath | ConvertFrom-Json
$credentialVault=Get-Content -Raw -LiteralPath $CredentialVaultPath | ConvertFrom-Json
$manifest=Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
$profiles=@(Get-G6DeveloperProfileCatalog)
$expectedLogins=@($profiles.Login); $inventory=@($vault.developers)
if ($inventory.Count -ne 6 -or @($inventory.Login | Select-Object -Unique).Count -ne 6 -or @(Compare-Object $expectedLogins @($inventory.Login)).Count -ne 0) { throw 'Package generation requires exactly the six approved developer records.' }
$assignedIdentities=@($profiles | ForEach-Object { $_.Services } | Sort-Object -Unique)
$manifestIdentities=@($manifest.users | ForEach-Object { $_.username })
if ($manifest.vhost -cne 'g6-productos-ofertas' -or @($manifest.users).Count -ne 9 -or @($manifestIdentities | Select-Object -Unique).Count -ne 9) { throw 'The G6 RBAC manifest identity inventory is invalid.' }
foreach ($identity in $assignedIdentities) { if ($identity -notin $manifestIdentities) { throw 'A package identity is missing from the approved G6 manifest.' } }
$credentialEntries=@($credentialVault.credentials)
if (@($credentialEntries.username | Select-Object -Unique).Count -ne $credentialEntries.Count) { throw 'Credential inventory contains duplicate service identities.' }
foreach ($identity in $assignedIdentities) { if (@($credentialEntries | Where-Object username -CEQ $identity).Count -ne 1) { throw 'Credential inventory is incomplete for the approved G6 identities.' } }

$askPassPath=Join-Path $rootFull 'askpass.cmd'
if (-not (Test-Path -LiteralPath $askPassPath -PathType Leaf)) { throw 'The protected SSH askpass helper is missing.' }
$validated=@{}
foreach ($profile in $profiles) {
  $dev=@($inventory | Where-Object Login -CEQ $profile.Login)
  if ($dev.Count -ne 1) { throw 'Developer inventory contains a missing or duplicate login.' }
  $dev=$dev[0]
  $expectedKey=[IO.Path]::GetFullPath((Join-Path $keyDirectory $profile.KeyName))
  $expectedPublic="$expectedKey.pub"
  $expectedPayload=[IO.Path]::GetFullPath((Join-Path $packageDirectory "$($profile.Login).g6pkg"))
  $expectedInstaller=[IO.Path]::GetFullPath((Join-Path $packageDirectory "$($profile.Login)-installer.ps1"))
  if ($dev.Developer -cne $profile.Developer -or $dev.KeyName -cne $profile.KeyName -or [int]$dev.Port -ne [int]$profile.Port -or @(Compare-Object @($dev.Services) @($profile.Services)).Count -ne 0 -or [IO.Path]::GetFullPath($dev.KeyPath) -cne $expectedKey -or [IO.Path]::GetFullPath($dev.PublicKeyPath) -cne $expectedPublic -or [IO.Path]::GetFullPath($dev.PackagePayloadPath) -cne $expectedPayload -or [IO.Path]::GetFullPath($dev.PackagePath) -cne $expectedInstaller -or [string]::IsNullOrWhiteSpace($dev.Fingerprint) -or [string]::IsNullOrWhiteSpace($dev.ProtectedPackagePassword)) { throw 'Developer record does not match its approved login, key, fingerprint, port, identities, or package paths.' }
  foreach ($keyPath in @($expectedKey,$expectedPublic)) { if (-not (Test-Path -LiteralPath $keyPath -PathType Leaf)) { throw 'An assigned SSH key file is missing; package generation will not create or replace keys.' }; Assert-G6PrivateAcl -Path $keyPath | Out-Null }
  $publicFingerprint=((& ssh-keygen.exe -lf $expectedPublic) -split '\s+')[1]
  $keySecure=ConvertTo-SecureString -String $dev.ProtectedPackagePassword
  $keyPass=[Net.NetworkCredential]::new('', $keySecure).Password
  try { $privateFingerprint=Get-G6UnlockedSshFingerprint -PrivateKeyPath $expectedKey -PublicKeyPath $expectedPublic -Passphrase $keyPass -AskPassPath $askPassPath -ExpectedFingerprint $dev.Fingerprint }
  finally { $keyPass=$null; $keySecure.Dispose() }
  if ($publicFingerprint -cne $dev.Fingerprint -or $privateFingerprint -cne $dev.Fingerprint) { throw 'SSH key fingerprint does not match the inventory; package generation stopped.' }
  foreach ($identity in $profile.Services) {
    $manifestUser=$manifest.users | Where-Object username -CEQ $identity | Select-Object -First 1
    $credentialUser=$credentialEntries | Where-Object username -CEQ $identity | Select-Object -First 1
    if (-not $manifestUser -or -not $credentialUser.protectedPassword) { throw 'Assigned RabbitMQ identity, vhost, or protected credential is invalid.' }
  }
  $validated[$profile.Login]=$dev
}

$kitFiles=@('Install-G6DeveloperPackage.ps1','Start-G6RabbitMqTunnel.ps1','Test-G6RabbitMqTunnel.ps1','Test-G6DeveloperAccess.ps1','Set-G6DeveloperRabbitMqUrl.ps1','G6DeveloperProfile.ps1','verify-pilot-amqp.mjs','..\rbac-rc3.json')
foreach ($file in $kitFiles) { if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $file) -PathType Leaf)) { throw "Required package source is missing: $file" } }
foreach ($profile in $profiles) { foreach ($identity in $profile.Services) { if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot "templates\$identity.env.example") -PathType Leaf)) { throw 'An assigned environment template is missing.' } } }

$destinations=[Collections.Generic.List[string]]::new()
foreach ($profile in $profiles) { $destinations.Add($validated[$profile.Login].PackagePayloadPath); $destinations.Add($validated[$profile.Login].PackagePath) }
$present=@($destinations | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
if ($present.Count -ne 0 -and $present.Count -ne $destinations.Count) { throw 'Existing package set is incomplete; no package was replaced.' }
foreach ($path in $present) { Assert-G6PrivateAcl -Path $path | Out-Null }

$stagePath=Join-Path $rootFull ('.g6-package-stage-'+[Guid]::NewGuid().ToString('N'))
Ensure-G6PrivateDirectory -Path $stagePath
$stagePackages=Join-Path $stagePath 'packages'; Ensure-G6PrivateDirectory -Path $stagePackages
$manifestBytes=[IO.File]::ReadAllBytes([IO.Path]::GetFullPath($ManifestPath))
$bootstrapPath=Join-Path $PSScriptRoot 'Install-G6DeveloperPackage.ps1'
$amqpScript=Join-Path $PSScriptRoot 'verify-pilot-amqp.mjs'
$tunnelScript=Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'Start-G6RabbitMqTunnel.ps1')
$tcpScript=Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'Test-G6RabbitMqTunnel.ps1')
$candidateRecords=[Collections.Generic.List[object]]::new()
$backupPath=$null
$backupFiles=@{}
try {
  $candidateIndex=0
  foreach ($profile in $profiles) {
    $dev=$validated[$profile.Login]
    $fileMap=[Collections.Generic.Dictionary[string,byte[]]]::new([StringComparer]::Ordinal)
    $keyBytes=[IO.File]::ReadAllBytes($dev.KeyPath); $pubBytes=[IO.File]::ReadAllBytes($dev.PublicKeyPath)
    $fileMap["ssh/$($dev.KeyName)"]=$keyBytes; $fileMap["ssh/$($dev.KeyName).pub"]=$pubBytes
    $meta=[ordered]@{Developer=$dev.Developer;Login=$dev.Login;KeyName=$dev.KeyName;Fingerprint=$dev.Fingerprint;Services=@($dev.Services);Port=[int]$dev.Port;Vhost='g6-productos-ofertas'}
    $fileMap['developer.json']=[Text.UTF8Encoding]::new($false).GetBytes(($meta | ConvertTo-Json -Depth 5))
    $sshConfig=@"
Host g6-dev
    HostName 157.137.205.218
    User $($dev.Login)
    Port 22
    IdentityFile ~/.ssh/$($dev.KeyName)
    IdentitiesOnly yes
    ForwardAgent no
    RequestTTY no
    ServerAliveInterval 15
    ServerAliveCountMax 3
    ExitOnForwardFailure yes
"@
    $fileMap['ssh-config']=[Text.UTF8Encoding]::new($false).GetBytes($sshConfig)
    $fileMap['scripts/Start-G6RabbitMqTunnel.ps1']=[Text.UTF8Encoding]::new($false).GetBytes($tunnelScript)
    $fileMap['scripts/Test-G6RabbitMqTunnel.ps1']=[Text.UTF8Encoding]::new($false).GetBytes($tcpScript)
    foreach ($scriptName in @('Test-G6DeveloperAccess.ps1','Set-G6DeveloperRabbitMqUrl.ps1','G6DeveloperProfile.ps1')) { $fileMap["scripts/$scriptName"]=[IO.File]::ReadAllBytes((Join-Path $PSScriptRoot $scriptName)) }
    $fileMap['scripts/verify-pilot-amqp.mjs']=[IO.File]::ReadAllBytes($amqpScript)
    $fileMap['scripts/rbac-rc3.json']=$manifestBytes
    $fileMap['install/Install-G6DeveloperPackage.ps1']=[IO.File]::ReadAllBytes($bootstrapPath)
    $readme=@"
G6 RabbitMQ local developer access — $($dev.Developer)

1. Run the self-contained installer with PowerShell 7: pwsh.exe -ExecutionPolicy Bypass -File .\$($dev.Login)-installer.ps1
2. Enter the individual package password when prompted.
3. Run Test-G6DeveloperAccess.ps1 for the no-message authentication smoke.
4. Configure a local .env using Set-G6DeveloperRabbitMqUrl.ps1.
5. Start the local SSH tunnel using Start-G6RabbitMqTunnel.ps1.

The package includes only the assigned RabbitMQ identities: $($dev.Services -join ', ').
The smoke authenticates and closes the AMQP connection; it does not consume or publish.
Edit local .env.example templates in the service workspace; do not commit filled secrets.
"@
    $fileMap['install/README.txt']=[Text.UTF8Encoding]::new($false).GetBytes($readme)
    $envMap=[Collections.Generic.List[object]]::new()
    foreach ($identity in $dev.Services) {
      $template=Join-Path $PSScriptRoot "templates\$identity.env.example"
      $text=(Get-Content -Raw -LiteralPath $template) -replace '127\.0\.0\.1:\d+/',"127.0.0.1:$($meta.Port)/"
      $fileMap["templates/$identity.env.example"]=[Text.UTF8Encoding]::new($false).GetBytes($text)
      $source=$credentialEntries | Where-Object username -CEQ $identity | Select-Object -First 1
      $secure=ConvertTo-SecureString -String $source.protectedPassword
      $plain=[Net.NetworkCredential]::new('', $secure).Password
      $envMap.Add([pscustomobject]@{username=$identity;vhost='g6-productos-ofertas';password=$plain})
      $secure.Dispose(); $plain=$null
    }
    $credentialJson=ConvertTo-Json -InputObject @($envMap) -Depth 4 -Compress
    $credentialBytes=[Text.UTF8Encoding]::new($false).GetBytes($credentialJson)
    $fileMap['secrets/credentials.json']=$credentialBytes
    $memory=[IO.MemoryStream]::new(); $zip=$null
    try {
      $zip=[IO.Compression.ZipArchive]::new($memory,[IO.Compression.ZipArchiveMode]::Create,$true)
      foreach ($name in $fileMap.Keys) { Add-ZipBytes -Archive $zip -Name $name -Bytes $fileMap[$name] }
    } finally { if ($zip) { $zip.Dispose() } }
    $zipBytes=$memory.ToArray(); $zipBuffer=$memory.GetBuffer()
    [Security.Cryptography.CryptographicOperations]::ZeroMemory($zipBuffer); $memory.Dispose()
    $packageSecure=ConvertTo-SecureString -String $dev.ProtectedPackagePassword
    $packagePassword=[Net.NetworkCredential]::new('', $packageSecure).Password
    $salt=[Security.Cryptography.RandomNumberGenerator]::GetBytes(16); $nonce=[Security.Cryptography.RandomNumberGenerator]::GetBytes(12)
    $derived=[Security.Cryptography.Rfc2898DeriveBytes]::Pbkdf2($packagePassword,$salt,$iterations,[Security.Cryptography.HashAlgorithmName]::SHA256,32)
    $header=[byte[]]::new(37); [Array]::Copy([Text.Encoding]::ASCII.GetBytes('G6PK1'),0,$header,0,5); [Array]::Copy($salt,0,$header,5,16); [Array]::Copy([BitConverter]::GetBytes([int]$iterations),0,$header,21,4); [Array]::Copy($nonce,0,$header,25,12)
    $cipher=[byte[]]::new($zipBytes.Length); $tag=[byte[]]::new(16); $aes=[Security.Cryptography.AesGcm]::new($derived,16)
    try { $aes.Encrypt($nonce,$zipBytes,$cipher,$tag,$header) } finally { $aes.Dispose() }
    $output=[IO.MemoryStream]::new()
    try { $output.Write($header,0,$header.Length); $output.Write($cipher,0,$cipher.Length); $output.Write($tag,0,$tag.Length); $packageBytes=$output.ToArray() } finally { $output.Dispose() }
    $payloadCandidate=Join-Path $stagePackages "$($dev.Login).g6pkg"
    Write-NewPrivateBytes -Path $payloadCandidate -Bytes $packageBytes
    Assert-CandidatePackage -PayloadPath $payloadCandidate -Passphrase $packagePassword -Profile $profile -AssignedIdentities @($profile.Services) | Out-Null

    $payloadB64=[Convert]::ToBase64String($packageBytes)
    $bootstrapB64=[Convert]::ToBase64String([IO.File]::ReadAllBytes($bootstrapPath))
    $wrapperTemplate=@'
#requires -Version 7.0
$ErrorActionPreference='Stop'
$payload=[Convert]::FromBase64String('__G6_ENCRYPTED_PAYLOAD__')
$bootstrapBytes=[Convert]::FromBase64String('__G6_BOOTSTRAP__')
$tempRoot=Join-Path $env:TEMP ('g6-package-unlock-'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $tempRoot
$payloadPath=Join-Path $tempRoot 'developer.g6pkg'
try {
  [IO.File]::WriteAllBytes($payloadPath,$payload)
  $bootstrap=[ScriptBlock]::Create([Text.UTF8Encoding]::new($false,$true).GetString($bootstrapBytes))
  & $bootstrap -PackagePath $payloadPath
} finally {
  [Security.Cryptography.CryptographicOperations]::ZeroMemory($payload)
  [Security.Cryptography.CryptographicOperations]::ZeroMemory($bootstrapBytes)
  $tempBase=[IO.Path]::GetFullPath($env:TEMP).TrimEnd([IO.Path]::DirectorySeparatorChar)+[IO.Path]::DirectorySeparatorChar
  $resolved=[IO.Path]::GetFullPath($tempRoot)
  if (-not $resolved.StartsWith($tempBase,[StringComparison]::OrdinalIgnoreCase)) { throw 'Refusing to remove a package temp path outside Windows TEMP.' }
  if (Test-Path -LiteralPath $payloadPath) { Remove-Item -LiteralPath $payloadPath -Force }
  if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
'@
    $wrapper=$wrapperTemplate.Replace('__G6_ENCRYPTED_PAYLOAD__',$payloadB64).Replace('__G6_BOOTSTRAP__',$bootstrapB64)
    $tokens=$null; $parseErrors=$null
    [System.Management.Automation.Language.Parser]::ParseInput($wrapper,[ref]$tokens,[ref]$parseErrors)|Out-Null
    if ($parseErrors) { throw 'Candidate installer wrapper failed PowerShell parsing.' }
    $installerCandidate=Join-Path $stagePackages "$($dev.Login)-installer.ps1"
    Write-NewPrivateBytes -Path $installerCandidate -Bytes ([Text.UTF8Encoding]::new($false).GetBytes($wrapper))
    $candidateRecords.Add([pscustomobject]@{Login=$dev.Login;PayloadCandidate=$payloadCandidate;InstallerCandidate=$installerCandidate;PayloadDestination=$dev.PackagePayloadPath;InstallerDestination=$dev.PackagePath;PayloadHash=(Get-FileHash -Algorithm SHA256 -LiteralPath $payloadCandidate).Hash;InstallerHash=(Get-FileHash -Algorithm SHA256 -LiteralPath $installerCandidate).Hash})

    $candidateIndex++
    if ($TestOnlyFailAfterCandidates -gt 0 -and $candidateIndex -eq $TestOnlyFailAfterCandidates) { throw 'Synthetic interruption requested after candidate staging.' }
    $packageSecure.Dispose()
    foreach ($arr in @($keyBytes,$pubBytes,$credentialBytes,$zipBytes,$derived,$cipher,$tag,$packageBytes,$salt,$nonce,$header)) { if ($arr -is [byte[]]) { [Security.Cryptography.CryptographicOperations]::ZeroMemory($arr) } }
    foreach ($value in $fileMap.Values) { if ($value -is [byte[]]) { [Security.Cryptography.CryptographicOperations]::ZeroMemory($value) } }
    $packagePassword=$null; $credentialJson=$null; $envMap.Clear()
  }

  $oldDestinations=@($present)
  if ($oldDestinations.Count -gt 0) {
    $backupParent=Join-Path $rootFull 'private-backups'; Ensure-G6PrivateDirectory -Path $backupParent
    $backupPath=Join-Path $backupParent ('packages-'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')+'-'+[Guid]::NewGuid().ToString('N'))
    Ensure-G6PrivateDirectory -Path $backupPath
    $backupIndex=[Collections.Generic.List[object]]::new()
    foreach ($record in $candidateRecords) {
      foreach ($sourcePath in @($record.PayloadDestination,$record.InstallerDestination)) {
        $backupFile=Join-Path $backupPath ([IO.Path]::GetFileName($sourcePath))
        [IO.File]::Copy($sourcePath,$backupFile,$false); Set-G6PrivateAclOnNewPath -Path $backupFile | Out-Null
        $sourceHash=(Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash; $backupHash=(Get-FileHash -Algorithm SHA256 -LiteralPath $backupFile).Hash
        if ($sourceHash -cne $backupHash) { throw 'Private backup verification failed; no package was replaced.' }
        $backupFiles[$sourcePath]=$backupFile; $backupIndex.Add([pscustomobject]@{file=[IO.Path]::GetFileName($sourcePath);sha256=$backupHash})
      }
    }
    $indexBytes=[Text.UTF8Encoding]::new($false).GetBytes(($backupIndex | ConvertTo-Json -Depth 3))
    Write-G6PrivateFileAtomically -Path (Join-Path $backupPath 'SHA256.json') -Content $indexBytes
    [Security.Cryptography.CryptographicOperations]::ZeroMemory($indexBytes)
  }

  $replaced=[Collections.Generic.List[string]]::new()
  $commitIndex=0
  try {
    foreach ($record in $candidateRecords) {
      foreach ($item in @(@{Source=$record.PayloadCandidate;Destination=$record.PayloadDestination},@{Source=$record.InstallerCandidate;Destination=$record.InstallerDestination})) {
        $replaced.Add($item.Destination)
        Move-VerifiedPrivateFile -Source $item.Source -Destination $item.Destination
        if ((Get-FileHash -Algorithm SHA256 -LiteralPath $item.Destination).Hash -cne $(if ($item.Destination -like '*.g6pkg') { $record.PayloadHash } else { $record.InstallerHash })) { throw 'Committed package hash differs from its validated candidate.' }
        $commitIndex++
        if ($TestOnlyFailDuringCommitAfter -gt 0 -and $commitIndex -eq $TestOnlyFailDuringCommitAfter) { throw 'Synthetic interruption requested during package replacement.' }
      }
    }

    foreach ($record in $candidateRecords) {
      $dev=$validated[$record.Login]
      $dev | Add-Member -NotePropertyName PackageSHA256 -NotePropertyValue $record.InstallerHash -Force
      $dev | Add-Member -NotePropertyName PackagePayloadSHA256 -NotePropertyValue $record.PayloadHash -Force
      $dev | Add-Member -NotePropertyName PackageCreatedUtc -NotePropertyValue ([DateTime]::UtcNow.ToString('o')) -Force
      $dev | Add-Member -NotePropertyName PackageCreated -NotePropertyValue $true -Force
    }
    $vault.createdUtc=[DateTime]::UtcNow.ToString('o')
    $vaultBytes=[Text.UTF8Encoding]::new($false).GetBytes(($vault | ConvertTo-Json -Depth 10))
    try { Write-G6PrivateFileAtomically -Path $vaultPath -Content $vaultBytes } finally { [Security.Cryptography.CryptographicOperations]::ZeroMemory($vaultBytes) }
  } catch {
    try { Restore-PackageSet -Destinations @($replaced) -BackupFiles $backupFiles -HadOriginal $oldDestinations }
    catch { throw "Package generation failed and automatic rollback could not be verified; retain the private backup and perform manual recovery. Recovery detail: $($_.Exception.Message)" }
    throw 'Package generation failed; the previous package set was restored and verified.'
  }

  foreach ($record in $candidateRecords) { Write-Output "$($record.Login): validated encrypted package ready; installer SHA-256 $($record.InstallerHash); payload SHA-256 $($record.PayloadHash)." }
  if ($backupPath) { Write-Output "Previous encrypted package set backed up and verified; private backup path: $backupPath" }
} finally {
  [Security.Cryptography.CryptographicOperations]::ZeroMemory($manifestBytes)
  if (Test-Path -LiteralPath $stagePath) { Remove-Item -LiteralPath $stagePath -Recurse -Force }
}
