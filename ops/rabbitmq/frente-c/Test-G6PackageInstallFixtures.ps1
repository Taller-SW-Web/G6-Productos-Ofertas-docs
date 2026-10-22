#requires -Version 7.0
param([string]$KitRoot = $PSScriptRoot)
$ErrorActionPreference = 'Stop'

. (Join-Path $KitRoot 'G6DeveloperProfile.ps1')
$profiles = @(
  [pscustomobject]@{ Login='g6_castilla'; KeyName='g6_castilla_dist'; Port=5673; Services=@('g6_masivos','g6_combos') },
  [pscustomobject]@{ Login='g6_poma'; KeyName='g6_poma'; Port=5674; Services=@('g6_catalogo') },
  [pscustomobject]@{ Login='g6_taco'; KeyName='g6_taco'; Port=5675; Services=@('g6_inventario') },
  [pscustomobject]@{ Login='g6_vera'; KeyName='g6_vera'; Port=5676; Services=@('g6_precios','g6_auditoria_precios') },
  [pscustomobject]@{ Login='g6_cueva'; KeyName='g6_cueva'; Port=5677; Services=@('g6_promociones') },
  [pscustomobject]@{ Login='g6_lopez'; KeyName='g6_lopez'; Port=5678; Services=@('g6_taxonomia') }
)
$secretSentinel = 'SYNTHETIC-AMQP-PASSWORD-ONLY'
$packagePassword = 'SYNTHETIC-PACKAGE-PASSWORD-ONLY'
$tempRoot = Join-Path $env:TEMP ('g6-package-install-fixtures-' + [Guid]::NewGuid().ToString('N'))
$oldUserProfile = $env:USERPROFILE
$oldLocalAppData = $env:LOCALAPPDATA
$oldFixturePassword = $global:G6FixturePackagePassword
function global:Read-Host {
  [CmdletBinding()]
  param([string]$Prompt,[switch]$AsSecureString)
  return ConvertTo-SecureString -String $global:G6FixturePackagePassword -AsPlainText -Force
}

function Add-ZipFixtureEntry {
  param([IO.Compression.ZipArchive]$Archive,[string]$Name,[byte[]]$Content)
  $entry = $Archive.CreateEntry($Name,[IO.Compression.CompressionLevel]::Optimal)
  $stream = $entry.Open()
  try { $stream.Write($Content,0,$Content.Length) } finally { $stream.Dispose() }
}

function New-SyntheticG6Package {
  param([hashtable]$Files,[string]$Destination)
  $memory = [IO.MemoryStream]::new()
  $zip = [IO.Compression.ZipArchive]::new($memory,[IO.Compression.ZipArchiveMode]::Create,$true)
  try { foreach ($name in $Files.Keys) { Add-ZipFixtureEntry -Archive $zip -Name $name -Content ([byte[]]$Files[$name]) } }
  finally { $zip.Dispose() }
  $plainZip = $memory.ToArray(); $memory.Dispose()
  $iterations = 300000
  $salt = [Security.Cryptography.RandomNumberGenerator]::GetBytes(16)
  $nonce = [Security.Cryptography.RandomNumberGenerator]::GetBytes(12)
  $header = [byte[]]::new(37)
  [Array]::Copy([Text.Encoding]::ASCII.GetBytes('G6PK1'),0,$header,0,5)
  [Array]::Copy($salt,0,$header,5,16)
  [Array]::Copy([BitConverter]::GetBytes([int]$iterations),0,$header,21,4)
  [Array]::Copy($nonce,0,$header,25,12)
  $derived = [Security.Cryptography.Rfc2898DeriveBytes]::Pbkdf2($packagePassword,$salt,$iterations,[Security.Cryptography.HashAlgorithmName]::SHA256,32)
  $cipher = [byte[]]::new($plainZip.Length); $tag = [byte[]]::new(16)
  $aes = [Security.Cryptography.AesGcm]::new($derived,16)
  try { $aes.Encrypt($nonce,$plainZip,$cipher,$tag,$header) } finally { $aes.Dispose() }
  $output = [IO.MemoryStream]::new()
  try { $output.Write($header,0,$header.Length); $output.Write($cipher,0,$cipher.Length); $output.Write($tag,0,$tag.Length); [IO.File]::WriteAllBytes($Destination,$output.ToArray()) }
  finally { $output.Dispose() }
  foreach ($bytes in @($plainZip,$salt,$nonce,$header,$derived,$cipher,$tag)) { [Security.Cryptography.CryptographicOperations]::ZeroMemory($bytes) }
}

try {
  $null = New-Item -ItemType Directory -Path $tempRoot
  $installer = Join-Path $KitRoot 'Install-G6DeveloperPackage.ps1'
  $helperPath = Join-Path $KitRoot 'G6DeveloperProfile.ps1'
  $manifestPath = Join-Path $KitRoot '..\rbac-rc3.json'
  $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
  $manifestBytes = [IO.File]::ReadAllBytes([IO.Path]::GetFullPath($manifestPath))
  $relativeScripts = @('Start-G6RabbitMqTunnel.ps1','Test-G6RabbitMqTunnel.ps1','Test-G6DeveloperAccess.ps1','Set-G6DeveloperRabbitMqUrl.ps1','G6DeveloperProfile.ps1','verify-pilot-amqp.mjs')

  foreach ($profile in $profiles) {
    $userRoot = Join-Path $tempRoot $profile.Login
    $localAppData = Join-Path $userRoot 'AppData\Local'
    $sshDir = Join-Path $userRoot '.ssh'
    $null = New-Item -ItemType Directory -Force -Path $sshDir
    $configPath = Join-Path $sshDir 'config'
    Set-Content -LiteralPath $configPath -Value "Host unrelated`n  User preserve-me" -Encoding ascii
    $metadata = [ordered]@{ Developer=$profile.Login; Login=$profile.Login; KeyName=$profile.KeyName; Fingerprint='SHA256:SYNTHETIC'; Services=$profile.Services; Port=$profile.Port; Vhost='g6-productos-ofertas' }
    $files = @{}
    $files['developer.json'] = [Text.UTF8Encoding]::new($false).GetBytes(($metadata | ConvertTo-Json -Depth 5))
    $files["ssh/$($profile.KeyName)"] = [byte[]]@(1,2,3,4)
    $files["ssh/$($profile.KeyName).pub"] = [Text.Encoding]::ASCII.GetBytes('ssh-ed25519 SYNTHETIC-PUBLIC-KEY fixture')
    $sshConfig = "Host g6-dev`n    HostName 157.137.205.218`n    User $($profile.Login)`n    Port 22`n    IdentityFile ~/.ssh/$($profile.KeyName)`n    IdentitiesOnly yes`n    ForwardAgent no`n"
    $files['ssh-config'] = [Text.UTF8Encoding]::new($false).GetBytes($sshConfig)
    foreach ($name in $relativeScripts) { $files["scripts/$name"] = [IO.File]::ReadAllBytes((Join-Path $KitRoot $name)) }
    $files['scripts/rbac-rc3.json'] = $manifestBytes
    $files['install/README.txt'] = [Text.Encoding]::UTF8.GetBytes("Synthetic fixture for $($profile.Login). Run scripts with pwsh.exe.")
    $files['install/Install-G6DeveloperPackage.ps1'] = [IO.File]::ReadAllBytes($installer)
    $credentialObjects = foreach ($identity in $profile.Services) {
      if (-not ($manifest.users | Where-Object username -EQ $identity)) { throw "Manifest missing synthetic fixture identity $identity." }
      [pscustomobject]@{ username=$identity; vhost='g6-productos-ofertas'; password=$secretSentinel }
      $templatePath = Join-Path (Join-Path $KitRoot 'templates') "$identity.env.example"
      $template = (Get-Content -Raw -LiteralPath $templatePath) -replace '127\.0\.0\.1:\d+/',"127.0.0.1:$($profile.Port)/"
      $files["templates/$identity.env.example"] = [Text.UTF8Encoding]::new($false).GetBytes($template)
    }
    $files['secrets/credentials.json'] = [Text.UTF8Encoding]::new($false).GetBytes((ConvertTo-Json -InputObject @($credentialObjects) -Depth 4 -Compress))
    $packagePath = Join-Path $tempRoot "$($profile.Login).g6pkg"
    New-SyntheticG6Package -Files $files -Destination $packagePath

    $env:USERPROFILE = $userRoot
    $env:LOCALAPPDATA = $localAppData
    $global:G6FixturePackagePassword = $packagePassword
    $installerOutput = & $installer -PackagePath $packagePath 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or $installerOutput -match [regex]::Escape($secretSentinel)) { throw "Synthetic installer failed or leaked a fixture value for $($profile.Login)." }

    $installed = Join-Path $localAppData "G6\RabbitMQ\$($profile.Login)"
    foreach ($required in @('developer.json','G6DeveloperProfile.ps1','Start-G6RabbitMqTunnel.ps1','Test-G6RabbitMqTunnel.ps1','Test-G6DeveloperAccess.ps1','Set-G6DeveloperRabbitMqUrl.ps1','verify-pilot-amqp.mjs','rbac-rc3.json')) {
      if (-not (Test-Path -LiteralPath (Join-Path $installed $required) -PathType Leaf)) { throw "Installed package omitted $required for $($profile.Login)." }
    }
    $installedSmoke = Get-Content -Raw -LiteralPath (Join-Path $installed 'Test-G6DeveloperAccess.ps1')
    foreach ($dependency in @("Join-Path `$installRoot 'G6DeveloperProfile.ps1'","Join-Path `$installRoot 'verify-pilot-amqp.mjs'","Join-Path `$installRoot 'rbac-rc3.json'")) {
      if (-not $installedSmoke.Contains($dependency)) { throw "Installed smoke has an invalid relative dependency for $($profile.Login)." }
    }
    if ($installedSmoke -notmatch '\$port=\[int\]\$meta\.Port' -or $installedSmoke -notmatch '\$meta\.Login' -or $installedSmoke -notmatch '\$meta\.KeyName') { throw "Installed smoke did not use the installed developer profile for $($profile.Login)." }
    . (Join-Path $installed 'G6DeveloperProfile.ps1')
    $loaded = Get-G6DeveloperProfile -PackageRoot $installed
    if ($loaded.Port -ne $profile.Port -or $loaded.Login -ne $profile.Login) { throw "Installed helper resolved wrong metadata for $($profile.Login)." }
    $startResult = $null
    try { & (Join-Path $installed 'Start-G6RabbitMqTunnel.ps1') -LocalPort ($profile.Port + 100) -SshConfigPath (Join-Path $sshDir 'missing-config') 2>&1 | Out-String } catch { $startResult = $_.Exception.Message }
    if ($startResult -notmatch 'does not match package port') { throw "Installed tunnel script did not resolve developer.json for $($profile.Login)." }
    $tcpResult = $null
    try { & (Join-Path $installed 'Test-G6RabbitMqTunnel.ps1') -LocalPort ($profile.Port + 100) 2>&1 | Out-String } catch { $tcpResult = $_.Exception.Message }
    if ($tcpResult -notmatch 'does not match package port') { throw "Installed TCP test did not resolve developer.json for $($profile.Login)." }

    $service = $profile.Services[0]
    $envPath = Join-Path $userRoot "$($profile.Login)-service\.env"
    $urlOutput = & (Join-Path $installed 'Set-G6DeveloperRabbitMqUrl.ps1') -Identity $service -Path $envPath 2>&1 | Out-String
    $envContents = [IO.File]::ReadAllText($envPath)
    if ($urlOutput -match [regex]::Escape($secretSentinel) -or -not ($envContents.Contains("RABBITMQ_URL=amqp://${service}:") -and $envContents.Contains("@127.0.0.1:$($profile.Port)/g6-productos-ofertas"))) { throw "Installed URL helper failed its local profile/secret handling check for $($profile.Login)." }

    $sshResolved = & ssh.exe -F $configPath -G g6-dev 2>$null
    if ($LASTEXITCODE -ne 0 -or -not ($sshResolved -match "(?m)^user\s+$($profile.Login)$") -or -not ($sshResolved -match "(?m)^identityfile\s+.*$([regex]::Escape($profile.KeyName))$")) { throw "Installed SSH login/key mapping failed for $($profile.Login)." }
    $existingConfig = Get-Content -Raw -LiteralPath $configPath
    if ($existingConfig -notmatch 'Host unrelated' -or $existingConfig -notmatch 'preserve-me') { throw "Unrelated SSH configuration was changed for $($profile.Login)." }

    $rootAcl = @(Get-Acl -LiteralPath $installed).Access | Where-Object { $_.AccessControlType -eq 'Allow' }
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    foreach ($requiredPrincipal in @($currentIdentity,'NT AUTHORITY\SYSTEM')) {
      if (-not ($rootAcl | Where-Object { $_.IdentityReference.Value -eq $requiredPrincipal })) { throw "Required install ACL principal missing for $($profile.Login)." }
    }
    if (@($rootAcl | Where-Object { $_.IdentityReference.Value -notin @($currentIdentity,'NT AUTHORITY\SYSTEM') }).Count -gt 0) { throw "Unexpected additional install ACL principal for $($profile.Login)." }
    $keyAcl = @(Get-Acl -LiteralPath (Join-Path $sshDir $profile.KeyName)).Access | Where-Object { $_.AccessControlType -eq 'Allow' }
    foreach ($requiredPrincipal in @($currentIdentity,'NT AUTHORITY\SYSTEM')) {
      if (-not ($keyAcl | Where-Object { $_.IdentityReference.Value -eq $requiredPrincipal })) { throw "Required private-key ACL principal missing for $($profile.Login)." }
    }
    if (@($keyAcl | Where-Object { $_.IdentityReference.Value -notin @($currentIdentity,'NT AUTHORITY\SYSTEM') }).Count -gt 0) { throw "Unexpected additional private-key ACL principal for $($profile.Login)." }
    if (Get-ChildItem -LiteralPath $userRoot -Recurse -File -Filter '.g6-*' | Where-Object { $_.Name -match '\.tmp$' }) { throw "A synthetic temporary secret file was left behind for $($profile.Login)." }
    Write-Output "PASS synthetic installation: $($profile.Login), port $($profile.Port), identities $($profile.Services -join ', '), helper/scripts/manifest, SSH mapping, URL, ACL, and no overwrite."
  }
} finally {
  $env:USERPROFILE = $oldUserProfile
  $env:LOCALAPPDATA = $oldLocalAppData
  $global:G6FixturePackagePassword = $oldFixturePassword
  Remove-Item Function:\global:Read-Host -ErrorAction SilentlyContinue
  $tempBase = [IO.Path]::GetFullPath($env:TEMP).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
  $resolved = [IO.Path]::GetFullPath($tempRoot)
  if (-not $resolved.StartsWith($tempBase,[StringComparison]::OrdinalIgnoreCase)) { throw 'Refusing to remove fixture data outside Windows TEMP.' }
  if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
