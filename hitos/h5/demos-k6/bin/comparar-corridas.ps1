[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$Baseline,
    [Parameter(Mandatory)][string[]]$Candidato,
    [Parameter(Mandatory)][string]$Telemetria,
    [ValidateRange(1, 300)][int]$PausaMinimaSegundos = 5
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'preflight.ps1')

function Compare-K6Median {
    param([double[]]$Values)
    return ($Values | Sort-Object)[1]
}

function Read-K6Comparable {
    param([string]$Path, [string]$Subject)
    $resolved = Get-K6DemoFile $Path 'RESUMEN_AUSENTE'
    $artifactHash = (Get-FileHash -LiteralPath $resolved).Hash.ToLowerInvariant()
    $checksumFile = Get-K6DemoFile (Join-Path (Split-Path -Parent $resolved) 'summary.sha256') 'HASH_RESUMEN_AUSENTE'
    if ((Get-Content -Raw -LiteralPath $checksumFile).Trim() -cne "$artifactHash  summary.json") {
        throw 'HASH_RESUMEN_DISTINTO'
    }
    $run = Read-K6DemoJson $resolved 'RESUMEN_INVALIDO'
    if ($run.schema_version -ne 1 -or $run.subject -cne $Subject -or $run.scope -cne 'L2_STAGING_APIM' -or
        $run.environment -cne 'STAGING_APIM' -or $run.harness_dirty -or $run.repetition -notin @(1, 2, 3) -or
        -not ($script:K6DemoCases.ContainsKey($run.case_id) -and $script:K6DemoProfiles.ContainsKey($run.profile)) -or
        $run.status -notin @('PASS', 'FAIL') -or $run.subject_digest -cnotmatch '^sha256:[a-f0-9]{64}$' -or
        $run.comparison_context_sha256 -cnotmatch '^[a-f0-9]{64}$' -or $run.release_manifest_sha256 -cnotmatch '^[a-f0-9]{64}$' -or
        $run.dataset_sha256 -cnotmatch '^[a-f0-9]{64}$' -or $run.harness_commit -cnotmatch '^[a-f0-9]{40}$') {
        throw 'SUJETO_O_PROCEDENCIA_NO_COMPARABLE'
    }
    $profile = $script:K6DemoProfiles[$run.profile]
    $harnessHashes = $run.harness_files_sha256.PSObject.Properties
    if (@($harnessHashes).Count -ne 6 -or
        @($harnessHashes | Where-Object Value -CNotMatch '^[a-f0-9]{64}$').Count -ne 0) {
        throw 'HASHES_DE_ARNES_INVALIDOS'
    }
    $m = $run.metrics
    if (-not $m -or $m.observed_max_vus -ne $profile.Vus -or $m.configured_seconds -ne $profile.Seconds -or
        $m.elapsed_seconds -lt ($profile.Seconds - 1) -or $m.iterations -lt 1 -or
        $m.valid_2xx -lt 1 -or $null -eq $m.p50_ms -or $null -eq $m.p95_ms -or $null -eq $m.p99_ms -or
        $m.p50_ms -lt 0 -or $m.p95_ms -lt $m.p50_ms -or $m.p99_ms -lt $m.p95_ms -or
        $m.rps_valid_2xx -le 0 -or $m.negative_401 -ne 0 -or
        $null -eq $m.critical_checks -or $null -eq $m.unexpected_error_rate) {
        throw 'METRICAS_INCOMPLETAS'
    }
    $telemetryPath = Get-K6DemoFile (Join-Path $Telemetria "$artifactHash.json") 'TELEMETRIA_AUSENTE'
    $observations = Read-K6DemoJson $telemetryPath 'TELEMETRIA_INVALIDA'
    if ($observations.summary_sha256 -cne $artifactHash -or
        $observations.telemetry_sha256 -cnotmatch '^[a-f0-9]{64}$' -or
        $observations.warmup_seconds -le 0 -or
        $null -eq $observations.cpu_peak_pct -or $observations.cpu_peak_pct -lt 0 -or
        $null -eq $observations.memory_peak_mb -or $observations.memory_peak_mb -lt 0 -or
        $null -eq $observations.db_connections_peak -or $observations.db_connections_peak -lt 0) {
        throw 'TELEMETRIA_INCOMPLETA'
    }
    return @{
        Run = $run; Hash = $artifactHash; Telemetry = $observations.telemetry_sha256
        Harness = (@($harnessHashes | Sort-Object Name | ForEach-Object { $_.Name + ':' + $_.Value }) -join ';')
    }
}

try {
    if ($Baseline.Count -ne 3 -or $Candidato.Count -ne 3) { throw 'SE_REQUIEREN_TRES_CORRIDAS_POR_SUJETO' }
    $baseRuns = @($Baseline | ForEach-Object { Read-K6Comparable $_ 'baseline' })
    $candidateRuns = @($Candidato | ForEach-Object { Read-K6Comparable $_ 'candidato' })
    $all = $baseRuns + $candidateRuns
    if (@($all.Hash | Sort-Object -Unique).Count -ne 6 -or
        @($baseRuns.Run.repetition | Sort-Object -Unique).Count -ne 3 -or
        @($candidateRuns.Run.repetition | Sort-Object -Unique).Count -ne 3) { throw 'REPETICIONES_DUPLICADAS' }
    if (@($all.Harness | Sort-Object -Unique).Count -ne 1) { throw 'ARCHIVOS_DE_ARNES_DISTINTOS' }
    $first = $baseRuns[0].Run
    $second = $candidateRuns[0].Run
    if ($first.revision -ceq $second.revision -or $first.subject_digest -ceq $second.subject_digest) {
        throw 'BASELINE_Y_CANDIDATO_DEBEN_SER_DISTINTOS'
    }
    foreach ($field in @('case_id', 'profile', 'operation_id', 'channel', 'max_rps', 'k6_version',
        'docs_sha', 'harness_commit', 'dataset_sha256', 'comparison_context_sha256')) {
        if (@($all.Run.$field | Sort-Object -Unique).Count -ne 1) { throw 'CONFIGURACIONES_NO_COMPARABLES' }
    }
    foreach ($group in @(@{ Rows = $baseRuns }, @{ Rows = $candidateRuns })) {
        foreach ($field in @('revision', 'subject_digest', 'backend_sha', 'frontend_sha', 'release_manifest_sha256')) {
            if (@($group.Rows.Run.$field | Sort-Object -Unique).Count -ne 1) { throw 'SUJETO_CAMBIO_ENTRE_REPETICIONES' }
        }
    }
    $orderedRuns = @($all.Run | Sort-Object timestamp_utc)
    for ($index = 1; $index -lt $orderedRuns.Count; $index++) {
        $previous = $orderedRuns[$index - 1]
        $next = $orderedRuns[$index]
        $ended = ([DateTimeOffset]$previous.timestamp_utc).AddSeconds($previous.metrics.elapsed_seconds + $PausaMinimaSegundos)
        if ([DateTimeOffset]$next.timestamp_utc -lt $ended) { throw 'SOLAPAMIENTO_O_PAUSA_INSUFICIENTE' }
    }

    $functionalFailure = @($all | Where-Object {
        $_.Run.status -ne 'PASS' -or $_.Run.k6_exit_code -ne 0 -or
        $_.Run.metrics.critical_checks -ne 1 -or $_.Run.metrics.unexpected_error_rate -ge 0.01
    }).Count -gt 0
    $baseP95 = Compare-K6Median $baseRuns.Run.metrics.p95_ms
    $candidateP95 = Compare-K6Median $candidateRuns.Run.metrics.p95_ms
    $baseRps = Compare-K6Median $baseRuns.Run.metrics.rps_valid_2xx
    $candidateRps = Compare-K6Median $candidateRuns.Run.metrics.rps_valid_2xx
    $passes = -not $functionalFailure -and $candidateP95 -le 1.10 * $baseP95 -and $candidateRps -ge 0.90 * $baseRps
    [ordered]@{
        case_id = $first.case_id; profile = $first.profile; veredicto = if ($passes) { 'PASS' } else { 'FAIL' }
        baseline_p95_ms = $baseP95; candidato_p95_ms = $candidateP95
        baseline_rps = $baseRps; candidato_rps = $candidateRps; gate_funcional = -not $functionalFailure
        p95_corridas = $all.Run.metrics.p95_ms; rps_corridas = $all.Run.metrics.rps_valid_2xx
        orden = $orderedRuns.subject; hashes = $all.Hash; telemetry_sha256 = $all.Telemetry
        h5_03 = 'REVISION_DE_OWNERS_PENDIENTE'
    } | ConvertTo-Json -Depth 4
    if ($passes) { exit 0 }
    exit 1
} catch {
    $reason = $_.Exception.Message
    if ($reason -cnotmatch '^[A-Z0-9_]+$') { $reason = 'EVIDENCIA_INCOMPLETA_O_INVALIDA' }
    @{ veredicto = 'INCONCLUSIVE'; bloqueo = $reason } | ConvertTo-Json
    exit 3
}
