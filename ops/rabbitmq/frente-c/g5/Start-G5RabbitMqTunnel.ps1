param([int]$LocalPort=5673,[int]$ReconnectDelaySeconds=5,[string]$SshConfigPath=(Join-Path $env:USERPROFILE '.ssh\config'))
$ErrorActionPreference='Stop'
if($LocalPort -ne 5673){throw 'G5 local tunnel port is fixed to 5673.'}
$cfg=& ssh.exe -F $SshConfigPath -G g5-dev 2>$null; if($LASTEXITCODE -ne 0){throw 'SSH alias g5-dev could not be resolved.'}
$hostName=($cfg|Where-Object {$_ -match '^hostname '}|Select-Object -First 1)-replace '^hostname\s+',''
$userName=($cfg|Where-Object {$_ -match '^user '}|Select-Object -First 1)-replace '^user\s+',''
$identityOnly=($cfg|Where-Object {$_ -match '^identitiesonly '}|Select-Object -First 1)-replace '^identitiesonly\s+',''
if($hostName -ne '157.137.205.218' -or $userName -cne 'g5_tunnel' -or $identityOnly -ne 'yes'){throw 'g5-dev must resolve to the Oracle VM and fixed shared account g5_tunnel with IdentitiesOnly yes.'}
$ids=@($cfg|Where-Object {$_ -match '^identityfile '}|ForEach-Object {($_ -replace '^identityfile\s+','').Trim('"')})
if(@($ids|Where-Object {[IO.Path]::GetFileNameWithoutExtension($_) -ceq 'g5_tunnel'}).Count -ne 1){throw 'g5-dev must select exactly the shared g5_tunnel Ed25519 identity.'}
$root=Split-Path -Parent $PSScriptRoot;$keySecret=Import-Clixml (Join-Path $root 'secrets\key-passphrase.clixml');$keyPass=[Net.NetworkCredential]::new('', $keySecret).Password;$askpass=Join-Path $root 'askpass.cmd';Set-Content -LiteralPath $askpass -Encoding ascii -Value '@echo off','echo %G5_SSH_PASSPHRASE%';$oldAsk=$env:SSH_ASKPASS;$oldRequire=$env:SSH_ASKPASS_REQUIRE;$oldPass=$env:G5_SSH_PASSPHRASE;$env:SSH_ASKPASS=$askpass;$env:SSH_ASKPASS_REQUIRE='force';$env:G5_SSH_PASSPHRASE=$keyPass
try{
while($true){
  $listener=Get-NetTCPConnection -State Listen -LocalPort $LocalPort -ErrorAction SilentlyContinue|Select-Object -First 1
  if($listener){throw "127.0.0.1:$LocalPort is already occupied; refusing to replace its listener."}
  Write-Host "Opening G5 tunnel on 127.0.0.1:$LocalPort; Ctrl+C stops it."
  & ssh.exe -F $SshConfigPath -N -T -o IdentitiesOnly=yes -o ForwardAgent=no -o RequestTTY=no -o ExitOnForwardFailure=yes -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -L "127.0.0.1:${LocalPort}:127.0.0.1:5672" g5-dev
  if($LASTEXITCODE -eq 0){break}; Write-Warning "Tunnel disconnected; retrying in $ReconnectDelaySeconds seconds."; Start-Sleep -Seconds $ReconnectDelaySeconds
}
}finally{$env:SSH_ASKPASS=$oldAsk;$env:SSH_ASKPASS_REQUIRE=$oldRequire;$env:G5_SSH_PASSPHRASE=$oldPass;$keyPass=$null;$keySecret.Dispose()}
