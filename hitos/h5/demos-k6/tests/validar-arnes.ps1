[CmdletBinding()]
param([Parameter(Mandatory)][string]$K6Path)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $root 'bin/preflight.ps1')
$local = Join-Path $root ('.local/autoprueba-' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $local

function Save-AutopruebaJson {
    param([string]$Path, $Document)
    $Document | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 -LiteralPath $Path
    return (Get-FileHash -LiteralPath $Path).Hash.ToLowerInvariant()
}

$dataset = Join-Path $root 'config/dataset.example.json'
$datasetHash = (Get-FileHash -LiteralPath $dataset).Hash.ToLowerInvariant()
$config = Join-Path $local 'config-inerte.json'
$manifest = Join-Path $local 'manifest-inerte.json'
$comparisonContext = Join-Path $local 'contexto-inerte.json'
$manifestHash = Save-AutopruebaJson $manifest @{ autoprueba = $true }
$contextHash = Save-AutopruebaJson $comparisonContext @{ autoprueba = $true }
$sha = 'a' * 40
$metadata = @{
    environment = 'STAGING_APIM'; channel = 'MARKETPLACE'
    profiles = @('demo-smoke', 'demo-normal', 'formal-carga'); max_rps = 2
    window_start_utc = [DateTime]::UtcNow.AddMinutes(-1).ToString('yyyy-MM-ddTHH:mm:ssZ')
    window_end_utc = [DateTime]::UtcNow.AddMinutes(20).ToString('yyyy-MM-ddTHH:mm:ssZ')
    approval_ref = 'AUTOPRUEBA_SIN_TRAFICO'; revision = 'AUTOPRUEBA'; allow_negative_401 = $false
    backend_sha = $sha; frontend_sha = $sha; docs_sha = $sha
    subject_digest = 'sha256:' + ('a' * 64); dataset_sha256 = $datasetHash
    release_manifest_sha256 = $manifestHash; comparison_context_sha256 = $contextHash
}
foreach ($test in @(
    @{ Case = 'PERF-02'; Profile = 'demo-normal'; Subject = 'demo' },
    @{ Case = 'PERF-03'; Profile = 'formal-carga'; Subject = 'baseline' }
)) {
    $metadata.case_id = $test.Case
    $null = Save-AutopruebaJson $config $metadata
    $result = Invoke-K6DemoChild (Get-Command powershell.exe).Source @(
        '-NoProfile', '-File', (Join-Path $root 'bin/ejecutar-demo.ps1'), '-Config', $config, '-Dataset', $dataset,
        '-Manifest', $manifest, '-ComparisonContext', $comparisonContext, '-Profile', $test.Profile,
        '-Subject', $test.Subject, '-K6Path', $K6Path, '-SoloValidar'
    ) @{
        G6_K6_TARGET = 'https://example.invalid'
        G6_K6_APPROVED_ORIGIN = 'https://example.invalid'
        G6_K6_TEST_TOKEN = 'inert.fixture.input'
    }
    if ($result.Code -ne 0 -or $result.Output -notmatch 'NO_EJECUTADO') {
        throw "INSPECT_FALLO $($test.Case)"
    }
    Write-Output "INSPECT $($test.Case) / $($test.Profile) OK"
}

# Datos artificiales de autoprueba del comparador, nunca evidencia de H5.
$telemetryDir = Join-Path $local 'telemetria-inerte'
$null = New-Item -ItemType Directory -Path $telemetryDir
$baselinePaths = @()
$candidatePaths = @()
$syntheticTime = [DateTime]::UtcNow.AddHours(-1)
$harnessHashes = @{}
foreach ($index in 1..6) { $harnessHashes["archivo$index"] = 'd' * 64 }
foreach ($repetition in 1..3) {
    foreach ($subject in @('baseline', 'candidato')) {
        $isBaseline = $subject -eq 'baseline'
        $letter = if ($isBaseline) { 'b' } else { 'c' }
        $directory = New-Item -ItemType Directory -Path (Join-Path $local "$subject-$repetition")
        $path = Join-Path $directory.FullName 'summary.json'
        $summary = @{
            schema_version = 1; case_id = 'PERF-01'; operation_id = 'listarProductos'
            scope = 'L2_STAGING_APIM'; environment = 'STAGING_APIM'; profile = 'demo-smoke'
            subject = $subject; repetition = $repetition; status = 'PASS'; k6_exit_code = 0
            timestamp_utc = $syntheticTime.ToString('o')
            channel = 'MARKETPLACE'; max_rps = 5; k6_version = '2.4.0'
            docs_sha = $sha; harness_commit = $sha; harness_dirty = $false; harness_files_sha256 = $harnessHashes
            frontend_sha = $sha; backend_sha = $letter * 40; revision = "INERTE-$letter"
            subject_digest = 'sha256:' + ($letter * 64); release_manifest_sha256 = $letter * 64
            comparison_context_sha256 = $contextHash; dataset_sha256 = $datasetHash
            metrics = @{
                observed_max_vus = 1; configured_seconds = 60; elapsed_seconds = 62; iterations = 120; valid_2xx = 120
                p50_ms = 30; p95_ms = 50 + $repetition; p99_ms = 60; rps_valid_2xx = 2
                negative_401 = 0; critical_checks = 1; unexpected_error_rate = 0
            }
        }
        $checksum = Save-AutopruebaJson $path $summary
        "$checksum  summary.json" | Set-Content -Encoding ASCII -LiteralPath (Join-Path $directory.FullName 'summary.sha256')
        $null = Save-AutopruebaJson (Join-Path $telemetryDir "$checksum.json") @{
            summary_sha256 = $checksum; telemetry_sha256 = 'a' * 64; warmup_seconds = 10
            cpu_peak_pct = 22; memory_peak_mb = 70; db_connections_peak = 3
        }
        if ($isBaseline) { $baselinePaths += $path } else { $candidatePaths += $path }
        $syntheticTime = $syntheticTime.AddMinutes(2)
    }
}
$compare = Join-Path $root 'bin/comparar-corridas.ps1'
$pass = & $compare -Baseline $baselinePaths -Candidato $candidatePaths -Telemetria $telemetryDir | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $pass.veredicto -ne 'PASS' -or $pass.baseline_p95_ms -ne 52) {
    throw 'COMPARADOR_MEDIANA_FALLO'
}
$incomplete = & $compare -Baseline $baselinePaths -Candidato $candidatePaths -Telemetria $local | ConvertFrom-Json
if ($LASTEXITCODE -ne 3 -or $incomplete.veredicto -ne 'INCONCLUSIVE' -or $incomplete.bloqueo -ne 'TELEMETRIA_AUSENTE') {
    throw 'COMPARADOR_TELEMETRIA_FALLO'
}
Write-Output 'COMPARADOR_MEDIANA Y COMPARADOR_TELEMETRIA OK (datos artificiales)'
exit 0
