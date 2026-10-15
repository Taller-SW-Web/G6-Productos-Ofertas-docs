param([string] $TestName)

$ErrorActionPreference = 'Stop'

$suiteDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$composeFile = Join-Path $suiteDir 'compose.yaml'
$project = 'g6rabbitiso' + [guid]::NewGuid().ToString('N').Substring(0, 12)

function Invoke-DockerCompose([string[]] $Arguments) {
    & docker compose --project-name $project --file $composeFile @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "docker compose failed with exit code $LASTEXITCODE"
    }
}

try {
    $dockerContext = (& docker context show).Trim()
    if ($LASTEXITCODE -ne 0 -or $dockerContext -ne 'desktop-linux') {
        throw "The active Docker context must be Docker Desktop's local 'desktop-linux'; current context is '$dockerContext'. No test resources were created."
    }
    $dockerEndpoint = (& docker context inspect desktop-linux --format '{{.Endpoints.docker.Host}}').Trim()
    if ($LASTEXITCODE -ne 0 -or $dockerEndpoint -notmatch '^npipe://') {
        throw "Docker Desktop's local Linux named-pipe endpoint was not verified ('$dockerEndpoint'). No test resources were created."
    }

    & docker info --format '{{.OSType}}'
    if ($LASTEXITCODE -ne 0) {
        throw 'The active Docker daemon is not available. Start Docker Desktop or select a working context, then rerun.'
    }
    $osType = (& docker info --format '{{.OSType}}').Trim()
    if ($LASTEXITCODE -ne 0 -or $osType -ne 'linux') {
        throw "A Linux container engine is required; current OSType is '$osType'."
    }

    Invoke-DockerCompose @('config', '--quiet')
    Invoke-DockerCompose @('pull', 'rabbitmq')
    if ($TestName) {
        Invoke-DockerCompose @('run', '--build', '--rm', '--entrypoint', 'python', 'contract-tests', '-m', 'unittest', '-v', "test_isolation.RabbitMQIsolation.$TestName")
    }
    else {
        Invoke-DockerCompose @('up', '--build', '--abort-on-container-exit', '--exit-code-from', 'contract-tests')
    }
}
finally {
    # Project name is unique to this run; cleanup is limited to its containers, network, and named volume.
    & docker compose --project-name $project --file $composeFile down --volumes --remove-orphans --rmi local
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Isolated Compose cleanup failed for project $project; inspect only resources prefixed with that project name."
    }
}
