param(
  [Parameter(Mandatory=$true)][ValidateSet('g6_castilla','g6_poma','g6_taco','g6_vera','g6_cueva','g6_lopez')][string]$Login,
  [string]$VaultPath=(Join-Path $env:LOCALAPPDATA 'G6\RabbitMQ\onboarding\admin-vault.dpapi.json')
)
$ErrorActionPreference='Stop'
if (-not (Test-Path -LiteralPath $VaultPath)) { throw 'Protected onboarding vault not found for this Windows user.' }
$vault=Get-Content -Raw -LiteralPath $VaultPath | ConvertFrom-Json
$entry=$vault.developers | Where-Object Login -EQ $Login | Select-Object -First 1
if (-not $entry -or -not $entry.ProtectedPackagePassword) { throw "No package password is stored for $Login." }
$secure=ConvertTo-SecureString -String $entry.ProtectedPackagePassword
$plain=$null
try {
  $plain=[Net.NetworkCredential]::new('', $secure).Password
  Set-Clipboard -Value $plain
  Write-Output "Package password for $Login copied to the local clipboard. Paste only into its approved separate channel, then clear the clipboard."
} finally { $secure.Dispose(); $plain=$null; $entry=$null; $vault=$null }
