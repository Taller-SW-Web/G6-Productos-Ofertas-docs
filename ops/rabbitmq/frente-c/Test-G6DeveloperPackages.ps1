param([string]$Root=(Join-Path $env:LOCALAPPDATA 'G6\RabbitMQ\onboarding'),[ValidateSet('g6_castilla','g6_poma','g6_taco','g6_vera','g6_cueva','g6_lopez')][string]$RunSmokeLogin)
$ErrorActionPreference='Stop'
$vault=Get-Content -Raw -LiteralPath (Join-Path $Root 'admin-vault.dpapi.json') | ConvertFrom-Json
$bootstrap=(Resolve-Path (Join-Path $PSScriptRoot 'Install-G6DeveloperPackage.ps1')).Path
$testRoot=Join-Path $env:TEMP ('g6-package-tests-'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $testRoot
$oldProfile=$env:USERPROFILE; $oldLocal=$env:LOCALAPPDATA; $oldHome=$env:HOME
$global:InstallTestPassword=$null
function Read-Host { [CmdletBinding()] param([string]$Prompt,[switch]$AsSecureString) if (-not $global:InstallTestPassword) { throw 'Test password was not loaded.' }; return $global:InstallTestPassword.Copy() }
try {
  foreach ($d in $vault.developers) {
    $secure=ConvertTo-SecureString -String $d.ProtectedPackagePassword
    $global:InstallTestPassword=$secure
    $profile=Join-Path $testRoot $d.Login; $local=Join-Path $profile 'AppData\Local'
    $null=New-Item -ItemType Directory -Force -Path $profile,$local,(Join-Path $profile '.ssh')
    $env:USERPROFILE=$profile; $env:LOCALAPPDATA=$local; $env:HOME=$profile
    if ((Get-FileHash -Algorithm SHA256 $d.PackagePayloadPath).Hash -ne $d.PackagePayloadSHA256) { throw "Encrypted payload hash mismatch for $($d.Login)." }
    & $d.PackagePath | Out-Null
    $meta=Get-Content -Raw -LiteralPath (Join-Path $local "G6\RabbitMQ\$($d.Login)\developer.json") | ConvertFrom-Json
    if ($meta.Login -ne $d.Login -or $meta.KeyName -ne $d.KeyName -or @($meta.Services).Count -ne @($d.Services).Count) { throw "Metadata mismatch for $($d.Login)." }
    $key=Join-Path $profile ".ssh\$($d.KeyName)"; $pub="$key.pub"
    if (-not (Test-Path -LiteralPath $key) -or -not (Test-Path -LiteralPath $pub)) { throw "SSH files missing for $($d.Login)." }
    $askpass=Join-Path $testRoot 'askpass.cmd'; Set-Content -LiteralPath $askpass -Encoding ascii -Value '@echo off','echo %G6_KEY_PASSPHRASE%'
    $plain=[Net.NetworkCredential]::new('', $secure).Password
    $check=[Diagnostics.ProcessStartInfo]::new(); $check.FileName=(Get-Command ssh-keygen.exe).Source; [void]$check.ArgumentList.Add('-y'); [void]$check.ArgumentList.Add('-f'); [void]$check.ArgumentList.Add($key)
    $check.UseShellExecute=$false; $check.RedirectStandardOutput=$true; $check.RedirectStandardError=$true; $check.Environment['SSH_ASKPASS']=$askpass; $check.Environment['SSH_ASKPASS_REQUIRE']='force'; $check.Environment['G6_KEY_PASSPHRASE']=$plain
    $proc=[Diagnostics.Process]::new(); $proc.StartInfo=$check; [void]$proc.Start(); $publicFromPrivate=$proc.StandardOutput.ReadToEndAsync(); $err=$proc.StandardError.ReadToEndAsync(); if (-not $proc.WaitForExit(10000) -or $proc.ExitCode -ne 0) { throw "Installed private key failed decryption check for $($d.Login); details redacted." }
    $fingerA=((& ssh-keygen.exe -lf $pub) -split '\s+')[1]
    $publicLine=$publicFromPrivate.GetAwaiter().GetResult().Trim()
    $pubKeyData=($publicLine -split '\s+')[1]; $expectedData=((Get-Content -Raw $pub) -split '\s+')[1]
    if ($pubKeyData -ne $expectedData -or $fingerA -ne $d.Fingerprint) { throw "Keypair fingerprint mismatch for $($d.Login)." }
    $installed=Join-Path $local "G6\RabbitMQ\$($d.Login)"
    foreach ($service in $d.Services) {
      if (-not (Test-Path (Join-Path $installed "templates\$service.env.example")) -or -not (Test-Path (Join-Path $installed "secrets\$service.clixml"))) { throw "Template or protected credential missing for $service." }
      $stored=Import-Clixml (Join-Path $installed "secrets\$service.clixml"); if ($stored -isnot [Security.SecureString]) { throw "Credential was not DPAPI protected for $service." }; $stored.Dispose()
      $envDir=Join-Path $testRoot "$($d.Login)-env-test"; $null=New-Item -ItemType Directory -Force -Path $envDir; $envPath=Join-Path $envDir '.env'
      & (Join-Path $installed 'Set-G6DeveloperRabbitMqUrl.ps1') -Identity $service -Path $envPath | Out-Null
      $envText=Get-Content -Raw -LiteralPath $envPath
      if ($envText -notmatch "(?m)^RABBITMQ_URL=amqp://${service}:" -or $envText -notmatch "127\.0\.0\.1:$($d.Port)/g6-productos-ofertas") { throw "Generated local URL did not match assigned identity/port for $service." }
    }
    if (-not (Test-Path (Join-Path $installed 'Test-G6DeveloperAccess.ps1')) -or -not (Test-Path (Join-Path $installed 'Start-G6RabbitMqTunnel.ps1'))) { throw "Operational scripts missing for $($d.Login)." }
    $config=Get-Content -Raw (Join-Path $profile '.ssh\config')
    if ($config -notmatch "(?m)^Host g6-dev$" -or $config -notmatch [regex]::Escape($d.Login)) { throw "SSH alias missing for $($d.Login)." }
    if ($d.Login -eq $RunSmokeLogin) { & (Join-Path $installed 'Test-G6DeveloperAccess.ps1'); if ($LASTEXITCODE -ne 0) { throw "Installed one-command smoke failed for $($d.Login)." } }
    $global:InstallTestPassword=$null; $secure.Dispose(); $plain=$null
    Write-Output "$($d.Developer): package decrypted/authenticated, keypair validated, assigned DPAPI credentials/templates/scripts installed."
  }
} finally {
  $env:USERPROFILE=$oldProfile; $env:LOCALAPPDATA=$oldLocal; $env:HOME=$oldHome; $global:InstallTestPassword=$null
  $secure.Dispose(); $plain=$null
  $tempBase=[IO.Path]::GetFullPath($env:TEMP).TrimEnd([IO.Path]::DirectorySeparatorChar)+[IO.Path]::DirectorySeparatorChar
  $resolved=[IO.Path]::GetFullPath($testRoot)
  if (-not $resolved.StartsWith($tempBase,[StringComparison]::OrdinalIgnoreCase)) { throw 'Refusing to remove test data outside Windows TEMP.' }
  Remove-Item -LiteralPath $resolved -Recurse -Force
}
