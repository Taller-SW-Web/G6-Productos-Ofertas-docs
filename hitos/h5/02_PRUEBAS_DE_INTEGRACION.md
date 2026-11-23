# H5-02 — Pruebas de integración demostrables

**Estado documental:** planificado; no se ejecutan integraciones en esta tarea. La exigencia docente es evidencia de pruebas de integración. Los niveles, IDs, suites y alcance son criterios internos G6.

## Niveles L0–L3 y límites

| Nivel | Evidencia que admite | Qué no demuestra |
|---|---|---|
| L0 | OpenAPI/AsyncAPI parseables, operationId, esquemas, rutas y ejemplos estáticos | Runtime, seguridad operativa ni despliegue |
| L1 | Servicios reales de G6 + PostgreSQL descartable; stubs G7 declarados como `SIMULATED_DEPENDENCY` | Azure/G7 real, homologación ni production |
| L2 | APIM/Gateway, servicios, DB de pruebas y Service Bus/Managed Identity reales; token real cuando haya grant | Aceptación de otro grupo o despliegue productivo |
| L3 | Cliente G1–G5, grants autorizados, evidencia conjunta y acuerdo bilateral | Aprobación por silencio o extensión a otros flujos |

Núcleo H5: INT-01/05/07/08/10. INT-02/03/04/06/09 se prueban si el manifest declara esas operaciones. INT-06 entra al núcleo si se elige R18; INT-04 si se elige R01. R18 es segundo flujo SB preferente tras reconciliar #247/fork; R07 es fallback predefinido si R18 no puede habilitarse, con decisión registrada antes del ensayo. L3 no es requisito universal H5; sí hace falta para afirmar homologación de una integración G5.

## Matriz INT-01 a INT-10

| ID / owner | Caso positivo y negativo | Dependencia / harness y nivel | Resultado real futuro y evidencia exigida |
|---|---|---|---|
| INT-01 — Poma | producto simple, variante y oferta; SKU ausente, agotado e indeterminado | Catalog→Pricing→disponibilidad; Vitest/Supertest y DB descartable L1; L2 para ruta real | `junit.xml`, `integration-results.json`, corr IDs, SHAs y respuestas redactadas |
| INT-02 — Taco | disponibilidad suficiente/insuficiente, reservar, liberar y consultar; repetir clave | Inventory/DB sintética; Supertest L1 y L2 condicionado | un efecto por clave, SQL descartable, resultado y `operation_id` |
| INT-03 — Axel | cupón elegible, consumo/restauración; agotado/no elegible y doble envío | Promotions tras grants/activación; L1 + L2 | resultado durable, Inbox/Outbox, SQL y prueba con identidad permitida; sin grant `BLOCKED_AUTH` |
| INT-04 — Castilla | lote Bulk crea referencia privada, SHA-256 y estado; repetir o enviar contenido inválido | Bulk→Catalog; Poma coejecuta validación de Catalog; L1, L2 si R01 activo | recepción, digest, estado terminal y replay; archivo sintético |
| INT-05 — Vera | Pricing publica cambio y Price Audit persiste; duplicar, reiniciar worker y llevar mensaje inválido a DLQ | R16, Azure real L2 obligatorio para evidencia H5; reutilizar piloto #234 solo como antecedente | `message_id`, `operation_id`, SQL Inbox/Outbox, DLQ, correlación y bundle digest de la corrida actual |
| INT-06 — López | baja Taxonomy válida y denegada, correlación, resultado terminal | Taxonomy↔Catalog; L1; L2 si relación habilitada/R18 elegido | pruebas por mensaje, estado persistido y SHA; no combinar runtime #247 y fork |
| INT-07 — Castilla | respuesta 200, 401/403/404/429, CORS y corr ID | APIM+Gateway+G7 real L2; L1 solo prepara fixtures, no acredita prueba externa | hostname APIM, política hash, solicitud/respuesta, logs redactados y grant |
| INT-08 — Poma | UI administrativa recorre Frontend→APIM→Gateway→owner; error y sesión no autorizada | Playwright L1; smoke real L2; SHAs Frontend/Backend/Docs | trace/video redactado, run, HAR sin credenciales, corr ID y respuesta |
| INT-09 — Axel | G5 consulta variante vendible, stock/dimensiones y operación permitida; denegación fuera de scope | Cliente G5 + JWT/G7 y homologación; L3 sujeto a ventana | artefacto bilateral, SHAs de ambos módulos, scope autorizado; no se simula homologación |
| INT-10 — Vera | apagar worker/broker/DB, reanudar Outbox, redelivery sin duplicar efecto | R16 + segundo flujo SB, L1 y L2 real para piloto/flujo elegido | eventos de caída/recuperación, SQL correlacionado, DLQ, tiempos y ausencia de efecto doble |

## Fallos y recuperación

Inyectar timeout antes/después del commit durable; dos solicitudes concurrentes con misma Idempotency-Key/cuerpo (un efecto) y misma clave/cuerpo diferente (conflicto contractual); caída del worker antes de settlement (redelivery sin repetir SQL); broker no disponible tras commit (Outbox pendiente); mensaje inválido (aislar/DLQ); replay autorizado (auditar operador); fallo de JWKS (rechazo seguro); expiración de reserva y carrera con confirmación sin cambiar ownership G5. Nunca consumir datos/stock compartidos; emplear IDs, SKUs e identidades sintéticas o DB clonada. No purgar DLQ ni reintentar efectos automáticamente sin reconciliar estado durable.

## G7, G5 y alcances condicionados

G7 mantiene autoridad de issuer y grants. Owner G6 y G7 deben verificar client_id/audience/scope/ambiente efectivos; sin eso prueba real queda `BLOCKED_AUTH`. G5 y G6 registran acuerdo, ventana, endpoint, resultado, scopes y evidencia bilateral; hasta entonces `PENDIENTE_HOMOLOGACION_G5`. G1–G5 consumen HTTP autenticado por APIM/Gateway, no colas Basic. Los stubs de L1 son visibles y no se reportan como L2.

## Responsables y entregables

Poma es owner de INT-01 e INT-08 y coejecutor de INT-04; Castilla es owner de INT-04 e INT-07/APIM. Taco es owner de INT-02; Axel de INT-03/09 y del transporte del flujo seleccionado; Vera de INT-05/10; López de INT-06; Castilla consolida. Cada responsable aporta test ID, comando, SHA exacto, harness, entorno, dependencia simulada/real, salida JUnit/JSON, correlación y digest/hash del artefacto. Ninguna asignación crea Issue ni modifica PR.

## Evidencia, procedencia y aceptación

Formato futuro: resultado `PASS|FAIL|INCONCLUSIVE|NOT_RUN`, nivel `STATIC|ISOLATED|LAB_AZURE|STAGING_REAL|INTERGROUP`, estado de despliegue y verificación separados, bloqueo con owner/condición. Guardar `junit.xml`, `integration-results.json`, logs redactados, run ID y artifact SHA-256; para UI, Playwright trace; para L2, identidad/revisión/imagen y hostname; para L3, aceptación bilateral verificable. El SHA de Frontend, Backend y Docs se consigna por separado. CI `skipped`, fixture o link de run sin artefacto no es PASS. Véanse [topología](../../contratos/eventos/TOPOLOGIA-SERVICE-BUS-BASIC-H5.md), [OpenAPI](../../contratos/http/openapi.yaml), [AsyncAPI](../../contratos/eventos/asyncapi.yaml) y [scorecard](07_MATRIZ_TRAZABILIDAD_Y_EVIDENCIAS.md).
