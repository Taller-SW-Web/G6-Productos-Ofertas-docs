param(
  [string]$RosterPath,
  [switch]$OwnerAuthorized,
  [string]$Login = 'g5_tunnel',
  [string]$PublicKeyPath = (Join-Path $env:LOCALAPPDATA 'G6\RabbitMQ\g5-onboarding\keys\g5_tunnel.pub'),
  [string]$AdminKeyPath = (Join-Path $env:USERPROFILE '.ssh\g6_oracle')
)
$ErrorActionPreference='Stop'
if ($Login -cne 'g5_tunnel') { throw 'Only the fixed shared SSH account g5_tunnel is allowed.' }
if ((-not $OwnerAuthorized -and (-not (Test-Path -LiteralPath $RosterPath -PathType Leaf))) -or -not (Test-Path -LiteralPath $PublicKeyPath -PathType Leaf) -or -not (Test-Path -LiteralPath $AdminKeyPath -PathType Leaf)) { throw 'Formal roster (unless owner-authorized), public key, or administrator key is missing.' }
if (-not $OwnerAuthorized) { if ([string]::IsNullOrWhiteSpace($RosterPath) -or -not (Test-Path -LiteralPath $RosterPath -PathType Leaf)) { throw 'Supply formal G5 homologation roster or explicitly pass -OwnerAuthorized for this controlled operator run.' }; $roster=@(Import-Csv -LiteralPath $RosterPath); if ($roster.Count -eq 0 -or @($roster | Where-Object { $_.EstadoHomologacion -cne 'HOMOLOGADO' -or [string]::IsNullOrWhiteSpace($_.Nombre) -or [string]::IsNullOrWhiteSpace($_.ReferenciaHomologacion) -or $_.Login -notmatch '^g5_[a-z0-9][a-z0-9_-]{1,30}$' }).Count -gt 0) { throw 'Provisioning requires a named recipient roster fully homologated with documentary reference.' }; if (@($roster.Login | Sort-Object -Unique).Count -ne $roster.Count) { throw 'Duplicate package recipient label in G5 roster.' } }
$pub=(Get-Content -Raw -LiteralPath $PublicKeyPath).Trim()
if ($pub -notmatch '^ssh-ed25519 [A-Za-z0-9+/]+={0,2}( .*)?$') { throw 'Provide exactly one ssh-ed25519 public key; private keys are never accepted.' }
$null=& ssh-keygen.exe -lf $PublicKeyPath; if ($LASTEXITCODE -ne 0) { throw 'Public key validation failed.' }
$remote='ubuntu@157.137.205.218'; $remoteDir='/home/ubuntu/.g6-rabbitmq-onboard'
$sshBase=@('-i',$AdminKeyPath,'-o','IdentitiesOnly=yes','-o','BatchMode=yes',$remote)
& ssh @sshBase "install -d -o ubuntu -g ubuntu -m 0700 $remoteDir"; if ($LASTEXITCODE -ne 0) { throw 'Could not prepare protected remote onboarding directory.' }
& scp -i $AdminKeyPath -o IdentitiesOnly=yes -o BatchMode=yes (Join-Path $PSScriptRoot 'provision-g5-dev-tunnel-user.sh') (Join-Path $PSScriptRoot '..\sshd-g6-rabbitmq-tunnel.conf.example') "${remote}:${remoteDir}/"
if ($LASTEXITCODE -ne 0) { throw 'Could not transfer non-secret onboarding files.' }
$psi=[Diagnostics.ProcessStartInfo]::new(); $psi.FileName='ssh'
foreach($arg in @('-i',$AdminKeyPath,'-o','IdentitiesOnly=yes','-o','BatchMode=yes',$remote,"sudo -n bash $remoteDir/provision-g5-dev-tunnel-user.sh g5_tunnel")){[void]$psi.ArgumentList.Add($arg)}
$psi.UseShellExecute=$false; $psi.RedirectStandardInput=$true; $psi.RedirectStandardOutput=$true; $psi.RedirectStandardError=$true
$p=[Diagnostics.Process]::new(); $p.StartInfo=$psi; [void]$p.Start(); $out=$p.StandardOutput.ReadToEndAsync(); $err=$p.StandardError.ReadToEndAsync(); $p.StandardInput.WriteLine($pub); $p.StandardInput.Close(); $p.WaitForExit(); $pub=$null
if($p.ExitCode -ne 0){throw "Restricted G5 SSH provisioning failed ($($p.ExitCode)); details redacted: $($err.GetAwaiter().GetResult())"}
$outText=$out.GetAwaiter().GetResult(); if($outText -match 'ssh-ed25519-[^\s]+|-----BEGIN|[A-Za-z0-9_-]{40,}') { throw 'Provisioner output unexpectedly resembled secret material; output suppressed.' }
Write-Output $outText
