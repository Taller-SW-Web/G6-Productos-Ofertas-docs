#requires -Version 7.0
param([Parameter(Mandatory=$true)][string]$PackagePath)
$ErrorActionPreference='Stop'
if (-not (Test-Path -LiteralPath $PackagePath -PathType Leaf)) { throw 'Encrypted package not found.' }
$magic=[Text.Encoding]::ASCII.GetBytes('G6PK1')
$package=[IO.File]::ReadAllBytes([IO.Path]::GetFullPath($PackagePath))
if ($package.Length -lt 53 -or [Text.Encoding]::ASCII.GetString($package,0,5) -ne 'G6PK1') { throw 'Invalid G6 encrypted package.' }
$salt=[byte[]]$package[5..20]; $iterations=[BitConverter]::ToInt32($package,21); $nonce=[byte[]]$package[25..36]
if ($iterations -lt 300000 -or $iterations -gt 2000000) { throw 'Package KDF parameters are outside the supported safe range.' }
$tagOffset=$package.Length-16
$cipher=[byte[]]$package[37..($tagOffset-1)]; $tag=[byte[]]$package[$tagOffset..($package.Length-1)]; $aad=[byte[]]$package[0..36]
$securePassword=Read-Host 'Contraseña individual del paquete' -AsSecureString
$password=[Net.NetworkCredential]::new('', $securePassword).Password
$zipBytes=[byte[]]::new($cipher.Length)
$derived=[Security.Cryptography.Rfc2898DeriveBytes]::Pbkdf2($password,$salt,$iterations,[Security.Cryptography.HashAlgorithmName]::SHA256,32)
$aes=[Security.Cryptography.AesGcm]::new($derived,16)
try { $aes.Decrypt($nonce,$cipher,$tag,$zipBytes,$aad) } catch {
  [Security.Cryptography.CryptographicOperations]::ZeroMemory($zipBytes)
  [Security.Cryptography.CryptographicOperations]::ZeroMemory($derived)
  throw 'No se pudo autenticar el paquete; contraseña incorrecta o archivo dañado.'
} finally { $aes.Dispose() }
$memory=[IO.MemoryStream]::new($zipBytes,$false)
$archive=[IO.Compression.ZipArchive]::new($memory,[IO.Compression.ZipArchiveMode]::Read,$false)
$files=@{}
$credentials=$null
try {
  foreach ($entry in $archive.Entries) {
    if ([string]::IsNullOrWhiteSpace($entry.FullName) -or $entry.FullName.StartsWith('/') -or $entry.FullName -match '(^|/)\.\.(/|$)' -or $entry.FullName.Contains('\\')) { throw 'Unsafe path in encrypted package.' }
    $stream=$entry.Open(); $out=[IO.MemoryStream]::new(); $stream.CopyTo($out); $stream.Dispose(); $bytes=$out.ToArray(); $out.Dispose()
    if ($entry.FullName -eq 'secrets/credentials.json') { $credentials=[Text.UTF8Encoding]::new($false,$true).GetString($bytes); [Security.Cryptography.CryptographicOperations]::ZeroMemory($bytes) }
    else { $files[$entry.FullName]=$bytes }
  }
  if (-not $files.ContainsKey('developer.json') -or -not $files.ContainsKey('ssh-config') -or -not $credentials) { throw 'Package is missing required installation files.' }
  $meta=[Text.UTF8Encoding]::new($false,$true).GetString($files['developer.json']) | ConvertFrom-Json
  if ($meta.Login -notmatch '^g6_(castilla|poma|taco|vera|cueva|lopez)$' -or $meta.KeyName -notmatch '^g6_[a-z0-9_]+$') { throw 'Package identity is not in the approved G6 list.' }
  if (-not $files.ContainsKey('scripts/G6DeveloperProfile.ps1')) { throw 'Package is missing its G6 profile helper.' }
  $profileHelperText=[Text.UTF8Encoding]::new($false,$true).GetString($files['scripts/G6DeveloperProfile.ps1'])
  . ([ScriptBlock]::Create($profileHelperText))
  $meta=Assert-G6DeveloperProfile -Profile $meta
  $credentialsObject=$credentials | ConvertFrom-Json
  $credentialNames=@($credentialsObject | ForEach-Object { $_.username })
  if ($credentialNames.Count -ne @($meta.Services).Count -or @(Compare-Object @($meta.Services) $credentialNames).Count -ne 0 -or @($credentialNames | Select-Object -Unique).Count -ne $credentialNames.Count) { throw 'Package credentials do not match the assigned service identities.' }
  foreach ($credential in $credentialsObject) { if ($credential.vhost -ne $meta.Vhost -or -not $credential.password) { throw 'Invalid credential data in package.' } }
  $sshDir=Join-Path $env:USERPROFILE '.ssh'; $configPath=Join-Path $sshDir 'config'
  if (Test-Path -LiteralPath $configPath) { if (Select-String -LiteralPath $configPath -Pattern '(?im)^\s*Host\s+[^\r\n]*\bg6-dev\b') { throw 'SSH alias g6-dev already exists; review the existing config before installing.' } }
  $localRoot=Join-Path $env:LOCALAPPDATA "G6\RabbitMQ\$($meta.Login)"
  if (Test-Path -LiteralPath $localRoot) { throw 'A G6 installation directory already exists; inspect and recover it manually before retrying.' }
  $installPlan=Get-G6PackageInstallFilePlan -Files $files -Credentials $credentialsObject -Profile $meta -UserProfile $env:USERPROFILE -LocalAppData $env:LOCALAPPDATA
  Assert-G6PackageInstallFilePlanAvailable -Destinations $installPlan
  $null=New-Item -ItemType Directory -Force -Path $sshDir
  $null=New-Item -ItemType Directory -Path $localRoot
  Set-G6PrivateAclOnNewPath -Path $localRoot -Directory | Out-Null
  foreach ($directory in @((Join-Path $localRoot 'templates'),(Join-Path $localRoot 'secrets'))) { $null=New-Item -ItemType Directory -Path $directory; Set-G6PrivateAclOnNewPath -Path $directory -Directory | Out-Null }
  foreach ($name in $files.Keys) {
    if ($name -eq 'developer.json' -or $name -eq 'ssh-config') { continue }
    if ($name -match '^ssh/(.+)$') {
      $sshMember=$Matches[1]
      $dest=Join-Path $sshDir $sshMember
    }
    elseif ($name -match '^templates/(.+)$') { $dest=Join-Path (Join-Path $localRoot 'templates') $Matches[1] }
    else { $dest=Join-Path $localRoot ($name -replace '^(scripts|install)/','') }
    $parent=Split-Path -Parent $dest; $null=New-Item -ItemType Directory -Force -Path $parent
    Write-G6NewFile -Path $dest -Content ([byte[]]$files[$name])
    if ($name -match '^ssh/(.+)$' -and $Matches[1] -eq $meta.KeyName) {
      Assert-G6PrivateAcl -Path $dest | Out-Null
    }
  }
  foreach ($credential in $credentialsObject) {
    if ($credential.username -notmatch '^g6_[a-z_]+$' -or $credential.vhost -ne 'g6-productos-ofertas' -or -not $credential.password) { throw 'Invalid credential data in package.' }
    $secret=ConvertTo-SecureString -String $credential.password -AsPlainText -Force
    Export-G6SecureStringNewFile -Value $secret -Path (Join-Path (Join-Path $localRoot 'secrets') "$($credential.username).clixml")
    $secret.Dispose(); $credential.password=$null
  }
  $keyPass=ConvertTo-SecureString -String $password -AsPlainText -Force
  Export-G6SecureStringNewFile -Value $keyPass -Path (Join-Path $localRoot 'secrets\key-passphrase.clixml')
  $keyPass.Dispose()
  Write-G6NewFile -Path (Join-Path $localRoot 'developer.json') -Content ([byte[]]$files['developer.json'])
  $sshConfigText=[Text.UTF8Encoding]::new($false,$true).GetString($files['ssh-config'])
  $sshKeyPrefix=[IO.Path]::GetFullPath($sshDir).Replace('\','/')
  $sshConfigText=$sshConfigText.Replace('~/.ssh/',"$sshKeyPrefix/")
  if (-not (Test-Path -LiteralPath $configPath)) { Write-G6NewFile -Path $configPath -Content ([Text.UTF8Encoding]::new($false).GetBytes($sshConfigText)) }
  else {
    if (Select-String -LiteralPath $configPath -Pattern '(?im)^\s*Host\s+[^\r\n]*\bg6-dev\b') { throw 'SSH alias g6-dev appeared during installation; refusing to modify the config.' }
    [IO.File]::AppendAllText($configPath,[Environment]::NewLine+$sshConfigText,[Text.UTF8Encoding]::new($false))
  }
  $privateKey=Join-Path $sshDir $meta.KeyName
  Write-Output "Instalación lista para $($meta.Developer). Alias: g6-dev; puerto local: $($meta.Port). Archivos y secretos guardados bajo DPAPI en el perfil local."
  Write-Output "Ejecuta: pwsh.exe -ExecutionPolicy Bypass -File `"$(Join-Path $localRoot 'Test-G6DeveloperAccess.ps1')`""
} finally {
  $archive.Dispose(); $memory.Dispose()
  [Security.Cryptography.CryptographicOperations]::ZeroMemory($zipBytes)
  [Security.Cryptography.CryptographicOperations]::ZeroMemory($derived)
  $password=$null; $credentials=$null; $securePassword.Dispose()
  if ($credentialsObject) { foreach ($credential in $credentialsObject) { $credential.password=$null }; $credentialsObject=$null }
  foreach ($value in $files.Values) { if ($value -is [byte[]]) { [Security.Cryptography.CryptographicOperations]::ZeroMemory($value) } }
  [Security.Cryptography.CryptographicOperations]::ZeroMemory($cipher)
}
