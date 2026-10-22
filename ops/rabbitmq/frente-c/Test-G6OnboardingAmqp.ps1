#requires -Version 7.0
param(
  [string]$Root = (Join-Path $env:LOCALAPPDATA 'G6\RabbitMQ\onboarding'),
  [string]$CredentialVaultPath = (Join-Path $env:LOCALAPPDATA 'G6\RabbitMQ\frontb-credentials.dpapi.json')
)
$ErrorActionPreference='Stop'
$manifestPath=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\rbac-rc3.json'))
$manifest=Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$keyVault=Get-Content -Raw -LiteralPath (Join-Path $Root 'admin-vault.dpapi.json') | ConvertFrom-Json
$credVault=Get-Content -Raw -LiteralPath $CredentialVaultPath | ConvertFrom-Json
$sshConfig=Join-Path $Root 'admin-test-ssh-config'
$adminKey=Join-Path $env:USERPROFILE '.ssh\g6_oracle'
$runtime=Join-Path $env:TEMP ('g6-amqp-onboarding-' + [Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $runtime
$pkg='{"private":true,"type":"module"}'
$pkg | Set-Content -LiteralPath (Join-Path $runtime 'package.json') -Encoding ascii
try {
  & npm.cmd install --prefix $runtime --no-audit --no-fund amqplib@2.2.0
  if ($LASTEXITCODE -ne 0) { throw 'Could not install the temporary AMQP test dependency.' }
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'verify-pilot-amqp.mjs') -Destination (Join-Path $runtime 'verify.mjs')
  $results=[Collections.Generic.List[object]]::new()
  foreach ($d in $keyVault.developers) {
    foreach ($identity in $d.Services) {
      $account=$manifest.users | Where-Object username -EQ $identity | Select-Object -First 1
      if (-not $account) { throw "Manifest missing assigned identity $identity." }
      $port=[int]$d.Port
      $tunnelInfo=[Diagnostics.ProcessStartInfo]::new(); $tunnelInfo.FileName=(Get-Command ssh.exe).Source
      foreach ($a in @('-F',$sshConfig,'-N','-T','-o','BatchMode=yes','-o','ExitOnForwardFailure=yes','-o','ConnectTimeout=8','-L',"127.0.0.1:${port}:127.0.0.1:5672",$d.Login)) { [void]$tunnelInfo.ArgumentList.Add($a) }
      $tunnelInfo.UseShellExecute=$false; $tunnelInfo.RedirectStandardOutput=$true; $tunnelInfo.RedirectStandardError=$true
      $tunnel=[Diagnostics.Process]::new(); $tunnel.StartInfo=$tunnelInfo; [void]$tunnel.Start(); $tout=$tunnel.StandardOutput.ReadToEndAsync(); $terr=$tunnel.StandardError.ReadToEndAsync()
      $tunnelReady=$false
      for ($n=0; $n -lt 40; $n++) {
        if ($tunnel.HasExited) { break }
        $tcp=[Net.Sockets.TcpClient]::new()
        try { $task=$tcp.ConnectAsync('127.0.0.1',$port); if ($task.Wait(250) -and $tcp.Connected) { $tunnelReady=$true; break } } catch {} finally { $tcp.Dispose() }
        Start-Sleep -Milliseconds 250
      }
      if (-not $tunnelReady) { $err=$terr.GetAwaiter().GetResult(); if (-not $tunnel.HasExited) { $tunnel.Kill(); $tunnel.WaitForExit() }; throw "Tunnel failed for $($d.Login); details redacted: $err" }
      try {
        $beforeCmd='sudo -n docker exec g6-po-rabbitmq-1 rabbitmqctl list_queues --vhost g6-productos-ofertas --no-table-headers name messages consumers'
        $snapshotText=& ssh -i $adminKey -o IdentitiesOnly=yes -o BatchMode=yes ubuntu@157.137.205.218 $beforeCmd
        if ($LASTEXITCODE -ne 0) { throw 'Admin queue-safety snapshot failed.' }
        $snap=@{}
        foreach ($line in $snapshotText) { if ($line -match '^(po\.[^\t]+)\t(\d+)\t(\d+)$') { $snap[$Matches[1]]=@{Messages=[int]$Matches[2];Consumers=[int]$Matches[3]} } }
        if (-not $snap.ContainsKey($account.queue)) { throw "Safety snapshot missing own queue for $identity." }
        $snapshotQueues=@($account.queue)
        if ($account.test_publish) { $snapshotQueues += @($account.test_publish.destinations) }
        foreach ($queue in ($snapshotQueues | Select-Object -Unique)) {
          if (-not $snap.ContainsKey($queue)) { throw "Safety snapshot missing queue $queue." }
          if ($snap[$queue].Messages -ne 0 -or $snap[$queue].Consumers -ne 0) { throw "Safety stop for ${identity}: $queue has messages or consumers; no test publish attempted." }
        }
        $entry=$credVault.credentials | Where-Object username -EQ $identity | Select-Object -First 1
        if (-not $entry) { throw "DPAPI vault missing assigned identity $identity." }
        $secure=ConvertTo-SecureString -String $entry.protectedPassword
        $plain=[Net.NetworkCredential]::new('', $secure).Password
        $escaped=[uri]::EscapeDataString($plain)
        $env:RABBITMQ_URL="amqp://${identity}:$escaped@127.0.0.1:${port}/g6-productos-ofertas"
        $env:G6_AMQP_PORT=[string]$port
        $env:G6_RABBITMQ_RBAC_FILE=$manifestPath
        & node (Join-Path $runtime 'verify.mjs') $identity
        if ($LASTEXITCODE -ne 0) { throw "AMQP identity verification failed for $identity; no secret was logged." }
        $plain=$null; $escaped=$null; $secure.Dispose(); $secure=$null; $entry=$null
        if ($account.test_publish) {
          Start-Sleep -Seconds 4
          $afterText=& ssh -i $adminKey -o IdentitiesOnly=yes -o BatchMode=yes ubuntu@157.137.205.218 $beforeCmd
          if ($LASTEXITCODE -ne 0) { throw 'Post-test queue-safety snapshot failed.' }
          $after=@{}
          foreach ($line in $afterText) { if ($line -match '^(po\.[^\t]+)\t(\d+)\t(\d+)$') { $after[$Matches[1]]=@{Messages=[int]$Matches[2];Consumers=[int]$Matches[3]} } }
          foreach ($queue in ($snapshotQueues | Select-Object -Unique)) { if ($after[$queue].Messages -ne 0 -or $after[$queue].Consumers -ne 0) { throw "Post-test safety found messages/consumers on $queue; no purge was attempted." } }
        }
        $authPub=if($account.test_publish){'PASS'}else{'NO_APLICA'}
        $confirm=if($account.test_publish){'PASS'}else{'NO_APLICA'}
        $results.Add([pscustomobject]@{ Developer=$d.Developer; SSHLogin=$d.Login; RabbitIdentity=$identity; Authentication='PASS'; OwnQueueRead='PASS'; CrossReadDenied='PASS'; ConfigureDenied='PASS'; UnauthorizedPublishDenied='PASS'; AuthorizedPublish=$authPub; PublisherConfirm=$confirm; QueueSafety='PASS'; LocalPort=$port })
      } finally {
        $env:RABBITMQ_URL=$null; $env:G6_AMQP_PORT=$null; $env:G6_RABBITMQ_RBAC_FILE=$null
        $plain=$null; $escaped=$null; if ($secure) { $secure.Dispose() }; $entry=$null
        if (-not $tunnel.HasExited) { $tunnel.Kill(); $tunnel.WaitForExit() }
      }
    }
  }
  $results | Format-Table -AutoSize
} finally {
  $env:RABBITMQ_URL=$null; $env:G6_AMQP_PORT=$null; $env:G6_RABBITMQ_RBAC_FILE=$null
  $tempBase=[IO.Path]::GetFullPath($env:TEMP).TrimEnd([IO.Path]::DirectorySeparatorChar)+[IO.Path]::DirectorySeparatorChar
  $resolved=[IO.Path]::GetFullPath($runtime)
  if (-not $resolved.StartsWith($tempBase,[StringComparison]::OrdinalIgnoreCase)) { throw 'Refusing to remove a temp path outside Windows TEMP.' }
  Remove-Item -LiteralPath $resolved -Recurse -Force
}
