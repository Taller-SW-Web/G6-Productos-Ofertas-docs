#requires -Version 7.0
param(
  [Parameter(Mandatory=$true)][ValidateSet('g6_castilla')][string]$Login,
  [Parameter(Mandatory=$true)][string]$PublicKeyPath,
  [string]$AdminKeyPath = (Join-Path $env:USERPROFILE '.ssh\g6_oracle'),
  [string]$Root = (Join-Path $env:LOCALAPPDATA 'G6\RabbitMQ\onboarding')
)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'G6DeveloperProfile.ps1')
foreach ($path in @($PublicKeyPath,$AdminKeyPath)) { if (-not (Test-Path -LiteralPath $path)) { throw "Required file not found: $path" } }
$publicKey=(Get-Content -Raw -LiteralPath $PublicKeyPath).Trim()
if ($publicKey -notmatch '^ssh-ed25519 [A-Za-z0-9+/]+={0,2}( .*)?$') { throw 'Provide one ssh-ed25519 public key line.' }
$fingerprint=(( & ssh-keygen.exe -lf $PublicKeyPath) -split '\s+')[1]
$remote='ubuntu@157.137.205.218'; $remoteDir='/home/ubuntu/.g6-rabbitmq-onboard'
& ssh -i $AdminKeyPath -o IdentitiesOnly=yes -o BatchMode=yes $remote "sudo -n test -x /usr/sbin/sshd && sudo -n id g6_castilla"
if ($LASTEXITCODE -ne 0) { throw 'Could not verify the existing pilot account.' }
& scp -i $AdminKeyPath -o IdentitiesOnly=yes -o BatchMode=yes (Join-Path $PSScriptRoot 'append-dev-tunnel-key.sh') "${remote}:${remoteDir}/"
if ($LASTEXITCODE -ne 0) { throw 'Could not transfer the non-secret append helper.' }
$start=[Diagnostics.ProcessStartInfo]::new(); $start.FileName='ssh'
foreach ($arg in @('-i',$AdminKeyPath,'-o','IdentitiesOnly=yes','-o','BatchMode=yes',$remote,"sudo -n bash $remoteDir/append-dev-tunnel-key.sh $Login")) { [void]$start.ArgumentList.Add($arg) }
$start.UseShellExecute=$false; $start.RedirectStandardInput=$true; $start.RedirectStandardOutput=$true; $start.RedirectStandardError=$true
$proc=[Diagnostics.Process]::new(); $proc.StartInfo=$start; [void]$proc.Start(); $out=$proc.StandardOutput.ReadToEndAsync(); $err=$proc.StandardError.ReadToEndAsync(); $proc.StandardInput.WriteLine($publicKey); $proc.StandardInput.Close(); $proc.WaitForExit()
$publicKey=$null
if ($proc.ExitCode -ne 0) { throw "Key append failed ($($proc.ExitCode)); details redacted." }
$remoteOutput=$out.GetAwaiter().GetResult()
if ($remoteOutput -notmatch [regex]::Escape($fingerprint)) { throw 'Remote registration evidence did not match the submitted public-key fingerprint.' }
Write-Output $remoteOutput
Set-G6VerifiedOnboardingState -VaultPath (Join-Path $Root 'admin-vault.dpapi.json') -Field PublicKeyRegistered -Login $Login
