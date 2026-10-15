param([int]$LocalPort = 5673)
$ErrorActionPreference = 'Stop'
$listener = Get-NetTCPConnection -State Listen -LocalPort $LocalPort -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $listener) { throw "No SSH tunnel is listening on 127.0.0.1:$LocalPort." }
$tcp = [System.Net.Sockets.TcpClient]::new()
try {
  $connect = $tcp.ConnectAsync('127.0.0.1', $LocalPort)
  if (-not $connect.Wait(5000)) { throw "TCP connection to 127.0.0.1:$LocalPort timed out." }
  $null = $connect.GetAwaiter().GetResult()
  Write-Output "PASS: TCP connection opened to 127.0.0.1:$LocalPort (SSH tunnel listener PID $($listener.OwningProcess))."
} finally { $tcp.Dispose() }
