# Demo independiente de k6 — G6 Hito 5

Arnés de lectura HTTP para Catálogo, Pricing e Inventario. Las ejecuciones de la demo se registran por separado de la certificación [H5-03](../03_PRUEBAS_DE_PERFORMANCE.md). Consulta [la matriz de casos](MATRIZ_K6.md), [el guion de exposición](GUIA_EXPOSICION.md) y [el formato de evidencia](evidence/README.md).

## Demo local de Catálogo (1 VU, 60 s)

Desde este directorio, con PowerShell, Node.js, Git y [k6 para Windows](https://grafana.com/docs/k6/latest/set-up/install-k6/). Se probó con k6 2.4.0. El fixture ya existente en Backend sirve HTTP sintético por loopback. Se puede extraer la versión exacta de los archivos sin cambiar la rama de ese repositorio.

~~~powershell
$Backend = '<ruta-al-repositorio-backend>'
$BackendSha = git -C $Backend rev-parse origin/master
$FrontendSha = git -C '<ruta-al-repositorio-frontend>' rev-parse origin/master
$DocsSha = git rev-parse origin/master
$K6 = (Get-Command k6 -CommandType Application).Source

New-Item -ItemType Directory -Force -Path .local | Out-Null
$FixtureZip = Join-Path (Get-Location).Path ('.local/fixture-' + [guid]::NewGuid() + '.zip')
$FixtureDir = [IO.Path]::ChangeExtension($FixtureZip, $null)
git -C $Backend archive --format=zip -o $FixtureZip $BackendSha apps/catalog-svc/test/performance/h5/catalog-pagination.fixture-server.h5.mjs apps/catalog-svc/test/fixtures/h5/catalog-h5-fixture.mjs
if ($LASTEXITCODE -ne 0) { throw 'Fixture de Catálogo ausente en el SHA elegido' }
Expand-Archive -LiteralPath $FixtureZip -DestinationPath $FixtureDir
$Fixture = Join-Path $FixtureDir 'apps/catalog-svc/test/performance/h5/catalog-pagination.fixture-server.h5.mjs'

node bin/demo-local.mjs $Fixture $BackendSha $FrontendSha $DocsSha $K6 --validar
node bin/demo-local.mjs $Fixture $BackendSha $FrontendSha $DocsSha $K6 --dashboard
~~~

El primer comando comprueba el arnés sin emitir solicitudes de k6. El segundo utiliza el mismo wrapper de staging, lo prueba contra el fixture e incluye una única lectura sin credenciales que debe devolver 401. El dashboard se abre en **http://127.0.0.1:5665** durante la corrida. Cierra la pestaña al terminar para que la exportación HTML finalice. Si el binario es portátil, asigna su ruta absoluta a `$K6`.

## Staging autorizado (1 o 5 VU)

Solicita al owner del ambiente la publicación efectiva de la operación, identidad/grant de test, origen APIM permitido, ventana, tasa y perfil aprobados, dataset sintético estable, manifiesto de release y revisión exacta. Pasa el origen aprobado y el token por variables de ambiente del **proceso actual**, inyectadas desde un mecanismo seguro. Los nombres son `G6_K6_APPROVED_ORIGIN`, `G6_K6_TARGET` y `G6_K6_TEST_TOKEN`. El origen debe ser HTTPS con host exacto, sin path, query ni barra final. Nunca escribas el token en el terminal, configuraciones versionadas o argumentos.

Copia las plantillas de `config/` a `.local/` y completa los datos autorizados. El dataset de Catálogo declara los IDs por página en orden `NOMBRE_ASC`, con el filtro sintético opcional `catalog.filter` aplicado previamente. Los conjuntos de Pricing e Inventario corresponden al canal de configuración. Verifica SHA-256 de dataset, manifiesto y archivo de contexto con `Get-FileHash`. El manifiesto efectivo debe pertenecer a la revisión bajo prueba. El contexto común registra región, SKU/política APIM, topología, runtime, configuración de recursos, pool de BD y referencias de telemetría. Guarda sus valores de forma privada.

~~~powershell
$Common = @{
    Config = '.local/config.json'
    Dataset = '.local/dataset.json'
    Manifest = '.local/release.json'
    ComparisonContext = '.local/contexto.json'
}
.\bin\ejecutar-demo.ps1 @Common -Profile demo-smoke -SoloValidar
.\bin\ejecutar-demo.ps1 @Common -Profile demo-smoke -Dashboard
.\bin\ejecutar-demo.ps1 @Common -Profile demo-normal -Dashboard
~~~

`demo-normal` necesita autorización expresa para **5 VU durante 180 s** en `profiles`. La tasa ofrecida queda acotada por configuración y por el límite del perfil. `-SoloValidar` verifica ambiente, ventana, hash, herramienta, contrato de entrada y opciones aplicadas por `k6 inspect`. La corrida valida la ruta, el token y los datos sobre HTTP antes de medir. Las redirecciones están deshabilitadas. Durante la medición, un 401, 403 o 429 interrumpe la prueba; también hay corte por tasa de error sostenida y por vencimiento de ventana. `-Negative401` necesita autorización adicional y se ejecuta una sola vez en la preparación de una demo.

## Comparación formal

Se necesita un baseline y candidato distintos, del mismo entorno y con condiciones comparables. Acordar y registrar el calentamiento separado y las pausas. Ejecutar cada perfil aprobado en serie, tres repeticiones por sujeto, alternando cuando corresponda. Para un sujeto formal usar `-Subject baseline` o `-Subject candidato`, y `-Repetition 1`, `2` o `3` con su manifiesto específico. El perfil `formal-carga` es de **20 VU durante 300 s**, exige selección explícita y jamás se ejecuta en el fixture.

~~~powershell
$Base = @('<baseline-1>/summary.json', '<baseline-2>/summary.json', '<baseline-3>/summary.json')
$Candidate = @('<candidato-1>/summary.json', '<candidato-2>/summary.json', '<candidato-3>/summary.json')
.\bin\comparar-corridas.ps1 -Baseline $Base -Candidato $Candidate -Telemetria '.local/telemetria'
~~~

El comparador verifica procedencia, separación temporal, métricas, telemetría y los gates semántico, de errores, p95 y RPS. El veredicto se aplica al par de sujetos de un caso y perfil. La certificación H5-03 depende además de la revisión de los responsables y la matriz oficial. PERF-08 y RL requieren sus propios permisos y evidencias; ver [los bloqueos y la coordinación](MATRIZ_K6.md).

Para validar los perfiles de Pricing e Inventario con `k6 inspect` y el comparador con entradas artificiales, usa `.\tests\validar-arnes.ps1 -K6Path $K6`. La autoprueba usa exclusivamente valores inertes y no emite solicitudes HTTP.
