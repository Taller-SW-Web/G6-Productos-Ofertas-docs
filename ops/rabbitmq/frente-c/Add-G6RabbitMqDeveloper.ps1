#requires -Version 7.0
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('g6_castilla','g6_poma','g6_taco','g6_vera','g6_cueva','g6_lopez')]
  [string]$Login,
  [Parameter(Mandatory = $true)]
  [string]$PublicKeyPath,
  [string]$AdminKeyPath = (Join-Path $env:USERPROFILE '.ssh\g6_oracle')
)
$ErrorActionPreference = 'Stop'
foreach ($path in @($PublicKeyPath, $AdminKeyPath)) {
  if (-not (Test-Path -LiteralPath $path)) { throw "Required file not found: $path" }
}
$publicKey = (Get-Content -Raw -LiteralPath $PublicKeyPath).Trim()
if ($publicKey -notmatch '^ssh-ed25519 [A-Za-z0-9+/]+={0,2}( .*)?$') { throw 'Provide exactly one ssh-ed25519 public key line; private keys are not accepted.' }
$null = & ssh-keygen -lf $PublicKeyPath
if ($LASTEXITCODE -ne 0) { throw 'The supplied public key failed local OpenSSH validation.' }

$remote = 'ubuntu@157.137.205.218'
$remoteDir = '/home/ubuntu/.g6-rabbitmq-onboard'
$sshArgs = @('-i', $AdminKeyPath, '-o', 'IdentitiesOnly=yes', '-o', 'BatchMode=yes', $remote)
& ssh @sshArgs "install -d -o ubuntu -g ubuntu -m 0700 $remoteDir"
if ($LASTEXITCODE -ne 0) { throw 'Could not prepare the protected remote onboarding directory.' }
& scp -i $AdminKeyPath -o IdentitiesOnly=yes -o BatchMode=yes `
  (Join-Path $PSScriptRoot 'provision-dev-tunnel-user.sh') `
  (Join-Path $PSScriptRoot 'sshd-g6-rabbitmq-tunnel.conf.example') `
  "${remote}:${remoteDir}/"
if ($LASTEXITCODE -ne 0) { throw 'Could not transfer the non-secret onboarding scripts.' }

$start = [System.Diagnostics.ProcessStartInfo]::new()
$start.FileName = 'ssh'
foreach ($arg in @('-i', $AdminKeyPath, '-o', 'IdentitiesOnly=yes', '-o', 'BatchMode=yes', $remote,
    "sudo -n bash $remoteDir/provision-dev-tunnel-user.sh $Login")) { [void]$start.ArgumentList.Add($arg) }
$start.UseShellExecute = $false
$start.RedirectStandardInput = $true
$start.RedirectStandardOutput = $true
$start.RedirectStandardError = $true
$start.StandardInputEncoding = [Text.UTF8Encoding]::new($false)
$start.StandardOutputEncoding = [Text.UTF8Encoding]::new($false)
$process = [System.Diagnostics.Process]::new(); $process.StartInfo = $start
[void]$process.Start()
$stdoutTask = $process.StandardOutput.ReadToEndAsync()
$stderrTask = $process.StandardError.ReadToEndAsync()
$process.StandardInput.WriteLine($publicKey)
$process.StandardInput.Close()
$process.WaitForExit()
$stdout = $stdoutTask.GetAwaiter().GetResult()
$stderr = $stderrTask.GetAwaiter().GetResult()
$publicKey = $null
if ($process.ExitCode -ne 0) { throw "Restricted account provisioning failed ($($process.ExitCode)): $stderr" }
Write-Output $stdout
$verify = "sudo -n sshd -t && sudo -n sshd -T -C user=$Login,host=localhost,addr=127.0.0.1 | grep -F 'permitopen 127.0.0.1:5672' && id -nG $Login && sudo -n stat -c '%U:%G %a %n' /home/$Login/.ssh/authorized_keys"
& ssh -i $AdminKeyPath -o IdentitiesOnly=yes -o BatchMode=yes $remote $verify
if ($LASTEXITCODE -ne 0) { throw 'Post-provisioning effective-policy/account verification failed.' }
