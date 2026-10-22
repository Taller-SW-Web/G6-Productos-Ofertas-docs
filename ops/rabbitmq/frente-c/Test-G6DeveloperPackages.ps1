#requires -Version 7.0
param([string]$KitRoot = $PSScriptRoot)
$ErrorActionPreference = 'Stop'

# These package checks use only synthetic package data. They never open the
# administrative DPAPI vault or decrypt a previously generated real package.
foreach ($fixture in @('Test-G6OnboardingFixtures.ps1','Test-G6PackageInstallFixtures.ps1','Test-G6PackageGenerationFixtures.ps1')) {
  $fixturePath = Join-Path $KitRoot $fixture
  if (-not (Test-Path -LiteralPath $fixturePath -PathType Leaf)) { throw "Synthetic package fixture is missing: $fixture." }
  & $fixturePath -KitRoot $KitRoot
}

Write-Output 'PASS: G6 package compatibility checks completed with synthetic fixtures only; no real package or credential vault was opened.'
