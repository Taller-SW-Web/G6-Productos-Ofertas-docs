param(
  [Parameter(Mandatory=$true)][ValidateSet('g6_castilla','g6_poma','g6_taco','g6_vera','g6_cueva','g6_lopez')][string]$Login,
  [switch]$PackageDelivered,
  [switch]$DeveloperPcConfirmed,
  [string]$VaultPath=(Join-Path $env:LOCALAPPDATA 'G6\RabbitMQ\onboarding\admin-vault.dpapi.json')
)
$ErrorActionPreference='Stop'
if (-not $PackageDelivered -and -not $DeveloperPcConfirmed) { throw 'Specify -PackageDelivered or -DeveloperPcConfirmed after observing that real-world event.' }
$vault=Get-Content -Raw -LiteralPath $VaultPath | ConvertFrom-Json
$entry=$vault.developers | Where-Object Login -EQ $Login | Select-Object -First 1
if (-not $entry) { throw "No onboarding record for $Login." }
if ($PackageDelivered) { $entry.PackageDelivered=$true; $entry.PackageDeliveredUtc=[DateTime]::UtcNow.ToString('o') }
if ($DeveloperPcConfirmed) { $entry.DeveloperPcConfirmed=$true; $entry.DeveloperPcConfirmedUtc=[DateTime]::UtcNow.ToString('o') }
$vault | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $VaultPath -Encoding utf8
Write-Output "Updated delivery record for $Login."
