#requires -Version 7.0
param([string]$KitRoot = $PSScriptRoot)
$ErrorActionPreference = 'Stop'

$expected = @(
  [pscustomobject]@{ Login='g6_castilla'; KeyName='g6_castilla_dist'; Port=5673; Services=@('g6_masivos','g6_combos') },
  [pscustomobject]@{ Login='g6_poma'; KeyName='g6_poma'; Port=5674; Services=@('g6_catalogo') },
  [pscustomobject]@{ Login='g6_taco'; KeyName='g6_taco'; Port=5675; Services=@('g6_inventario') },
  [pscustomobject]@{ Login='g6_vera'; KeyName='g6_vera'; Port=5676; Services=@('g6_precios','g6_auditoria_precios') },
  [pscustomobject]@{ Login='g6_cueva'; KeyName='g6_cueva'; Port=5677; Services=@('g6_promociones') },
  [pscustomobject]@{ Login='g6_lopez'; KeyName='g6_lopez'; Port=5678; Services=@('g6_taxonomia') }
)
$keysScript = Get-Content -Raw -LiteralPath (Join-Path $KitRoot 'New-G6DeveloperKeys.ps1')
$packagesScript = Get-Content -Raw -LiteralPath (Join-Path $KitRoot 'New-G6DeveloperPackages.ps1')
$tunnelScript = Get-Content -Raw -LiteralPath (Join-Path $KitRoot 'Start-G6RabbitMqTunnel.ps1')
$urlScript = Get-Content -Raw -LiteralPath (Join-Path $KitRoot 'Set-G6DeveloperRabbitMqUrl.ps1')
$installerScript = Get-Content -Raw -LiteralPath (Join-Path $KitRoot 'Install-G6DeveloperPackage.ps1')
$accessScript = Get-Content -Raw -LiteralPath (Join-Path $KitRoot 'Test-G6DeveloperAccess.ps1')
$tcpTestScript = Get-Content -Raw -LiteralPath (Join-Path $KitRoot 'Test-G6RabbitMqTunnel.ps1')
$profileHelper = Join-Path $KitRoot 'G6DeveloperProfile.ps1'
$tempRoot = Join-Path $env:TEMP ('g6-onboarding-fixtures-' + [Guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $tempRoot
try {
  . $profileHelper
  foreach ($person in $expected) {
    $sourcePattern = "Developer='[^']+'; Login='$($person.Login)'; KeyName='$([regex]::Escape($person.KeyName))'; Services=@\(([^)]*)\); Port=$($person.Port)"
    $accountMatch = [regex]::Match($keysScript,$sourcePattern)
    if (-not $accountMatch.Success) { throw "Source account mapping mismatch for $($person.Login)." }
    $sourceServices = @([regex]::Matches($accountMatch.Groups[1].Value,"'(g6_[a-z_]+)'") | ForEach-Object { $_.Groups[1].Value })
    if (@(Compare-Object $person.Services $sourceServices).Count -ne 0) { throw "RabbitMQ identity assignment mismatch for $($person.Login)." }
    if ($packagesScript -notmatch [regex]::Escape('IdentityFile ~/.ssh/$($dev.KeyName)')) { throw "SSH key mapping expression missing for $($person.Login)." }
    if ($packagesScript -notmatch 'User \$\(\$dev\.Login\)' -or $packagesScript -notmatch 'Port=\[int\]\$dev\.Port' -or $packagesScript -notmatch '127\.0\.0\.1:\$\(\$meta\.Port\)') { throw "SSH login and package metadata mapping mismatch for $($person.Login)." }
    $root = Join-Path $tempRoot $person.Login
    $null = New-Item -ItemType Directory -Path $root
    $meta = [pscustomobject]@{ Developer=$person.Login; Login=$person.Login; KeyName=$person.KeyName; Fingerprint='SYNTHETIC'; Services=$person.Services; Port=$person.Port; Vhost='g6-productos-ofertas' }
    $meta | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $root 'developer.json') -Encoding utf8
    $profile = Get-G6DeveloperProfile -PackageRoot $root
    if ($profile.Port -ne $person.Port -or @($profile.Services).Count -ne $person.Services.Count) { throw "Metadata fixture mismatch for $($person.Login)." }
    if ($packagesScript -notmatch '\$\(\$meta\.Port\)' -or $tunnelScript -notmatch '\$LocalPort\s*=\s*\$profile\.Port' -or $tcpTestScript -notmatch '\$LocalPort\s*=\s*\$profile\.Port' -or $urlScript -notmatch '\$\(\$meta\.Port\)' -or $accessScript -notmatch '\$port=\[int\]\$meta\.Port' -or $accessScript -notmatch '\$meta\.KeyName') { throw "Package template, tunnel, TCP test, URL and access smoke must use developer.json for $($person.Login)." }
    Write-Output "PASS fixture: $($person.Login), key $($person.KeyName), local port $($person.Port), identities $($person.Services -join ', ')."
  }

  if ($installerScript -notmatch 'pwsh\.exe' -or $installerScript -match 'powershell\.exe') { throw 'Installer guidance must invoke PowerShell 7 as pwsh.exe.' }
  if ($packagesScript -notmatch 'pwsh\.exe' -or $packagesScript -match 'powershell\.exe') { throw 'Generated package instructions must invoke pwsh.exe.' }
  foreach ($scriptName in @('New-G6DeveloperKeys.ps1','New-G6DeveloperPackages.ps1','Install-G6DeveloperPackage.ps1','Set-G6DeveloperRabbitMqUrl.ps1','Test-G6DeveloperAccess.ps1','Test-G6DeveloperPackages.ps1','Test-G6OnboardingSsh.ps1','Test-G6OnboardingAmqp.ps1','Test-G6RabbitMqTunnelReconnect.ps1','Add-G6RabbitMqDeveloper.ps1','Add-G6RabbitMqDeveloperKey.ps1')) {
    $firstLine=Get-Content -LiteralPath (Join-Path $KitRoot $scriptName) -TotalCount 1
    if ($firstLine -ne '#requires -Version 7.0') { throw "$scriptName must retain an explicit PowerShell 7 version requirement." }
  }
  $legacyNames = '(?i)CodexSandboxUsers|Renato\\|renato\\marec|C:\\Users\\marec'
  foreach ($source in @($keysScript,$packagesScript,$installerScript)) { if ($source -match $legacyNames) { throw 'An unnecessary hard-coded Windows identity or profile path remains in an installer.' } }
  foreach ($path in @((Join-Path $KitRoot 'New-G6DeveloperKeys.ps1'),(Join-Path $KitRoot 'New-G6DeveloperPackages.ps1'))) {
    $source = Get-Content -Raw -LiteralPath $path
    if ($source -match 'icacls.*CodexSandboxUsers|icacls.*renato\\marec') { throw 'An onboarding ACL grants a fixed additional Windows identity.' }
  }

  $fixtureUser = Join-Path $tempRoot 'user'; $fixtureLocal = Join-Path $tempRoot 'local'
  $ssh = Join-Path $fixtureUser '.ssh'; $null = New-Item -ItemType Directory -Force -Path $ssh
  $config = Join-Path $ssh 'config'; Set-Content -LiteralPath $config -Value "Host unrelated`n  User elsewhere" -Encoding ascii
  $fixtureProfile = [pscustomobject]@{ Login='g6_castilla'; KeyName='g6_castilla_dist'; Port=5673; Vhost='g6-productos-ofertas'; Services=@('g6_masivos') }
  $fixtureFiles = [Collections.Generic.Dictionary[string,byte[]]]::new([StringComparer]::Ordinal)
  $fixtureFiles['ssh/g6_castilla_dist'] = [byte[]]@(1,2,3)
  $fixtureFiles['scripts/Start-G6RabbitMqTunnel.ps1'] = [byte[]]@(4,5,6)
  $fixtureCredentials = @([pscustomobject]@{ username='g6_masivos'; vhost='g6-productos-ofertas'; password='SYNTHETIC-NOT-A-SECRET' })
  $plan = Get-G6PackageInstallFilePlan -Files $fixtureFiles -Credentials $fixtureCredentials -Profile $fixtureProfile -UserProfile $fixtureUser -LocalAppData $fixtureLocal
  Assert-G6PackageInstallFilePlanAvailable -Destinations $plan
  if ((Get-Content -Raw -LiteralPath $config) -notmatch 'Host unrelated') { throw 'Unrelated SSH configuration changed during fixture planning.' }
  $collisionTarget = $plan | Where-Object { $_ -like '*g6_castilla_dist' } | Select-Object -First 1
  $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $collisionTarget)
  [IO.File]::WriteAllBytes($collisionTarget,[byte[]]@(7))
  $collisionRejected = $false
  try { Assert-G6PackageInstallFilePlanAvailable -Destinations $plan } catch { $collisionRejected = $_.Exception.Message -match 'refusing to overwrite' }
  if (-not $collisionRejected) { throw 'Installer plan failed to reject an existing private key destination.' }
  $createNewRejected = $false
  try { Write-G6NewFile -Path $collisionTarget -Content ([byte[]]@(9,9,9)) } catch { $createNewRejected = $true }
  if (-not $createNewRejected -or [IO.File]::ReadAllBytes($collisionTarget)[0] -ne 7) { throw 'Installer write helper overwrote an existing synthetic private key.' }
  if ($installerScript -notmatch 'Assert-G6PackageInstallFilePlanAvailable' -or $installerScript -notmatch 'AppendAllText\(\$configPath') { throw 'Installer must preflight collisions and append only its SSH alias.' }

  $gitRoot = Join-Path $tempRoot 'git-fixture'; $null = New-Item -ItemType Directory -Path $gitRoot
  & git.exe -C $gitRoot init --quiet
  if ($LASTEXITCODE -ne 0) { throw 'Could not initialize temporary Git fixture.' }
  Set-Content -LiteralPath (Join-Path $gitRoot '.gitignore') -Value '.env' -Encoding ascii
  $gitHelper = Join-Path $gitRoot 'G6DeveloperProfile.ps1'; Copy-Item -LiteralPath $profileHelper -Destination $gitHelper
  . $gitHelper
  if (-not (Test-G6DeveloperEnvIgnored -Path (Join-Path $gitRoot '.env'))) { throw 'Ignored .env fixture was not accepted.' }
  if (Test-G6DeveloperEnvIgnored -Path (Join-Path $gitRoot '.env.local')) { throw 'Unignored environment file fixture was accepted.' }
  Set-Content -LiteralPath (Join-Path $gitRoot '.env') -Value 'RABBITMQ_URL=amqp://synthetic' -Encoding ascii
  & git.exe -C $gitRoot add -f -- .env
  if ($LASTEXITCODE -ne 0) { throw 'Could not stage tracked .env fixture.' }
  if (Test-G6DeveloperEnvIgnored -Path (Join-Path $gitRoot '.env')) { throw 'Tracked .env fixture was accepted.' }
  Write-Output 'PASS fixtures: installer collision guard, unrelated SSH config preservation, and Git ignore checks.'
} finally {
  $tempBase = [IO.Path]::GetFullPath($env:TEMP).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
  $resolved = [IO.Path]::GetFullPath($tempRoot)
  if (-not $resolved.StartsWith($tempBase,[StringComparison]::OrdinalIgnoreCase)) { throw 'Refusing to remove fixture data outside Windows TEMP.' }
  if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
