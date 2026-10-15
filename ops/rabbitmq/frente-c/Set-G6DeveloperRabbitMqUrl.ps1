#requires -Version 7.0
param(
  [Parameter(Mandatory=$true)][string]$Identity,
  [Parameter(Mandatory=$true)][string]$Path
)
$ErrorActionPreference='Stop'
$meta=Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'developer.json') | ConvertFrom-Json
if ($Identity -notin $meta.Services) { throw "Identity $Identity is not assigned in this package." }
$fullPath=[IO.Path]::GetFullPath($Path)
if ([IO.Directory]::Exists($fullPath)) { throw 'The destination must be a file path.' }
$directory=Split-Path -Parent $fullPath
if (-not (Test-Path -LiteralPath $directory)) { $null=New-Item -ItemType Directory -Path $directory }
$gitRoot=& git.exe -C $directory rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -eq 0) {
  $relative=[IO.Path]::GetRelativePath($gitRoot,$fullPath).Replace('\','/')
  & git.exe -C $gitRoot ls-files --error-unmatch -- $relative *> $null
  if ($LASTEXITCODE -eq 0) { throw 'Refusing to write a RabbitMQ secret to a tracked file.' }
  & git.exe -C $gitRoot check-ignore --quiet -- $relative
  if ($LASTEXITCODE -ne 0) { throw 'Refusing to write a secret in a Git worktree unless the destination is ignored (for example, .env).' }
}
$secretPath=Join-Path (Join-Path $PSScriptRoot 'secrets') "$Identity.clixml"
if (-not (Test-Path -LiteralPath $secretPath)) { throw "DPAPI credential not installed for $Identity." }
$secure=Import-Clixml -LiteralPath $secretPath
$password=$null; $encoded=$null; $tempPath=Join-Path $directory ('.g6-amqp-'+[Guid]::NewGuid().ToString('N')+'.tmp')
try {
  $password=[Net.NetworkCredential]::new('', $secure).Password
  $encoded=[Uri]::EscapeDataString($password)
  $url="amqp://${Identity}:$encoded@127.0.0.1:$($meta.Port)/$([Uri]::EscapeDataString($meta.Vhost))"
  $existing=if (Test-Path -LiteralPath $fullPath) { [IO.File]::ReadAllText($fullPath) } else { '' }
  $newline=if ($existing.Contains("`r`n")) { "`r`n" } else { [Environment]::NewLine }
  $lines=[Collections.Generic.List[string]]::new()
  if ($existing.Length -gt 0) { foreach($line in [regex]::Split($existing,'\r?\n')) { if ($line -notmatch '^\s*RABBITMQ_URL\s*=') { $lines.Add($line) } } }
  $lines.Add("RABBITMQ_URL=$url")
  $content=($lines -join $newline)+$newline
  [IO.File]::WriteAllText($tempPath,$content,[Text.UTF8Encoding]::new($false))
  $current=[Security.Principal.WindowsIdentity]::GetCurrent().Name
  icacls $tempPath /inheritance:r /grant:r "$current`:(F)" 'NT AUTHORITY\SYSTEM:(F)' | Out-Null
  Move-Item -LiteralPath $tempPath -Destination $fullPath -Force
  icacls $fullPath /inheritance:r /grant:r "$current`:(F)" 'NT AUTHORITY\SYSTEM:(F)' | Out-Null
  Write-Output "RABBITMQ_URL configurada para $Identity en $fullPath. El valor quedó oculto; confirma que este archivo está ignorado por Git."
} finally {
  $password=$null; $encoded=$null; $url=$null; $content=$null; $existing=$null; $secure.Dispose()
  if (Test-Path -LiteralPath $tempPath) { Remove-Item -LiteralPath $tempPath -Force }
}
