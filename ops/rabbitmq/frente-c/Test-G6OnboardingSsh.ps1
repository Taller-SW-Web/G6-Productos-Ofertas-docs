#requires -Version 7.0
param([string]$Root = (Join-Path $env:LOCALAPPDATA 'G6\RabbitMQ\onboarding'))
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'G6DeveloperProfile.ps1')
$vaultPath=Join-Path $Root 'admin-vault.dpapi.json'
$vault=Get-Content -Raw -LiteralPath (Join-Path $Root 'admin-vault.dpapi.json') | ConvertFrom-Json
$askpass=Join-Path $Root 'askpass.cmd'
if (-not (Test-Path -LiteralPath $askpass -PathType Leaf)) { throw 'Protected SSH askpass helper is missing.' }
$config=Join-Path $Root 'admin-test-ssh-config'
$lines=[Collections.Generic.List[string]]::new()
foreach ($d in $vault.developers) {
  $lines.Add("Host $($d.Login)")
  $lines.Add('    HostName 157.137.205.218')
  $lines.Add("    User $($d.Login)")
  $lines.Add("    IdentityFile `"$($d.KeyPath)`"")
  $lines.Add('    IdentitiesOnly yes')
  $lines.Add('    ForwardAgent no')
  $lines.Add('    RequestTTY no')
  $lines.Add('    AddKeysToAgent no')
  $lines.Add('    ServerAliveInterval 15')
  $lines.Add('    ServerAliveCountMax 3')
  $lines.Add('    ExitOnForwardFailure yes')
}
$lines | Set-Content -LiteralPath $config -Encoding ascii
$results=[Collections.Generic.List[object]]::new()
foreach ($d in $vault.developers) {
  $secure=ConvertTo-SecureString -String $d.ProtectedPackagePassword
  $password=[Net.NetworkCredential]::new('', $secure).Password
  $pt=$null; $pb=$null
  try {
  $port=[int]$d.Port
  $tunnel=[Diagnostics.ProcessStartInfo]::new(); $tunnel.FileName=(Get-Command ssh.exe).Source
  foreach ($a in @('-F',$config,'-i',$d.KeyPath,'-o','IdentitiesOnly=yes','-o','IdentityAgent=none','-N','-T','-o','ExitOnForwardFailure=yes','-o','ConnectTimeout=8','-L',"127.0.0.1:${port}:127.0.0.1:5672",$d.Login)) { [void]$tunnel.ArgumentList.Add($a) }
  $tunnel.Environment['SSH_ASKPASS']=$askpass; $tunnel.Environment['SSH_ASKPASS_REQUIRE']='force'; $tunnel.Environment['G6_KEY_PASSPHRASE']=$password
  $tunnel.UseShellExecute=$false; $tunnel.RedirectStandardOutput=$true; $tunnel.RedirectStandardError=$true
  $pt=[Diagnostics.Process]::new(); $pt.StartInfo=$tunnel; [void]$pt.Start(); $tout=$pt.StandardOutput.ReadToEndAsync(); $terr=$pt.StandardError.ReadToEndAsync()
  $null=$tunnel.Environment.Remove('G6_KEY_PASSPHRASE')
  $tcpPassed=$false
  for ($i=0; $i -lt 40; $i++) {
    if ($pt.HasExited) { break }
    $tcp=[Net.Sockets.TcpClient]::new()
    try { $task=$tcp.ConnectAsync('127.0.0.1',$port); if ($task.Wait(250) -and $tcp.Connected) { $tcpPassed=$true; break } } catch {} finally { $tcp.Dispose() }
    Start-Sleep -Milliseconds 250
  }
  $auth=$tcpPassed -and -not $pt.HasExited
  if (-not $auth) { $err=$terr.GetAwaiter().GetResult(); if (-not $pt.HasExited) { $pt.Kill(); $pt.WaitForExit() }; throw "SSH auth/tunnel failed for $($d.Login); details redacted: $err" }
  $pt.Kill(); $pt.WaitForExit(); Start-Sleep -Milliseconds 250
  if (Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue) { throw "Local listener $port remained after stopping $($d.Login)'s test." }

  $badPort=$port+100
  $bad=[Diagnostics.ProcessStartInfo]::new(); $bad.FileName=(Get-Command ssh.exe).Source
  foreach ($a in @('-F',$config,'-i',$d.KeyPath,'-o','IdentitiesOnly=yes','-o','IdentityAgent=none','-N','-T','-o','ExitOnForwardFailure=yes','-L',"127.0.0.1:${badPort}:127.0.0.1:22",$d.Login)) { [void]$bad.ArgumentList.Add($a) }
  $bad.Environment['SSH_ASKPASS']=$askpass; $bad.Environment['SSH_ASKPASS_REQUIRE']='force'; $bad.Environment['G6_KEY_PASSPHRASE']=$password
  $bad.UseShellExecute=$false; $bad.RedirectStandardOutput=$true; $bad.RedirectStandardError=$true
  $pb=[Diagnostics.Process]::new(); $pb.StartInfo=$bad; [void]$pb.Start(); $bo=$pb.StandardOutput.ReadToEndAsync(); $be=$pb.StandardError.ReadToEndAsync()
  $null=$bad.Environment.Remove('G6_KEY_PASSPHRASE')
  $negative=$false
  for ($i=0; $i -lt 30 -and -not $pb.HasExited; $i++) {
    $listener=Get-NetTCPConnection -State Listen -LocalPort $badPort -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($listener) { $t=[Net.Sockets.TcpClient]::new(); try { $t.Connect('127.0.0.1',$badPort) } catch {} finally { $t.Dispose() }; Start-Sleep -Milliseconds 400; if ($pb.HasExited) { $text=$be.GetAwaiter().GetResult(); if ($text -match 'administratively prohibited|open failed') { $negative=$true } }; break }
    Start-Sleep -Milliseconds 200
  }
  if (-not $pb.HasExited) { $pb.Kill(); $pb.WaitForExit() }
  if (-not $negative) { $text=$be.GetAwaiter().GetResult(); if ($text -match 'administratively prohibited|open failed') { $negative=$true } }
  if (-not $negative) { throw "Unapproved-destination denial was not proven for $($d.Login); details redacted." }
  Set-G6VerifiedOnboardingState -VaultPath $vaultPath -Field TunnelTestedFromAdminPc -Login $d.Login
  $results.Add([pscustomobject]@{ Developer=$d.Developer; Login=$d.Login; Fingerprint=$d.Fingerprint; SSHAuthentication='PASS'; AllowedLocalForward='PASS'; UnapprovedDestination='DENIED'; LocalPort=$port })
  } finally {
    $password=$null; if ($secure) { $secure.Dispose() }
    foreach ($process in @($pt,$pb)) { if ($process -and -not $process.HasExited) { $process.Kill(); $process.WaitForExit() } }
    if ($pt) { $pt.Dispose() }; if ($pb) { $pb.Dispose() }
  }
}
$results | Format-Table -AutoSize
