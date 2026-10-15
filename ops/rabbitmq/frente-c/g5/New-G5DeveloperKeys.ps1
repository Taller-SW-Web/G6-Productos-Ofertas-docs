param([string]$RosterPath,[switch]$SharedTeamPackage,[string]$Root=(Join-Path $env:LOCALAPPDATA 'G6\RabbitMQ\g5-onboarding'))
$ErrorActionPreference='Stop'
if($SharedTeamPackage){$roster=@([pscustomobject]@{Nombre='Equipo G5 (paquete grupal pendiente de entrega)';Login='g5_equipo';EstadoHomologacion='ACEPTACION_COMUNICADA_HOMOLOGACION_FORMAL_PENDIENTE';ReferenciaHomologacion=''})}
else{if([string]::IsNullOrWhiteSpace($RosterPath)-or-not(Test-Path -LiteralPath $RosterPath -PathType Leaf)){throw 'Provide the approved G5 recipient roster CSV, or explicitly select -SharedTeamPackage.'};$roster=@(Import-Csv -LiteralPath $RosterPath)}
if($roster.Count -eq 0){throw 'No authorized G5 recipient has been identified; no key was generated.'}
foreach($r in $roster){if([string]::IsNullOrWhiteSpace($r.Nombre)-or $r.Login -notmatch '^g5_[a-z0-9][a-z0-9_-]{1,30}$'-or(-not $SharedTeamPackage-and($r.EstadoHomologacion -cne 'HOMOLOGADO'-or[string]::IsNullOrWhiteSpace($r.ReferenciaHomologacion)))){throw 'Each individual recipient requires a unique label, EstadoHomologacion=HOMOLOGADO and a documentary acceptance reference.'}}
if(@($roster.Login|Sort-Object -Unique).Count -ne $roster.Count){throw 'Roster contains duplicate package recipient labels.'}
$null=New-Item -ItemType Directory -Force -Path (Join-Path $Root 'keys'),(Join-Path $Root 'packages')
$vaultPath=Join-Path $Root 'admin-vault.dpapi.json'
$vault=if(Test-Path -LiteralPath $vaultPath){Get-Content -Raw -LiteralPath $vaultPath|ConvertFrom-Json}else{[pscustomobject]@{format='G5-onboarding-DPAPI-v2';sshIdentity=$null;members=@()}}
if($vault.format -cne 'G5-onboarding-DPAPI-v2'){throw 'Unsupported G5 vault format; refusing to overwrite or migrate it.'}
$keyPath=Join-Path (Join-Path $Root 'keys') 'g5_tunnel'
if((Test-Path -LiteralPath $keyPath) -or (Test-Path -LiteralPath "$keyPath.pub")){
  if(-not $vault.sshIdentity-or-not(Test-Path $keyPath)-or-not(Test-Path "$keyPath.pub")){throw 'Untracked or partial shared SSH key exists; refusing overwrite.'}
  $fingerprint=((ssh-keygen.exe -lf "$keyPath.pub") -split '\s+')[1]
  if($fingerprint-ne$vault.sshIdentity.Fingerprint){throw 'Shared SSH key fingerprint mismatch; refusing to continue.'}
}else{
  if($vault.sshIdentity){throw 'Vault has a shared SSH identity but its key pair is missing; refusing regeneration.'}
  $keyBytes=[Security.Cryptography.RandomNumberGenerator]::GetBytes(32);$keyPass=[Convert]::ToBase64String($keyBytes).TrimEnd('=').Replace('+','-').Replace('/','_');[Security.Cryptography.CryptographicOperations]::ZeroMemory($keyBytes)
  $ask=Join-Path $Root 'askpass.cmd';Set-Content -LiteralPath $ask -Encoding ascii -Value '@echo off','echo %G5_KEY_PASSPHRASE%'
  $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName=(Get-Command ssh-keygen.exe).Source;foreach($a in @('-q','-t','ed25519','-a','100','-f',$keyPath,'-C','G5 shared RabbitMQ tunnel')){[void]$psi.ArgumentList.Add($a)};$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true;$psi.Environment['SSH_ASKPASS']=$ask;$psi.Environment['SSH_ASKPASS_REQUIRE']='force';$psi.Environment['G5_KEY_PASSPHRASE']=$keyPass
  $proc=[Diagnostics.Process]::new();$proc.StartInfo=$psi;[void]$proc.Start();$null=$proc.StandardOutput.ReadToEndAsync();$null=$proc.StandardError.ReadToEndAsync();if(-not $proc.WaitForExit(20000)){$proc.Kill();throw 'ssh-keygen timed out.'};if($proc.ExitCode-ne 0){throw 'Shared Ed25519 key generation failed; diagnostics redacted.'}
  $fingerprint=((ssh-keygen.exe -lf "$keyPath.pub") -split '\s+')[1];$secure=ConvertTo-SecureString $keyPass -AsPlainText -Force
  $vault.sshIdentity=[pscustomobject]@{Login='g5_tunnel';KeyPath=$keyPath;PublicKeyPath="$keyPath.pub";Fingerprint=$fingerprint;ProtectedKeyPassphrase=(ConvertFrom-SecureString $secure)};$secure.Dispose();$keyPass=$null;$psi.Environment.Remove('G5_KEY_PASSPHRASE')
}
$existing=@($vault.members);$byLogin=@{};foreach($m in $existing){if($byLogin.ContainsKey($m.Login)){throw 'Vault contains duplicate package recipients.'};$byLogin[$m.Login]=$m}
foreach($r in $roster){
  if($byLogin.ContainsKey($r.Login)){$m=$byLogin[$r.Login];$m.Name=$r.Nombre;continue}
  $bytes=[Security.Cryptography.RandomNumberGenerator]::GetBytes(32);$pkgPass=[Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+','-').Replace('/','_');[Security.Cryptography.CryptographicOperations]::ZeroMemory($bytes);$secure=ConvertTo-SecureString $pkgPass -AsPlainText -Force
  $existing+=,[pscustomobject]@{Name=$r.Nombre;Login=$r.Login;ProtectedPackagePassword=(ConvertFrom-SecureString $secure);PackagePath=(Join-Path (Join-Path $Root 'packages') "$($r.Login).g5pkg");InstallerPath=(Join-Path (Join-Path $Root 'packages') "$($r.Login)-installer.ps1")};$secure.Dispose();$pkgPass=$null
}
$vault.members=@($existing);$vault|ConvertTo-Json -Depth 6|Set-Content -LiteralPath $vaultPath -Encoding utf8
$owner=[Security.Principal.WindowsIdentity]::GetCurrent().Name;icacls $Root /inheritance:r /grant:r "$owner`:(OI)(CI)F" 'NT AUTHORITY\SYSTEM:(OI)(CI)F' /T /C|Out-Null
icacls $keyPath /inheritance:r /grant:r "$owner`:(F)" 'NT AUTHORITY\SYSTEM:(F)'|Out-Null;icacls "$keyPath.pub" /inheritance:r /grant:r "$owner`:(F)" 'NT AUTHORITY\SYSTEM:(F)'|Out-Null
Write-Output "Prepared one shared, passphrase-protected Ed25519 key for SSH account g5_tunnel and $($roster.Count) independently encrypted package password(s). Vault: $vaultPath"
$roster|Select-Object Nombre,Login|Format-Table -AutoSize
