param([string]$Root = (Join-Path $env:LOCALAPPDATA 'G6\RabbitMQ\onboarding'))
$ErrorActionPreference = 'Stop'
$accounts = @(
  @{ Developer='Castilla'; Login='g6_castilla'; KeyName='g6_castilla_dist'; Services=@('g6_masivos','g6_combos'); Port=5673 },
  @{ Developer='Poma'; Login='g6_poma'; KeyName='g6_poma'; Services=@('g6_catalogo'); Port=5674 },
  @{ Developer='Taco'; Login='g6_taco'; KeyName='g6_taco'; Services=@('g6_inventario'); Port=5675 },
  @{ Developer='Vera'; Login='g6_vera'; KeyName='g6_vera'; Services=@('g6_precios','g6_auditoria_precios'); Port=5676 },
  @{ Developer='Cueva'; Login='g6_cueva'; KeyName='g6_cueva'; Services=@('g6_promociones'); Port=5677 },
  @{ Developer='López'; Login='g6_lopez'; KeyName='g6_lopez'; Services=@('g6_taxonomia'); Port=5678 }
)
$null = New-Item -ItemType Directory -Path $Root -Force
$null = New-Item -ItemType Directory -Path (Join-Path $Root 'keys') -Force
$null = New-Item -ItemType Directory -Path (Join-Path $Root 'packages') -Force
$askpass = Join-Path $Root 'askpass.cmd'
Set-Content -LiteralPath $askpass -Encoding ascii -Value '@echo off','echo %G6_KEY_PASSPHRASE%'
$vaultPath = Join-Path $Root 'admin-vault.dpapi.json'
$vault = if (Test-Path -LiteralPath $vaultPath) { Get-Content -Raw -LiteralPath $vaultPath | ConvertFrom-Json } else { [pscustomobject]@{ format='G6-onboarding-DPAPI-v1'; createdUtc=[DateTime]::UtcNow.ToString('o'); developers=@() } }
$entries = [System.Collections.Generic.List[object]]::new()
foreach ($item in $accounts) {
  $keyPath = Join-Path (Join-Path $Root 'keys') $item.KeyName
  $pubPath = "$keyPath.pub"
  $existing = @($vault.developers | Where-Object Login -EQ $item.Login)
  if ((Test-Path -LiteralPath $keyPath) -or (Test-Path -LiteralPath $pubPath)) {
    if (-not (Test-Path -LiteralPath $keyPath) -or -not (Test-Path -LiteralPath $pubPath) -or $existing.Count -ne 1) { throw "Partial or untracked onboarding key exists for $($item.Login); refusing to overwrite." }
    $entry = $existing[0]
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
    $public = Get-Content -Raw -LiteralPath $pubPath
    $fingerprint = ((& ssh-keygen.exe -lf $pubPath) -split '\s+')[1]
    $secure = ConvertTo-SecureString -String $password -AsPlainText -Force
    $protected = ConvertFrom-SecureString -SecureString $secure
    $secure.Dispose(); $psi.Environment.Remove('G6_KEY_PASSPHRASE'); $password=$null
    $entry = [pscustomobject]@{ Developer=$item.Developer; Login=$item.Login; KeyName=$item.KeyName; KeyPath=$keyPath; PublicKeyPath=$pubPath; Fingerprint=$fingerprint; PackagePayloadPath=(Join-Path (Join-Path $Root 'packages') "$($item.Login).g6pkg"); PackagePath=(Join-Path (Join-Path $Root 'packages') "$($item.Login)-installer.ps1"); ProtectedPackagePassword=$protected; Services=@($item.Services); Port=$item.Port; AccountCreated=($item.Login -eq 'g6_castilla'); PublicKeyRegistered=($false); TunnelTestedFromAdminPc=($false); PackageDelivered=$false; DeveloperPcConfirmed=$false }
  }
  $entries.Add($entry)
}
$vault.developers = @($entries)
$vault.createdUtc = [DateTime]::UtcNow.ToString('o')
$json = $vault | ConvertTo-Json -Depth 8
$json | Set-Content -LiteralPath $vaultPath -Encoding utf8
$current=[Security.Principal.WindowsIdentity]::GetCurrent().Name
icacls $Root /inheritance:r /grant:r "$current`:(OI)(CI)F" 'NT AUTHORITY\SYSTEM:(OI)(CI)F' 'Renato\CodexSandboxUsers:(OI)(CI)F' | Out-Null
foreach($entry in $entries) {
  icacls $entry.KeyPath /inheritance:r /grant:r "$current`:(F)" 'NT AUTHORITY\SYSTEM:(F)' 'Renato\CodexSandboxUsers:(F)' | Out-Null
  icacls $entry.KeyPath /remove:g '*S-1-5-32-544' | Out-Null
  icacls $entry.PublicKeyPath /inheritance:r /grant:r "$current`:(F)" 'NT AUTHORITY\SYSTEM:(F)' 'Renato\CodexSandboxUsers:(F)' | Out-Null
}
Write-Output "Generated or verified six passphrase-protected Ed25519 keys. DPAPI admin vault: $vaultPath"
$entries | Select-Object Developer,Login,KeyName,Fingerprint,PackagePath | Format-Table -AutoSize
