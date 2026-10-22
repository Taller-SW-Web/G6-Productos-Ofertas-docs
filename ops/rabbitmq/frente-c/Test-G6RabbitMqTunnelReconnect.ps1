#requires -Version 7.0
param(
  [int]$LocalPort = 5673,
  [int]$ReconnectDelaySeconds = 3,
  [int]$TimeoutSeconds = 30
)
$ErrorActionPreference = 'Stop'
$existing = Get-NetTCPConnection -State Listen -LocalPort $LocalPort -ErrorAction SilentlyContinue | Select-Object -First 1
if ($existing) { throw "Local port $LocalPort is already occupied; refusing to affect that listener." }

$tempBase = [IO.Path]::GetFullPath($env:TEMP).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
$tempRoot = [IO.Path]::GetFullPath((Join-Path $env:TEMP ('g6-tunnel-reconnect-' + [Guid]::NewGuid().ToString('N'))))
if (-not $tempRoot.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe test log path.' }
$null = New-Item -ItemType Directory -Path $tempRoot
$stdout = Join-Path $tempRoot 'stdout.log'
$stderr = Join-Path $tempRoot 'stderr.log'
$runner = $null
try {
  $script = Join-Path $PSScriptRoot 'Start-G6RabbitMqTunnel.ps1'
  $argLine = '-NoLogo -NoProfile -File "' + $script + '" -LocalPort ' + $LocalPort + ' -ReconnectDelaySeconds ' + $ReconnectDelaySeconds
  $pwshPath = (Get-Command -Name pwsh.exe -ErrorAction Stop).Source
  $runner = Start-Process -FilePath $pwshPath -ArgumentList $argLine -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  $listener = $null
  while ((Get-Date) -lt $deadline -and -not $listener) {
    if ($runner.HasExited) { throw 'Tunnel auto-reconnect runner exited before opening its first connection.' }
    $listener = Get-NetTCPConnection -State Listen -LocalPort $LocalPort -ErrorAction SilentlyContinue | Select-Object -First 1
    Start-Sleep -Milliseconds 300
  }
  if (-not $listener) { throw 'Timed out waiting for the initial SSH tunnel.' }
  $oldPid = [int]$listener.OwningProcess
  $ssh = Get-Process -Id $oldPid -ErrorAction Stop
  if ($ssh.ProcessName -ne 'ssh') { throw "The tunnel listener is owned by unexpected process $($ssh.ProcessName)." }

  Stop-Process -Id $oldPid -Force
  $deadline = (Get-Date).AddSeconds(10)
  do {
    $listener = Get-NetTCPConnection -State Listen -LocalPort $LocalPort -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $listener) { break }
    Start-Sleep -Milliseconds 250
  } while ((Get-Date) -lt $deadline)
  if ($listener) { throw 'The tunnel listener did not close after terminating its SSH child.' }

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  $reconnected = $null
  while ((Get-Date) -lt $deadline -and -not $reconnected) {
    if ($runner.HasExited) { throw 'The tunnel auto-reconnect runner exited after its SSH connection was interrupted.' }
    $candidate = Get-NetTCPConnection -State Listen -LocalPort $LocalPort -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($candidate -and $candidate.OwningProcess -ne $oldPid) { $reconnected = $candidate; break }
    Start-Sleep -Milliseconds 300
  }
  if (-not $reconnected) { throw 'The tunnel did not reconnect before timeout.' }
  & (Join-Path $PSScriptRoot 'Test-G6RabbitMqTunnel.ps1') -LocalPort $LocalPort
  Write-Output "PASS: SSH tunnel reconnected after interruption (PID $oldPid -> $($reconnected.OwningProcess))."
} finally {
  if ($runner -and -not $runner.HasExited) { Stop-Process -Id $runner.Id -Force -ErrorAction SilentlyContinue }
  $listener = Get-NetTCPConnection -State Listen -LocalPort $LocalPort -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($listener) {
    $process = Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue
    if ($process -and $process.ProcessName -eq 'ssh') { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue }
  }
  if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}
