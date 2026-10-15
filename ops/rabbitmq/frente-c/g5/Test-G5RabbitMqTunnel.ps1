param([int]$LocalPort=5673)
$ErrorActionPreference='Stop';if($LocalPort-ne 5673){throw 'G5 tunnel port is fixed to 5673.'}
$listener=Get-NetTCPConnection -State Listen -LocalPort $LocalPort -ErrorAction SilentlyContinue|Select-Object -First 1;if(-not$listener){throw 'No G5 SSH tunnel is listening on 127.0.0.1:5673.'}
$tcp=[Net.Sockets.TcpClient]::new();try{$task=$tcp.ConnectAsync('127.0.0.1',$LocalPort);if(-not$task.Wait(5000)){throw 'TCP connection to the local G5 tunnel timed out.'};$null=$task.GetAwaiter().GetResult();Write-Output "PASS: TCP to 127.0.0.1:5673 through SSH listener PID $($listener.OwningProcess)."}finally{$tcp.Dispose()}
