#requires -Version 7.0
param([string]$KitRoot = $PSScriptRoot)
$ErrorActionPreference='Stop'
. (Join-Path $KitRoot 'G6DeveloperProfile.ps1')
$profiles=@(Get-G6DeveloperProfileCatalog)
$fixtureRoot=Join-Path $env:TEMP ('g6-package-generation-fixtures-'+[Guid]::NewGuid().ToString('N'))
$oldHashes=@{}
$secretMarker='SYNTHETIC-PACKAGE-GENERATION-CREDENTIAL-ONLY'
$keyPassphrase='SYNTHETIC-SSH-PASSPHRASE-ONLY'
$generator=Join-Path $KitRoot 'New-G6DeveloperPackages.ps1'
$manifestPath=[IO.Path]::GetFullPath((Join-Path $KitRoot '..\rbac-rc3.json'))
try {
  Ensure-G6PrivateDirectory -Path $fixtureRoot
  $keyDirectory=Join-Path $fixtureRoot 'keys'; $packageDirectory=Join-Path $fixtureRoot 'packages'
  Ensure-G6PrivateDirectory -Path $keyDirectory; Ensure-G6PrivateDirectory -Path $packageDirectory
  $askPassPath=Join-Path $fixtureRoot 'askpass.cmd'
  Write-G6PrivateFileAtomically -Path $askPassPath -Content ([Text.Encoding]::ASCII.GetBytes("@echo off`r`necho %G6_KEY_PASSPHRASE%`r`n"))

  $developers=[Collections.Generic.List[object]]::new()
  foreach ($index in 0..($profiles.Count-1)) {
    $profile=$profiles[$index]
    $keyPath=Join-Path $keyDirectory $profile.KeyName; $publicPath="$keyPath.pub"
    & ssh-keygen.exe -q -t ed25519 -N $keyPassphrase -f $keyPath -C "synthetic $($profile.Login)"
    if ($LASTEXITCODE -ne 0) { throw 'Could not create a synthetic SSH fixture key.' }
    Set-G6PrivateAclOnNewPath -Path $keyPath | Out-Null; Set-G6PrivateAclOnNewPath -Path $publicPath | Out-Null
    $fingerprint=((& ssh-keygen.exe -lf $publicPath) -split '\s+')[1]
    $secure=ConvertTo-SecureString -String $keyPassphrase -AsPlainText -Force
    $protected=ConvertFrom-SecureString -SecureString $secure; $secure.Dispose()
    $unlockedFingerprint=Get-G6UnlockedSshFingerprint -PrivateKeyPath $keyPath -PublicKeyPath $publicPath -Passphrase $keyPassphrase -AskPassPath $askPassPath -ExpectedFingerprint $fingerprint
    if ($unlockedFingerprint -cne $fingerprint) { throw "Synthetic private-key unlock fixture failed for $($profile.Login)." }
    $wrongPassphraseRejected=$false
    try { Get-G6UnlockedSshFingerprint -PrivateKeyPath $keyPath -PublicKeyPath $publicPath -Passphrase 'SYNTHETIC-WRONG-PASSPHRASE-ONLY' -AskPassPath $askPassPath -ExpectedFingerprint $fingerprint | Out-Null }
    catch { $wrongPassphraseRejected=$_.Exception.Message -match 'passphrase or key is invalid' }
    if (-not $wrongPassphraseRejected) { throw "Synthetic wrong-passphrase fixture was not rejected for $($profile.Login)." }
    $developers.Add([pscustomobject]@{
      Developer=$profile.Developer; Login=$profile.Login; KeyName=$profile.KeyName; KeyPath=$keyPath; PublicKeyPath=$publicPath
      Fingerprint=$fingerprint; PackagePayloadPath=(Join-Path $packageDirectory "$($profile.Login).g6pkg"); PackagePath=(Join-Path $packageDirectory "$($profile.Login)-installer.ps1")
      ProtectedPackagePassword=$protected; Services=@($profile.Services); Port=$profile.Port
      AccountCreated=($index % 2 -eq 0); PublicKeyRegistered=($index % 2 -ne 0); TunnelTestedFromAdminPc=$false
      PackageDelivered=($index -eq 2); DeveloperPcConfirmed=$false; PackageCreated=$true; PackageCreatedUtc='2026-01-01T00:00:00Z'
      PackageSHA256="old-installer-$index"; PackagePayloadSHA256="old-payload-$index"
    })
  }
  Write-Output 'PASS synthetic SSH unlock fixtures: six encrypted Ed25519 keys unlocked with their passphrases; six incorrect passphrases rejected without key material output.'
  $unprotectedKey=Join-Path $keyDirectory 'synthetic-unprotected'
  & ssh-keygen.exe -q -t ed25519 -N '' -f $unprotectedKey -C 'synthetic unprotected negative fixture'
  if ($LASTEXITCODE -ne 0) { throw 'Could not create the synthetic unprotected-key negative fixture.' }
  Set-G6PrivateAclOnNewPath -Path $unprotectedKey | Out-Null; Set-G6PrivateAclOnNewPath -Path "$unprotectedKey.pub" | Out-Null
  $unprotectedFingerprint=((& ssh-keygen.exe -lf "$unprotectedKey.pub") -split '\s+')[1]
  $unprotectedRejected=$false
  try { Get-G6UnlockedSshFingerprint -PrivateKeyPath $unprotectedKey -PublicKeyPath "$unprotectedKey.pub" -Passphrase $keyPassphrase -AskPassPath $askPassPath -ExpectedFingerprint $unprotectedFingerprint | Out-Null }
  catch { $unprotectedRejected=$_.Exception.Message -match 'does not require its protected passphrase' }
  if (-not $unprotectedRejected) { throw 'Synthetic unprotected private key was not rejected.' }
  Write-Output 'PASS synthetic encryption policy: an unencrypted Ed25519 key is rejected even when its fingerprint matches.'

  $adminVaultPath=Join-Path $fixtureRoot 'admin-vault.dpapi.json'
  $adminBytes=[Text.UTF8Encoding]::new($false).GetBytes((ConvertTo-Json -InputObject ([pscustomobject]@{format='synthetic';createdUtc='2026-01-01T00:00:00Z';developers=@($developers)}) -Depth 10))
  Write-G6PrivateFileAtomically -Path $adminVaultPath -Content $adminBytes
  [Security.Cryptography.CryptographicOperations]::ZeroMemory($adminBytes)

  $credentialEntries=[Collections.Generic.List[object]]::new()
  foreach ($identity in @($profiles | ForEach-Object Services | Sort-Object -Unique)) {
    $secure=ConvertTo-SecureString -String "$secretMarker-$identity" -AsPlainText -Force
    $credentialEntries.Add([pscustomobject]@{username=$identity;protectedPassword=(ConvertFrom-SecureString -SecureString $secure)})
    $secure.Dispose()
  }
  $credentialVaultPath=Join-Path $fixtureRoot 'credential-vault.synthetic.json'
  $credentialBytes=[Text.UTF8Encoding]::new($false).GetBytes((ConvertTo-Json -InputObject ([pscustomobject]@{credentials=@($credentialEntries)}) -Depth 5))
  Write-G6PrivateFileAtomically -Path $credentialVaultPath -Content $credentialBytes
  [Security.Cryptography.CryptographicOperations]::ZeroMemory($credentialBytes)

  foreach ($profile in $profiles) {
    foreach ($suffix in @('.g6pkg','-installer.ps1')) {
      $path=Join-Path $packageDirectory "$($profile.Login)$suffix"
      $bytes=[Text.Encoding]::UTF8.GetBytes("SYNTHETIC-OLD-$($profile.Login)$suffix")
      $stream=[IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
      try { $stream.Write($bytes,0,$bytes.Length) } finally { $stream.Dispose() }
      Set-G6PrivateAclOnNewPath -Path $path | Out-Null
      $oldHashes[$path]=(Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash
    }
  }

  $stageFailed=$false; $stageFailureOutput=''
  try { $stageFailureOutput=& $generator -Root $fixtureRoot -CredentialVaultPath $credentialVaultPath -ManifestPath $manifestPath -TestOnlyFailAfterCandidates 3 2>&1 | Out-String }
  catch { $stageFailed=$true; $stageFailureOutput=$_.Exception.Message }
  if (-not $stageFailed -or $stageFailureOutput -match [regex]::Escape($secretMarker)) { throw 'Synthetic staging interruption did not fail safely or leaked a fixture credential.' }
  foreach ($path in $oldHashes.Keys) { if ((Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash -cne $oldHashes[$path]) { throw 'A prior package changed after staging interruption.' } }
  $afterStageVault=Get-Content -Raw -LiteralPath $adminVaultPath | ConvertFrom-Json
  if (@($afterStageVault.developers | Where-Object { $_.PackageSHA256 -like 'old-installer-*' }).Count -ne 6) { throw 'Inventory changed after staging interruption.' }
  Write-Output 'PASS synthetic interruption: staged candidates were discarded; all twelve prior package files and inventory remain unchanged.'

  $commitFailed=$false; $commitFailureOutput=''
  try { $commitFailureOutput=& $generator -Root $fixtureRoot -CredentialVaultPath $credentialVaultPath -ManifestPath $manifestPath -TestOnlyFailDuringCommitAfter 3 2>&1 | Out-String }
  catch { $commitFailed=$true; $commitFailureOutput=$_.Exception.Message }
  if (-not $commitFailed -or $commitFailureOutput -match [regex]::Escape($secretMarker)) { throw 'Synthetic commit interruption did not fail safely or leaked a fixture credential.' }
  foreach ($path in $oldHashes.Keys) { if ((Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash -cne $oldHashes[$path]) { throw 'A prior package was not restored after commit interruption.' } }
  $afterCommitVault=Get-Content -Raw -LiteralPath $adminVaultPath | ConvertFrom-Json
  if (@($afterCommitVault.developers | Where-Object { $_.PackageSHA256 -like 'old-installer-*' }).Count -ne 6) { throw 'Package inventory claimed a candidate after failed commit.' }
  Write-Output 'PASS synthetic rollback: partial replacements were restored from the verified private backup; inventory remained unchanged.'

  $generationFailed=$false; $generationOutput=''
  try { $generationOutput=& $generator -Root $fixtureRoot -CredentialVaultPath $credentialVaultPath -ManifestPath $manifestPath 2>&1 | Out-String }
  catch { $generationFailed=$true; $generationOutput=$_.Exception.Message }
  if ($generationOutput -match [regex]::Escape($secretMarker)) { throw 'Synthetic package generation output contained the fixture credential marker.' }
  if ($generationFailed) { throw "Synthetic package generation failed: $generationOutput" }
  $generatedVault=Get-Content -Raw -LiteralPath $adminVaultPath | ConvertFrom-Json
  foreach ($profile in $profiles) {
    $entry=@($generatedVault.developers | Where-Object Login -CEQ $profile.Login)
    if ($entry.Count -ne 1 -or -not $entry[0].PackageCreated -or $entry[0].PackageSHA256 -ne (Get-FileHash -Algorithm SHA256 -LiteralPath $entry[0].PackagePath).Hash -or $entry[0].PackagePayloadSHA256 -ne (Get-FileHash -Algorithm SHA256 -LiteralPath $entry[0].PackagePayloadPath).Hash) { throw "Package state or hash mismatch for $($profile.Login)." }
    $oldEntry=@($developers | Where-Object Login -CEQ $profile.Login)[0]
    foreach ($state in @('AccountCreated','PublicKeyRegistered','TunnelTestedFromAdminPc','PackageDelivered','DeveloperPcConfirmed')) { if ([bool]$entry[0].$state -ne [bool]$oldEntry.$state) { throw "Package generation overwrote evidence state $state for $($profile.Login)." } }
    if (-not (Test-Path -LiteralPath $entry[0].PackagePath) -or -not (Test-Path -LiteralPath $entry[0].PackagePayloadPath)) { throw "Generated package output is missing for $($profile.Login)." }
  }

  $backupDirs=@(Get-ChildItem -LiteralPath (Join-Path $fixtureRoot 'private-backups') -Directory -Filter 'packages-*')
  if ($backupDirs.Count -lt 2) { throw 'Expected verified backups from failed and successful transaction fixtures.' }
  foreach ($backupDir in $backupDirs) {
    Assert-G6PrivateAcl -Path $backupDir.FullName | Out-Null
    $index=Get-Content -Raw -LiteralPath (Join-Path $backupDir.FullName 'SHA256.json') | ConvertFrom-Json
    if (@($index).Count -ne 12) { throw 'Private backup hash index does not cover all twelve package artifacts.' }
    foreach ($item in $index) { if ((Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $backupDir.FullName $item.file)).Hash -cne $item.sha256) { throw 'Private backup hash verification failed.' } }
  }
  if (Get-ChildItem -LiteralPath $fixtureRoot -Directory -Filter '.g6-package-stage-*') { throw 'A candidate staging directory remained after generation.' }
  Write-Output 'PASS synthetic transaction: six validated AES-GCM packages, metadata, identities, fingerprints, and private prior-set backups verified.'
} finally {
  $tempBase=[IO.Path]::GetFullPath($env:TEMP).TrimEnd([IO.Path]::DirectorySeparatorChar)+[IO.Path]::DirectorySeparatorChar
  $resolved=[IO.Path]::GetFullPath($fixtureRoot)
  if (-not $resolved.StartsWith($tempBase,[StringComparison]::OrdinalIgnoreCase) -or (Split-Path -Leaf $resolved) -notlike 'g6-package-generation-fixtures-*') { throw 'Refusing to remove fixture data outside its synthetic temporary root.' }
  if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
