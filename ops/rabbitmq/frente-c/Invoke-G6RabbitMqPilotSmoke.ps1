param(
  [string]$Identity = 'g6_masivos',
  [string]$VaultPath = (Join-Path $env:LOCALAPPDATA 'G6\RabbitMQ\frontb-credentials.dpapi.json'),
  [string]$AdminKeyPath = (Join-Path $env:USERPROFILE '.ssh\g6_oracle'),
  [int]$LocalPort = 5673
)
$ErrorActionPreference = 'Stop'
if ($Identity -ne 'g6_masivos') { throw 'This pilot verifier is scoped to the authorized Castilla identity g6_masivos.' }
if (-not (Test-Path -LiteralPath $VaultPath)) { throw 'DPAPI credential vault not found for this Windows user.' }
if (-not (Test-Path -LiteralPath $AdminKeyPath)) { throw 'Administrative SSH key not found.' }

$manifestPath = Join-Path $PSScriptRoot '..\rbac-rc3.json'
$manifestPath = [IO.Path]::GetFullPath($manifestPath)
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$account = $manifest.users | Where-Object username -EQ $Identity | Select-Object -First 1
if (-not $account -or -not $account.test_publish) { throw 'Pilot identity or approved test publication is missing from the rc.3 manifest.' }

$tcp = [System.Net.Sockets.TcpClient]::new()
try {
  $connect = $tcp.ConnectAsync('127.0.0.1', $LocalPort)
  if (-not $connect.Wait(5000)) { throw "TCP connection to 127.0.0.1:$LocalPort timed out; start the SSH tunnel first." }
  $null = $connect.GetAwaiter().GetResult()
} finally { $tcp.Dispose() }

function Get-QueueSnapshot {
  $cmd = "sudo -n docker exec g6-po-rabbitmq-1 rabbitmqctl list_queues --vhost g6-productos-ofertas --no-table-headers name messages consumers"
  $text = & ssh -i $AdminKeyPath -o IdentitiesOnly=yes -o BatchMode=yes ubuntu@157.137.205.218 $cmd
  if ($LASTEXITCODE -ne 0) { throw 'Could not read the RabbitMQ queue safety snapshot through the existing admin SSH path.' }
  $rows = @{}
  foreach ($line in $text) {
    if ($line -match '^(po\.[^\t]+)\t(\d+)\t(\d+)$') { $rows[$Matches[1]] = @{ Messages = [int]$Matches[2]; Consumers = [int]$Matches[3] } }
  }
  if (-not $rows.ContainsKey($account.queue) -or -not $rows.ContainsKey($account.test_publish.destinations[0])) {
    throw 'Could not verify both the pilot queue and the authorized synthetic-message destination.'
  }
  return $rows
}

$targetQueue = [string]$account.test_publish.destinations[0]
$before = Get-QueueSnapshot
foreach ($queue in @($account.queue, $targetQueue)) {
  if ($before[$queue].Messages -ne 0 -or $before[$queue].Consumers -ne 0) {
    throw "Safety stop: queue $queue is not empty or has consumers; no AMQP test message was sent."
  }
}

$tempRoot = Join-Path $env:TEMP ('g6-rabbitmq-pilot-' + [Guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $tempRoot
$plain = $null
$secure = $null
try {
  $package = Join-Path $tempRoot 'package.json'
  '{"private":true,"type":"module"}' | Set-Content -LiteralPath $package -Encoding ascii
  & npm.cmd install --prefix $tempRoot --no-audit --no-fund amqplib@2.2.0
  $npmExitCode = $LASTEXITCODE
  if ($npmExitCode -ne 0) { throw "Could not install the temporary AMQP verifier dependency (npm exit $npmExitCode)." }
  $verifier = Join-Path $tempRoot 'verify-pilot-amqp.mjs'
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'verify-pilot-amqp.mjs') -Destination $verifier
  $vault = Get-Content -Raw -LiteralPath $VaultPath | ConvertFrom-Json
  $entry = $vault.credentials | Where-Object username -EQ $Identity | Select-Object -First 1
  if (-not $entry) { throw "Identity '$Identity' is absent from the DPAPI vault." }
  $secure = ConvertTo-SecureString -String $entry.protectedPassword
  $plain = [System.Net.NetworkCredential]::new('', $secure).Password
  $escapedPassword = [uri]::EscapeDataString($plain)
  $env:RABBITMQ_URL = "amqp://${Identity}:$escapedPassword@127.0.0.1:${LocalPort}/g6-productos-ofertas"
  $env:G6_RABBITMQ_RBAC_FILE = $manifestPath
  & node $verifier $Identity
  if ($LASTEXITCODE -ne 0) { throw 'The Windows-to-RabbitMQ authenticated AMQP verifier failed.' }
  $plain = $null
  $escapedPassword = $null
  $secure.Dispose(); $secure = $null
  $entry = $null; $vault = $null
  Start-Sleep -Seconds 4
  $after = Get-QueueSnapshot
  foreach ($queue in @($account.queue, $targetQueue)) {
    if ($after[$queue].Messages -ne 0 -or $after[$queue].Consumers -ne 0) {
      throw "Post-test safety check found messages or consumers on $queue; no purge was attempted."
    }
  }
  Write-Output 'Queue safety snapshots: PASS (pilot and synthetic destination empty, no consumers before and after).'
} finally {
  $env:RABBITMQ_URL = $null
  $env:G6_RABBITMQ_RBAC_FILE = $null
  if ($secure) { $secure.Dispose() }
  $plain = $null
  $escapedPassword = $null
  $entry = $null; $vault = $null
  if (Test-Path -LiteralPath $tempRoot) {
    $tempBase = [IO.Path]::GetFullPath($env:TEMP).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    $resolvedTempRoot = [IO.Path]::GetFullPath($tempRoot)
    if (-not $resolvedTempRoot.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase)) {
      throw 'Refusing to remove a verifier temp path outside the Windows TEMP directory.'
    }
    Remove-Item -LiteralPath $resolvedTempRoot -Recurse -Force
  }
}
