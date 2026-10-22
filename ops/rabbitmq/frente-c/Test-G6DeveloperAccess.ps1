#requires -Version 7.0
$ErrorActionPreference='Stop'
$installRoot=$PSScriptRoot
$profileHelper=Join-Path $installRoot 'G6DeveloperProfile.ps1'
if (-not (Test-Path -LiteralPath $profileHelper -PathType Leaf)) { throw 'G6 developer profile helper is missing.' }
. $profileHelper
$meta=Get-G6DeveloperProfile
$sshConfigPath=Join-Path $env:USERPROFILE '.ssh\config'
if (-not (Test-Path -LiteralPath $sshConfigPath)) { throw 'User SSH config was not installed.' }
$sshConfig=& ssh.exe -F $sshConfigPath -G g6-dev 2>$null
if ($LASTEXITCODE -ne 0) { throw 'SSH alias g6-dev could not be resolved.' }
$hostName=($sshConfig | Where-Object { $_ -match '^hostname ' } | Select-Object -First 1) -replace '^hostname\s+',''
$userName=($sshConfig | Where-Object { $_ -match '^user ' } | Select-Object -First 1) -replace '^user\s+',''
$identitiesOnly=($sshConfig | Where-Object { $_ -match '^identitiesonly ' } | Select-Object -First 1) -replace '^identitiesonly\s+',''
$identityFiles=@($sshConfig | Where-Object { $_ -match '^identityfile ' } | ForEach-Object { ($_ -replace '^identityfile\s+','').Trim('"') })
if ($hostName -ne '157.137.205.218' -or $userName -ne $meta.Login -or $identitiesOnly -ne 'yes' -or -not ($identityFiles | Where-Object { [IO.Path]::GetFileNameWithoutExtension($_) -eq $meta.KeyName })) { throw 'SSH alias host, login, identity key, or IdentitiesOnly setting does not match developer.json.' }
$port=[int]$meta.Port
$tunnelInfo=[Diagnostics.ProcessStartInfo]::new(); $tunnelInfo.FileName=(Get-Command ssh.exe).Source
foreach ($a in @('-F',$sshConfigPath,'-N','-T','-o','ExitOnForwardFailure=yes','-o','ConnectTimeout=8','-L',"127.0.0.1:${port}:127.0.0.1:5672",'g6-dev')) { [void]$tunnelInfo.ArgumentList.Add($a) }
$tunnelInfo.UseShellExecute=$false; $tunnelInfo.CreateNoWindow=$true; $tunnelInfo.RedirectStandardOutput=$true; $tunnelInfo.RedirectStandardError=$true
$askpass=Join-Path $installRoot 'askpass.cmd'
if (-not (Test-Path -LiteralPath $askpass)) { Set-Content -LiteralPath $askpass -Encoding ascii -Value '@echo off','echo %G6_SSH_PASSPHRASE%' }
$securePass=Import-Clixml -LiteralPath (Join-Path $installRoot 'secrets\key-passphrase.clixml')
$plainPass=[Net.NetworkCredential]::new('', $securePass).Password
$tunnelInfo.Environment['SSH_ASKPASS']=$askpass; $tunnelInfo.Environment['SSH_ASKPASS_REQUIRE']='force'; $tunnelInfo.Environment['G6_SSH_PASSPHRASE']=$plainPass
$tunnel=[Diagnostics.Process]::new(); $tunnel.StartInfo=$tunnelInfo; [void]$tunnel.Start(); $outTask=$tunnel.StandardOutput.ReadToEndAsync(); $errTask=$tunnel.StandardError.ReadToEndAsync()
$runtime=Join-Path $env:TEMP ('g6-dev-smoke-'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $runtime
try {
  $ready=$false
  for ($i=0;$i -lt 40;$i++) {
    if ($tunnel.HasExited) { break }
    $tcp=[Net.Sockets.TcpClient]::new()
    try { $task=$tcp.ConnectAsync('127.0.0.1',$port); if ($task.Wait(250) -and $tcp.Connected) { $ready=$true; break } } catch {} finally { $tcp.Dispose() }
    Start-Sleep -Milliseconds 250
  }
  if (-not $ready) { throw 'SSH authentication or tunnel startup failed; diagnostic output omitted to protect local paths and credentials.' }
  '{"private":true,"type":"module"}' | Set-Content -LiteralPath (Join-Path $runtime 'package.json') -Encoding ascii
  & npm.cmd install --prefix $runtime --no-audit --no-fund amqplib@2.2.0
  if ($LASTEXITCODE -ne 0) { throw 'Could not prepare the temporary AMQP smoke dependency.' }
  Copy-Item -LiteralPath (Join-Path $installRoot 'verify-pilot-amqp.mjs') -Destination (Join-Path $runtime 'verify.mjs')
  $credentials=Get-ChildItem (Join-Path $installRoot 'secrets') -Filter 'g6_*.clixml'
  foreach ($file in $credentials) {
    $identity=[IO.Path]::GetFileNameWithoutExtension($file.Name)
    $secure=Import-Clixml -LiteralPath $file.FullName
    $secret=[Net.NetworkCredential]::new('', $secure).Password
    $escaped=[uri]::EscapeDataString($secret)
    $env:RABBITMQ_URL="amqp://${identity}:$escaped@127.0.0.1:${port}/g6-productos-ofertas"
    $env:G6_AMQP_PORT=[string]$port; $env:G6_AMQP_VHOST=[string]$meta.Vhost; $env:G6_RABBITMQ_RBAC_FILE=Join-Path $installRoot 'rbac-rc3.json'
    & node (Join-Path $runtime 'verify.mjs') $identity
    if ($LASTEXITCODE -ne 0) { throw "AMQP smoke failed for $identity; no secret was printed." }
    $secret=$null; $escaped=$null; $secure.Dispose(); $secure=$null
  }
  Write-Output "PASS: $($meta.Developer), SSH and assigned AMQP identities verified from this PC. Publisher operations were not run by the local smoke."
} finally {
  $env:RABBITMQ_URL=$null; $env:G6_AMQP_PORT=$null; $env:G6_AMQP_VHOST=$null; $env:G6_RABBITMQ_RBAC_FILE=$null
  $plainPass=$null; $securePass.Dispose()
  if (-not $tunnel.HasExited) { $tunnel.Kill(); $tunnel.WaitForExit() }
  $tempBase=[IO.Path]::GetFullPath($env:TEMP).TrimEnd([IO.Path]::DirectorySeparatorChar)+[IO.Path]::DirectorySeparatorChar
  $resolved=[IO.Path]::GetFullPath($runtime)
  if (-not $resolved.StartsWith($tempBase,[StringComparison]::OrdinalIgnoreCase)) { throw 'Refusing to remove a temp path outside Windows TEMP.' }
  Remove-Item -LiteralPath $resolved -Recurse -Force
}
