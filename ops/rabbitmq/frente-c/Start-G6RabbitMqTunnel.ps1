param(
  [string]$Alias = 'g6-dev',
  [int]$LocalPort = 5673,
  [int]$ReconnectDelaySeconds = 5,
  [string]$ExpectedIdentityFile = 'g6_piloto',
  [string]$SshConfigPath = (Join-Path $env:USERPROFILE '.ssh\config')
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $SshConfigPath)) { throw "SSH config not found: $SshConfigPath" }
$sshConfig = & ssh -F $SshConfigPath -G $Alias 2>$null
if ($LASTEXITCODE -ne 0) { throw "Could not resolve SSH alias '$Alias'." }
$sshHost = ($sshConfig | Where-Object { $_ -match '^hostname ' } | Select-Object -First 1) -replace '^hostname\s+', ''
$sshUser = ($sshConfig | Where-Object { $_ -match '^user ' } | Select-Object -First 1) -replace '^user\s+', ''
$identitiesOnly = ($sshConfig | Where-Object { $_ -match '^identitiesonly ' } | Select-Object -First 1) -replace '^identitiesonly\s+', ''
if ($sshHost -ne '157.137.205.218' -or $sshUser -notmatch '^g6_[a-z0-9][a-z0-9_-]{1,30}$' -or $identitiesOnly -ne 'yes') {
  throw "SSH alias '$Alias' must resolve to the Oracle host, an individual g6_* account, and IdentitiesOnly yes; refusing to try another identity."
}
$identityFiles = @($sshConfig | Where-Object { $_ -match '^identityfile ' } | ForEach-Object { ($_ -replace '^identityfile\s+', '').Trim('"') })
if (-not ($identityFiles | Where-Object { [IO.Path]::GetFileNameWithoutExtension($_) -eq $ExpectedIdentityFile })) {
  throw "SSH alias '$Alias' does not select the expected dedicated identity '$ExpectedIdentityFile'."
}

while ($true) {
  $listener = Get-NetTCPConnection -State Listen -LocalPort $LocalPort -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($listener) {
    $owner = Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue
    throw "Local port $LocalPort is already listening (PID $($listener.OwningProcess), process $($owner.ProcessName)). Stop that process or choose another port."
  }

  Write-Host "Opening SSH tunnel on 127.0.0.1:$LocalPort. Press Ctrl+C to stop."
  & ssh -F $SshConfigPath -N -T -o IdentitiesOnly=yes -o ForwardAgent=no -o RequestTTY=no `
    -o ExitOnForwardFailure=yes -o ServerAliveInterval=15 -o ServerAliveCountMax=3 `
    -L "127.0.0.1:${LocalPort}:127.0.0.1:5672" $Alias
  $exitCode = $LASTEXITCODE

  if ($exitCode -eq 0) {
    Write-Host 'SSH tunnel ended cleanly.'
    break
  }

  Write-Warning "SSH tunnel ended with code $exitCode; keepalive detected a lost connection. Retrying in $ReconnectDelaySeconds seconds."
  Start-Sleep -Seconds $ReconnectDelaySeconds
}
