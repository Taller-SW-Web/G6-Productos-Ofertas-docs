param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('g6_catalogo','g6_inventario','g6_precios','g6_auditoria_precios','g6_promociones','g6_combos','g6_masivos','g6_taxonomia','g6_pasarela')]
  [string]$Identity,
  [string]$VaultPath = (Join-Path $env:LOCALAPPDATA 'G6\RabbitMQ\frontb-credentials.dpapi.json')
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $VaultPath)) { throw 'DPAPI credential vault not found for this Windows user.' }
$vault = Get-Content -Raw -LiteralPath $VaultPath | ConvertFrom-Json
$entry = $vault.credentials | Where-Object username -EQ $Identity | Select-Object -First 1
if (-not $entry) { throw "Identity '$Identity' is not present in the DPAPI vault." }
$secure = ConvertTo-SecureString -String $entry.protectedPassword
$plain = $null
try {
  $plain = [System.Net.NetworkCredential]::new('', $secure).Password
  Set-Clipboard -Value $plain
  Write-Output "Credential for $Identity copied to the local clipboard. Paste only into its approved local secret store, then clear the clipboard."
} finally {
  $secure.Dispose()
  $plain = $null
  $entry = $null
  $vault = $null
}
