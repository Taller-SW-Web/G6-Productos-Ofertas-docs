<#
.SYNOPSIS
  Runner automatizado y seguro de Postman/Newman para G6 - Hito 5.

.DESCRIPTION
  Ejecuta preflight, inyecta credenciales desde variables de entorno (nunca por argumentos visibles),
  corre Newman local, genera evidencia saneada con hashes SHA-256 y preserva el codigo de salida.

.EXAMPLE
  .\scripts\run-newman.ps1 -Profile smoke -Env azure-aca-chile

.EXAMPLE
  .\scripts\run-newman.ps1 -Profile integration -Env local -BaseUrl http://127.0.0.1:3000 -AllowNoAuth
#>
[CmdletBinding()]
param(
  [ValidateSet('smoke', 'integration')]
  [string]$Profile = 'smoke',

  [ValidateSet('azure-aca-chile', 'local')]
  [string]$Env = 'azure-aca-chile',

  [string]$BaseUrl = '',
  [string]$Folder = '',
  [string]$RunId = '',
  [string]$OutDir = '',
  [string]$Channel = 'MARKETPLACE',
  [int]$TimeoutMs = 20000,
  [switch]$AllowNoAuth,
  [switch]$PromptToken
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$postmanRoot = Split-Path -Parent $scriptDir

if ($PromptToken -and [string]::IsNullOrWhiteSpace($env:G6_ACCESS_TOKEN)) {
  $secure = Read-Host -AsSecureString 'Ingrese JWT G7 (G6_ACCESS_TOKEN) [entrada oculta]'
  $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    $env:G6_ACCESS_TOKEN = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
  } finally {
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  }
}

$nodeArgs = @(
  (Join-Path $scriptDir 'run-newman.mjs'),
  '--profile', $Profile,
  '--env', $Env,
  '--channel', $Channel,
  '--timeout', "$TimeoutMs"
)

if (-not [string]::IsNullOrWhiteSpace($BaseUrl)) {
  $nodeArgs += @('--base-url', $BaseUrl)
}
if (-not [string]::IsNullOrWhiteSpace($Folder)) {
  $nodeArgs += @('--folder', $Folder)
}
if (-not [string]::IsNullOrWhiteSpace($RunId)) {
  $nodeArgs += @('--run-id', $RunId)
}
if (-not [string]::IsNullOrWhiteSpace($OutDir)) {
  $nodeArgs += @('--out-dir', $OutDir)
}
if ($AllowNoAuth) {
  $nodeArgs += @('--allow-no-auth', 'true')
}

Push-Location $postmanRoot
try {
  & node @nodeArgs
  $code = $LASTEXITCODE
} finally {
  Pop-Location
}

exit $code
