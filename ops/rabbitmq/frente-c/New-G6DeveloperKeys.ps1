#requires -Version 7.0
param([string]$Root = (Join-Path $env:LOCALAPPDATA 'G6\RabbitMQ\onboarding'))
$ErrorActionPreference = 'Stop'
$helperPath = Join-Path $PSScriptRoot 'G6DeveloperProfile.ps1'
. $helperPath
$accounts = @(Get-G6DeveloperProfileCatalog)
Ensure-G6PrivateDirectory -Path $Root
Ensure-G6PrivateDirectory -Path (Join-Path $Root 'keys')
Ensure-G6PrivateDirectory -Path (Join-Path $Root 'packages')
$askpass = Join-Path $Root 'askpass.cmd'
if (-not (Test-Path -LiteralPath $askpass)) {
  Write-G6PrivateFileAtomically -Path $askpass -Content ([Text.Encoding]::ASCII.GetBytes("@echo off`r`necho %G6_KEY_PASSPHRASE%`r`n"))
}
$vaultPath = Join-Path $Root 'admin-vault.dpapi.json'
if (Test-Path -LiteralPath $vaultPath) { Assert-G6PrivateAcl -Path $vaultPath | Out-Null }
$vault = if (Test-Path -LiteralPath $vaultPath) { Get-Content -Raw -LiteralPath $vaultPath | ConvertFrom-Json } else { [pscustomobject]@{ format='G6-onboarding-DPAPI-v1'; createdUtc=[DateTime]::UtcNow.ToString('o'); developers=@() } }
$entries = [System.Collections.Generic.List[object]]::new()
foreach ($item in $accounts) {
  $keyPath = Join-Path (Join-Path $Root 'keys') $item.KeyName
  $pubPath = "$keyPath.pub"
  $existing = @($vault.developers | Where-Object Login -EQ $item.Login)
  if ((Test-Path -LiteralPath $keyPath) -or (Test-Path -LiteralPath $pubPath)) {
    if (-not (Test-Path -LiteralPath $keyPath) -or -not (Test-Path -LiteralPath $pubPath) -or $existing.Count -ne 1) { throw "Partial or untracked onboarding key exists for $($item.Login); refusing to overwrite." }
    $entry = $existing[0]
    Assert-G6PrivateAcl -Path $keyPath | Out-Null
    Assert-G6PrivateAcl -Path $pubPath | Out-Null
    $entry | Add-Member -NotePropertyName PackagePayloadPath -NotePropertyValue (Join-Path (Join-Path $Root 'packages') "$($item.Login).g6pkg") -Force
    $entry | Add-Member -NotePropertyName PackagePath -NotePropertyValue (Join-Path (Join-Path $Root 'packages') "$($item.Login)-installer.ps1") -Force
    $fingerprint = ((& ssh-keygen.exe -lf $pubPath) -split '\s+')[1]
    if ($fingerprint -ne $entry.Fingerprint) { throw "Fingerprint mismatch for existing key $($item.Login)." }
  } else {
    $bytes = [Security.Cryptography.RandomNumberGenerator]::GetBytes(32)
    $password = [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+','-').Replace('/','_')
    [Array]::Clear($bytes,0,$bytes.Length)
    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = (Get-Command ssh-keygen.exe).Source
    foreach ($arg in @('-q','-t','ed25519','-f',$keyPath,'-C',"G6 $($item.Developer) developer access")) { [void]$psi.ArgumentList.Add($arg) }
    $psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $psi.Environment['SSH_ASKPASS'] = $askpass; $psi.Environment['SSH_ASKPASS_REQUIRE'] = 'force'; $psi.Environment['G6_KEY_PASSPHRASE'] = $password
    $proc = [Diagnostics.Process]::new(); $proc.StartInfo = $psi; [void]$proc.Start()
    $stdout = $proc.StandardOutput.ReadToEndAsync(); $stderr = $proc.StandardError.ReadToEndAsync()
    if (-not $proc.WaitForExit(15000)) { $proc.Kill(); throw "ssh-keygen timed out for $($item.Login)." }
    if ($proc.ExitCode -ne 0) { throw "ssh-keygen failed for $($item.Login) (exit $($proc.ExitCode)); details redacted." }
    Set-G6PrivateAclOnNewPath -Path $keyPath | Out-Null
    Set-G6PrivateAclOnNewPath -Path $pubPath | Out-Null
    $public = Get-Content -Raw -LiteralPath $pubPath
    $fingerprint = ((& ssh-keygen.exe -lf $pubPath) -split '\s+')[1]
    $secure = ConvertTo-SecureString -String $password -AsPlainText -Force
    $protected = ConvertFrom-SecureString -SecureString $secure
    $secure.Dispose(); $psi.Environment.Remove('G6_KEY_PASSPHRASE'); $password=$null
    $entry = [pscustomobject]@{ Developer=$item.Developer; Login=$item.Login; KeyName=$item.KeyName; KeyPath=$keyPath; PublicKeyPath=$pubPath; Fingerprint=$fingerprint; PackagePayloadPath=(Join-Path (Join-Path $Root 'packages') "$($item.Login).g6pkg"); PackagePath=(Join-Path (Join-Path $Root 'packages') "$($item.Login)-installer.ps1"); ProtectedPackagePassword=$protected; Services=@($item.Services); Port=$item.Port; AccountCreated=$false; PublicKeyRegistered=$false; TunnelTestedFromAdminPc=$false; PackageDelivered=$false; DeveloperPcConfirmed=$false }
  }
  foreach ($stateName in @('AccountCreated','PublicKeyRegistered','TunnelTestedFromAdminPc')) {
    if ($null -eq $entry.$stateName) { $entry | Add-Member -NotePropertyName $stateName -NotePropertyValue $false -Force }
  }
  $entries.Add($entry)
}
$vault.developers = @($entries)
$vault.createdUtc = [DateTime]::UtcNow.ToString('o')
$json = $vault | ConvertTo-Json -Depth 8
$vaultBytes = [Text.UTF8Encoding]::new($false).GetBytes($json)
Write-G6PrivateFileAtomically -Path $vaultPath -Content $vaultBytes
[Security.Cryptography.CryptographicOperations]::ZeroMemory($vaultBytes)
Write-Output "Generated or verified six passphrase-protected Ed25519 keys. DPAPI admin vault: $vaultPath"
$entries | Select-Object Developer,Login,KeyName,Fingerprint,PackagePath | Format-Table -AutoSize
