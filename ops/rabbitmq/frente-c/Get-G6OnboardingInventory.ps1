param([string]$VaultPath=(Join-Path $env:LOCALAPPDATA 'G6\RabbitMQ\onboarding\admin-vault.dpapi.json'))
$ErrorActionPreference='Stop'
$vault=Get-Content -Raw -LiteralPath $VaultPath | ConvertFrom-Json
$vault.developers | Select-Object Developer,Login,PackagePath,PackagePayloadPath,AccountCreated,PublicKeyRegistered,TunnelTestedFromAdminPc,PackageCreated,PackageDelivered,DeveloperPcConfirmed,PackageSHA256 | Format-Table -AutoSize
