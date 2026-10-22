#requires -Version 7.0
param([string]$Root = (Join-Path $env:LOCALAPPDATA 'G6\RabbitMQ\onboarding'))
$ErrorActionPreference='Stop'
$iterations=600000
$current=[Security.Principal.WindowsIdentity]::GetCurrent().Name
if (-not (Test-Path -LiteralPath $Root -PathType Container)) { throw 'Onboarding root does not exist; run the key inventory step first.' }
icacls $Root /reset /T /C | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Could not reset onboarding package directory ACLs.' }
icacls $Root /inheritance:r /grant:r "$current`:(OI)(CI)F" 'NT AUTHORITY\SYSTEM:(OI)(CI)F' /T /C | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Could not restrict onboarding package directory ACLs.' }
$vaultPath=Join-Path $Root 'admin-vault.dpapi.json'
$vault=Get-Content -Raw -LiteralPath $vaultPath | ConvertFrom-Json
$credentialVault=Get-Content -Raw -LiteralPath (Join-Path $env:LOCALAPPDATA 'G6\RabbitMQ\frontb-credentials.dpapi.json') | ConvertFrom-Json
$manifest=Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot '..\rbac-rc3.json') | ConvertFrom-Json
$bootstrapPath=Join-Path $PSScriptRoot 'Install-G6DeveloperPackage.ps1'
$amqpScript=Join-Path $PSScriptRoot 'verify-pilot-amqp.mjs'
$tunnelScript=Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'Start-G6RabbitMqTunnel.ps1')
$tcpScript=Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'Test-G6RabbitMqTunnel.ps1')
foreach ($dev in $vault.developers) {
  $fileMap=[Collections.Generic.Dictionary[string,byte[]]]::new([StringComparer]::Ordinal)
  $keyBytes=[IO.File]::ReadAllBytes($dev.KeyPath); $pubBytes=[IO.File]::ReadAllBytes($dev.PublicKeyPath)
  $fileMap["ssh/$($dev.KeyName)"]=$keyBytes; $fileMap["ssh/$($dev.KeyName).pub"]=$pubBytes
  $meta=[ordered]@{Developer=$dev.Developer;Login=$dev.Login;KeyName=$dev.KeyName;Fingerprint=$dev.Fingerprint;Services=@($dev.Services);Port=[int]$dev.Port;Vhost='g6-productos-ofertas'}
  $fileMap['developer.json']=[Text.UTF8Encoding]::new($false).GetBytes(($meta | ConvertTo-Json -Depth 5))
  $sshConfig=@"
Host g6-dev
    HostName 157.137.205.218
    User $($dev.Login)
    Port 22
    IdentityFile ~/.ssh/$($dev.KeyName)
    IdentitiesOnly yes
    ForwardAgent no
    RequestTTY no
    AddKeysToAgent yes
    ServerAliveInterval 15
    ServerAliveCountMax 3
    ExitOnForwardFailure yes
"@
  $fileMap['ssh-config']=[Text.UTF8Encoding]::new($false).GetBytes($sshConfig)
  $fileMap['scripts/Start-G6RabbitMqTunnel.ps1']=[Text.UTF8Encoding]::new($false).GetBytes($tunnelScript)
  $fileMap['scripts/Test-G6RabbitMqTunnel.ps1']=[Text.UTF8Encoding]::new($false).GetBytes($tcpScript)
  $fileMap['scripts/Test-G6DeveloperAccess.ps1']=[IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'Test-G6DeveloperAccess.ps1'))
  $fileMap['scripts/Set-G6DeveloperRabbitMqUrl.ps1']=[IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'Set-G6DeveloperRabbitMqUrl.ps1'))
  $fileMap['scripts/G6DeveloperProfile.ps1']=[IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'G6DeveloperProfile.ps1'))
  $fileMap['scripts/verify-pilot-amqp.mjs']=[IO.File]::ReadAllBytes($amqpScript)
  $fileMap['scripts/rbac-rc3.json']=[IO.File]::ReadAllBytes((Join-Path $PSScriptRoot '..\rbac-rc3.json'))
  $fileMap['install/Install-G6DeveloperPackage.ps1']=[IO.File]::ReadAllBytes($bootstrapPath)
  $readme=@"
G6 RabbitMQ local developer access — $($dev.Developer)

1. Open PowerShell 7 in the folder with the self-contained installer `$($dev.Login)-installer.ps1` and run:
   pwsh.exe -ExecutionPolicy Bypass -File .\$($dev.Login)-installer.ps1
2. Enter the individual package password when prompted.
3. Run the installed one-command smoke shown by the installer.
4. To configure a local service .env without displaying its secret, run:
   pwsh.exe -ExecutionPolicy Bypass -File "`$env:LOCALAPPDATA\G6\RabbitMQ\$($dev.Login)\Set-G6DeveloperRabbitMqUrl.ps1" -Identity <assigned_g6_identity> -Path <service-folder>\.env
   The helper requires the target .env to be ignored by Git and writes only the assigned identity URL.
5. Start the tunnel when developing:
   pwsh.exe -ExecutionPolicy Bypass -File "`$env:LOCALAPPDATA\G6\RabbitMQ\$($dev.Login)\Start-G6RabbitMqTunnel.ps1"
   The SSH key passphrase is the same individual password used to open this package.

The package includes only the assigned RabbitMQ identities: $($dev.Services -join ', ').
Edit local .env.example templates in your service workspace; do not commit filled secrets.
Each assigned service identity has its own DPAPI-protected local credential file after install.
The local smoke proves the current PC only; it does not validate another developer's PC.
"@
  $fileMap['install/README.txt']=[Text.UTF8Encoding]::new($false).GetBytes($readme)
  $envMap=[Collections.Generic.List[object]]::new()
  foreach ($identity in $dev.Services) {
    $template=Join-Path $PSScriptRoot "templates\$identity.env.example"
    if (-not (Test-Path -LiteralPath $template)) { throw "Missing environment template for $identity." }
    $text=(Get-Content -Raw -LiteralPath $template) -replace '127\.0\.0\.1:\d+/',"127.0.0.1:$($meta.Port)/"
    $fileMap["templates/$identity.env.example"]=[Text.UTF8Encoding]::new($false).GetBytes($text)
    $service=$manifest.users | Where-Object username -EQ $identity | Select-Object -First 1
    $source=$credentialVault.credentials | Where-Object username -EQ $identity | Select-Object -First 1
    if (-not $service -or -not $source) { throw "Credential or contract manifest missing identity $identity." }
    $secure=ConvertTo-SecureString -String $source.protectedPassword
    $plain=[Net.NetworkCredential]::new('', $secure).Password
    $envMap.Add([pscustomobject]@{username=$identity;vhost='g6-productos-ofertas';password=$plain})
    $secure.Dispose(); $plain=$null
  }
  $credentialJson=ConvertTo-Json -InputObject @($envMap) -Depth 4 -Compress
  $credentialBytes=[Text.UTF8Encoding]::new($false).GetBytes($credentialJson)
  $fileMap['secrets/credentials.json']=$credentialBytes
  $memory=[IO.MemoryStream]::new()
  $zip=[IO.Compression.ZipArchive]::new($memory,[IO.Compression.ZipArchiveMode]::Create,$true)
  try {
    foreach ($name in $fileMap.Keys) {
      $entry=$zip.CreateEntry($name,[IO.Compression.CompressionLevel]::Optimal)
      $stream=$entry.Open(); $stream.Write($fileMap[$name],0,$fileMap[$name].Length); $stream.Dispose()
    }
  } finally { $zip.Dispose() }
  $zipBytes=$memory.ToArray()
  $zipBuffer=$memory.GetBuffer(); [Security.Cryptography.CryptographicOperations]::ZeroMemory($zipBuffer); $memory.Dispose()
  $securePackage=ConvertTo-SecureString -String $dev.ProtectedPackagePassword
  $password=[Net.NetworkCredential]::new('', $securePackage).Password
  $salt=[Security.Cryptography.RandomNumberGenerator]::GetBytes(16); $nonce=[Security.Cryptography.RandomNumberGenerator]::GetBytes(12)
  $derived=[Security.Cryptography.Rfc2898DeriveBytes]::Pbkdf2($password,$salt,$iterations,[Security.Cryptography.HashAlgorithmName]::SHA256,32)
  $header=[byte[]]::new(37); [Array]::Copy([Text.Encoding]::ASCII.GetBytes('G6PK1'),0,$header,0,5); [Array]::Copy($salt,0,$header,5,16); [Array]::Copy([BitConverter]::GetBytes([int]$iterations),0,$header,21,4); [Array]::Copy($nonce,0,$header,25,12)
  $cipher=[byte[]]::new($zipBytes.Length); $tag=[byte[]]::new(16); $aes=[Security.Cryptography.AesGcm]::new($derived,16)
  $aes.Encrypt($nonce,$zipBytes,$cipher,$tag,$header); $aes.Dispose()
  $output=[IO.MemoryStream]::new(); $output.Write($header,0,$header.Length); $output.Write($cipher,0,$cipher.Length); $output.Write($tag,0,$tag.Length)
  $packageBytes=$output.ToArray(); $output.Dispose()
  [IO.File]::WriteAllBytes($dev.PackagePayloadPath,$packageBytes)
  icacls $dev.PackagePayloadPath /inheritance:r /grant:r "$current`:(F)" 'NT AUTHORITY\SYSTEM:(F)' | Out-Null
  $payloadHash=(Get-FileHash -Algorithm SHA256 -LiteralPath $dev.PackagePayloadPath).Hash
  $payloadB64=[Convert]::ToBase64String($packageBytes)
  $bootstrapB64=[Convert]::ToBase64String([IO.File]::ReadAllBytes($bootstrapPath))
  $wrapperTemplate=@'
#requires -Version 7.0
$ErrorActionPreference='Stop'
$payload=[Convert]::FromBase64String('__G6_ENCRYPTED_PAYLOAD__')
$bootstrapBytes=[Convert]::FromBase64String('__G6_BOOTSTRAP__')
$tempRoot=Join-Path $env:TEMP ('g6-package-unlock-'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $tempRoot
$payloadPath=Join-Path $tempRoot 'developer.g6pkg'
try {
  [IO.File]::WriteAllBytes($payloadPath,$payload)
  $bootstrap=[ScriptBlock]::Create([Text.UTF8Encoding]::new($false,$true).GetString($bootstrapBytes))
  & $bootstrap -PackagePath $payloadPath
} finally {
  [Security.Cryptography.CryptographicOperations]::ZeroMemory($payload)
  [Security.Cryptography.CryptographicOperations]::ZeroMemory($bootstrapBytes)
  $tempBase=[IO.Path]::GetFullPath($env:TEMP).TrimEnd([IO.Path]::DirectorySeparatorChar)+[IO.Path]::DirectorySeparatorChar
  $resolved=[IO.Path]::GetFullPath($tempRoot)
  if (-not $resolved.StartsWith($tempBase,[StringComparison]::OrdinalIgnoreCase)) { throw 'Refusing to remove a package temp path outside Windows TEMP.' }
  if (Test-Path -LiteralPath $payloadPath) { Remove-Item -LiteralPath $payloadPath -Force }
  if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Force }
}
'@
  $wrapper=$wrapperTemplate.Replace('__G6_ENCRYPTED_PAYLOAD__',$payloadB64).Replace('__G6_BOOTSTRAP__',$bootstrapB64)
  [IO.File]::WriteAllText($dev.PackagePath,$wrapper,[Text.UTF8Encoding]::new($false))
  icacls $dev.PackagePath /inheritance:r /grant:r "$current`:(F)" 'NT AUTHORITY\SYSTEM:(F)' | Out-Null
  $hash=(Get-FileHash -Algorithm SHA256 -LiteralPath $dev.PackagePath).Hash
  $dev | Add-Member -NotePropertyName PackageSHA256 -NotePropertyValue $hash -Force
  $dev | Add-Member -NotePropertyName PackagePayloadSHA256 -NotePropertyValue $payloadHash -Force
  $dev | Add-Member -NotePropertyName PackageCreatedUtc -NotePropertyValue ([DateTime]::UtcNow.ToString('o')) -Force
  $dev | Add-Member -NotePropertyName PackageCreated -NotePropertyValue $true -Force
  $dev.AccountCreated=$true; $dev.PublicKeyRegistered=$true; $dev.TunnelTestedFromAdminPc=$true
  $credentialJson=$null; $envMap.Clear(); $password=$null; $securePackage.Dispose()
  foreach ($arr in @($keyBytes,$pubBytes,$credentialBytes,$zipBytes,$zipBuffer,$derived,$cipher,$tag,$packageBytes)) { if ($arr -is [byte[]]) { [Security.Cryptography.CryptographicOperations]::ZeroMemory($arr) } }
  foreach ($value in $fileMap.Values) { if ($value -is [byte[]]) { [Security.Cryptography.CryptographicOperations]::ZeroMemory($value) } }
  $dev | Add-Member -NotePropertyName PackagePayloadPath -NotePropertyValue $dev.PackagePayloadPath -Force
  Write-Output "$($dev.Developer): self-contained AES-256-GCM installer created; SHA-256 $hash; encrypted payload SHA-256 $payloadHash."
}
$vault.createdUtc=[DateTime]::UtcNow.ToString('o')
$vault | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $vaultPath -Encoding utf8
$current=[Security.Principal.WindowsIdentity]::GetCurrent().Name
