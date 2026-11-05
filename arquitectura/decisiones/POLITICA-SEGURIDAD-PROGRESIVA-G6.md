# Política de seguridad progresiva y reversible de G6

**Estado de la decisión:** adoptada; la arquitectura de tres fases está aprobada. **Estado de publicación:** este documento sigue en el PR Docs #114, abierto como draft y pendiente de merge/publicación. **Implementación:** pendiente. No se acredita homologación G7/G1–G5, grants efectivos, release ni despliegue.
**Alcance:** API Gateway, ocho microservicios G6 y sus fronteras de integración HTTP y asíncronas.
**Contratos de referencia al corte:** OpenAPI `0.6.0-rc.3`, AsyncAPI `0.6.0-rc.4` (candidatos documentales).
**Decisión transversal:** Backend #144, complementada por esta política. No crea DEC-F-016 ni altera DEC-F-001–015.

## 1. Propósito, alcance y lenguaje

G6 avanzará hacia la autenticación definitiva de Seguridad G7 en tres fases operativas. `PUBLIC_READ_ONLY` y `SIMULATED_AUTH` son etapas temporales; la arquitectura objetivo permanente es `G7_AUTHENTICATED`. Las transiciones se gobiernan por configuración validada y reinicios/redeploys controlados, sin rediseñar controladores, DTO, casos de uso ni repositorios. El selector común de esta política es una propuesta documental: todavía no está implementado.

Los nueve componentes son `api-gateway`, `catalog-svc`, `taxonomy-svc`, `pricing-svc`, `price-audit-svc`, `promotions-svc`, `combos-svc`, `inventory-svc` y `bulk-svc`. Las lecturas públicas se sirven por HTTPS a través de Caddy y Gateway. Los puertos de microservicios y dependencias siguen internos. Cada servicio conserva su autorización local y Gateway su propia responsabilidad; una decisión del Gateway no autentica una petición ni sustituye los guards del owner.

La autenticación establece quién presenta una credencial; la autorización decide si esa identidad puede realizar una operación bajo sus roles, scopes y contexto; las reglas de negocio y validaciones aseguran que el efecto permitido sea válido. Ninguna fase omite DTO, invariantes, persistencia, límites, idempotencia, auditoría, errores contractuales ni autorización específica cuando corresponda.

OpenAPI sigue siendo la fuente HTTP de rutas, métodos, schemas, seguridad declarada y scopes publicados. AsyncAPI sigue gobernando eventos, actores, mensajes y topología contractual. La política es una capa temporal de ejecución: no elimina esquemas `security`, modifica contratos, concede permisos ni cambia nombres de eventos/routing keys. Una consulta HTTP que publique un comando o evento con efectos de negocio no es lectura pura.

## 2. Principios de seguridad

1. **Default cerrado:** configuración explícita, validada al inicio. Valores inválidos, identidad desconocida, operación no registrada o decisión ambigua fallan cerrados.
2. **Sin fallback de seguridad:** fallos de G7, JWKS, red, parseo o configuración nunca habilitan una fase menos restrictiva automáticamente.
3. **Verificadores preservados:** JWT y guards existentes siguen disponibles; cambiar fase no elimina el camino autenticado.
4. **Mínimo privilegio:** autorización por operación, actor, scope/rol y restricciones de contexto. Ningún grant se infiere de la presencia de un endpoint.
5. **Contratos estables:** no modificar rutas, métodos, DTO, códigos contractuales, scopes, audiencias, identidades externas ni eventos sin el proceso de aprobación/homologación aplicable.
6. **Confianza explícita:** no aceptar identidad ni permiso a partir de IP, URL, `Origin`, `Referer`, `X-Forwarded-For` o headers `X-*` controlables por clientes. Gateway elimina headers de identidad no verificados al llamar a upstreams.
7. **Perímetro interno:** PostgreSQL, RabbitMQ, puertos de servicios y administración permanecen fuera de exposición pública. Caddy termina HTTPS público y enruta al Gateway; CORS no autentica.
8. **Controles operativos:** límites de solicitudes/tamaño, timeouts, errores sanitizados, logs sin secretos y trazabilidad por operación, commit SHA, entorno, configuración no secreta e imagen/digest.
9. **Sin simulación engañosa:** ningún token/identidad demo se presenta como emitido o concedido por G7. La telemetría no mutante no convierte una operación en mutación de negocio.
10. **Estados separados:** contrato, implementación, CI, autorización, homologación, despliegue y E2E tienen evidencia independiente.

## 3. Fase 1 — `PUBLIC_READ_ONLY`

Permite acceso anónimo desde Internet únicamente a operaciones cuya lectura pública esté expresamente aprobada en la matriz de operaciones. No se exige VPN, Tailscale ni allowlist IP para esas operaciones aprobadas. Esta autorización es por operación exacta (`operationId`, método y ruta), y no por prefijo, método o patrón general. No implica que todos los GET ni todos los POST sean aptos.

**Objetivo normativo de cobertura:** ofrecer acceso público y anónimo a todas las operaciones funcionalmente de lectura de los ocho microservicios, usen GET, HEAD, POST u otro método contractual. Este objetivo describe la cobertura que G6 busca alcanzar; no significa que una operación ya esté autorizada o publicada. La exposición efectiva requiere demostrar ausencia de mutaciones, revisar sensibilidad de datos y obtener aprobación explícita por operación.

La elegibilidad depende de semántica y efectos. Puede incluir GET, HEAD, POST de búsqueda/consulta u otro método contractual solo si el owner demuestra con contrato, implementación y pruebas que no crea/actualiza/elimina negocio, reserva/mueve stock o cupos, cambia precios, inicia/reanuda trabajos de escritura, programa efectos, publica comandos/eventos mutantes, induce mutaciones en otros servicios ni necesita identidad comercial para preservar invariantes. Un POST se considera consulta solo con evidencia explícita; su verbo por sí solo no decide.

La lista normativa y auditable exige por fila servicio, método, ruta exacta, `operationId`, clasificación, evidencia de no mutación, dependencias, sensibilidad y estado de autorización pública. Cada lectura termina en exactamente uno de estos estados: `PUBLICA_APROBADA`, `PENDIENTE_VERIFICACION` o `EXCEPCION_JUSTIFICADA`. La aprobación exige evidencia suficiente y decisión del owner; una candidata nunca se convierte en permiso por inferencia. Cada excepción registra causa técnica o contractual, owner, evidencia y condición verificable de resolución. Mutaciones y operaciones privadas conservan su clasificación y estado propios; la nueva columna de lectura de la matriz es una clasificación adicional y no sustituye ni reescribe el estado Fase 1 existente.

| Clasificación | Criterio de asignación |
|---|---|
| `PUBLICA_APROBADA` | Owner demuestra ausencia de efectos de negocio y propagación mutante; sensibilidad y dependencias revisadas; operación/método/ruta exactos aprobados explícitamente; pruebas negativas y positivas registradas por SHA. |
| `PENDIENTE_VERIFICACION` | Falta cotejo de implementación, evidencia de no mutación, revisión de sensibilidad, dependencias o decisión. Es el estado por defecto de una lectura aún no aprobada. |
| `EXCEPCION_JUSTIFICADA` | Se conserva una frontera contractual M2M, el contrato interno `x-internal`, o información protegida. La matriz identifica causa, owner, evidencia y condición verificable de resolución; no se publica anónimamente mientras subsista. |

Las operaciones que no son lecturas conservan sus estados de mutación/privacidad en la matriz y no reciben una de estas tres clasificaciones.

La matriz inventaría los 136 contratos OpenAPI y contrasta decoradores de ruta en Backend `master` `9f1bed8`; encontró 132 coincidencias método/ruta y cuatro discrepancias aún por confirmar. Una coincidencia de ruta no demuestra guards, efectos reales ni pruebas. Las decisiones de autorización pública siguen pendientes de evidencia funcional por SHA y aprobación del owner.

Las lecturas administrativas no sensibles no quedan excluidas por ser administrativas: se mantienen `PENDIENTE_VERIFICACION` hasta que el owner revise campos, efectos y sensibilidad; si la evidencia demuestra que son aptas, pueden aprobarse por operación. La información protegida (por ejemplo, saldos/ubicaciones detallados o transferencias internas) conserva autenticación como excepción justificada mientras siga vigente la necesidad de confidencialidad. Las fronteras actuales `serviceBearer`, scopes y allowlists M2M permanecen intactas. Una operación `x-internal: true` es privada; convertirla en pública requiere decisión expresa y, cuando corresponda, cambio homologado del contrato. La matriz registra causa, owner, evidencia y criterio de resolución para cada excepción vigente.

El modo público solo elimina el requisito de identidad en filas explícitamente aprobadas. Conserva validación, autorización residual, DTO, reglas de negocio, integraciones reales, límites y errores. La falta de contexto/identidad necesaria bloquea solo esa operación (`BLOQUEADO_ESPECÍFICO`). No hay bypass general de GET/POST, por servicio o por prefijo.

## 4. Fase 2 — `SIMULATED_AUTH`

La demostración autenticada usa JWT simulados con emisor propio, independiente de G7; no usa allowlists de IP/URL como identidad principal. Preferentemente RS256 y claves asimétricas exclusivas de demostración; publica JWKS de demo, issuer y audience contractual, expiración y firma verificable. Las claves privadas quedan fuera del repositorio y se gestionan como secretos de entorno. Identidades humanas y técnicas se distinguen. Claims solo se consideran compatibles con G7 cuando hayan sido homologados. Se verifican firma, `iss`, `aud`, vigencia, tipo de actor, scopes/roles y autorización por operación; errores siguen el contrato 401/403 aplicable.

El emisor y sus tokens no aparentan provenir de G7 ni se admiten en `G7_AUTHENTICATED`. Esta fase no sustituye la prueba bilateral con credenciales auténticas de G7.

### 4.1 Identidades de demostración

El inventario de actores a preparar incluye G1 Marketplace, G2 Despacho, G3 Chatbot, G4 Retail, G5 Ventas/Postventa, usuarios gestores comerciales y clientes internos G6. Los identificadores concretos son ejemplos hasta confirmación contractual. Separar actor humano de cliente M2M y asignar solo permisos requeridos por contrato/acuerdo homologado. No atribuir grants universales ni inferir aceptación externa.

### 4.2 Matriz declarativa de autorización

La configuración versionada de permisos debe permitir registrar: identidad; tipo de actor; módulo; roles; scopes; audience; operaciones permitidas por `operationId`; restricciones de contexto; vigencia; entorno y evidencia/fuente contractual. Los valores proceden de OpenAPI, acuerdos intermodulares y contrato G7. Un campo sin fuente queda `PENDIENTE`; no se completa por conveniencia. Cambiar permisos es modificar configuración versionada y revisable, no guards ni casos de uso. Identidad u operación desconocida deniega.

IP y CORS pueden complementar la defensa de red/navegador; nunca asignan identidad, rol o scope. No conceder permisos por IP, URL, `Origin`, `Referer`, `X-Forwarded-For` ni headers de navegador.

## 5. Fase 3 — `G7_AUTHENTICATED`

Es la meta permanente. Valida issuer G7, discovery/JWKS, firma y expiración; audience `api-productos` cuando aplique; claims homologados; clientes autorizados; tipo de actor; roles, scopes y permisos efectivos por operación. Integra flujos M2M y humanos y MFA cuando G7 lo requiera. Introspección se usa solo cuando el contrato G7 la exige. Aceptación requiere pruebas positivas y negativas por operación con tokens genuinos provisionados por G7 y evidencia de grant efectivo.

Esta fase rechaza tokens del emisor simulado. La pérdida de conectividad con G7 no habilita `SIMULATED_AUTH` ni `PUBLIC_READ_ONLY`; falla cerrada según operación y contrato. La fase 2 aporta cobertura local del mecanismo, no homologación, grant, despliegue ni prueba bilateral.

## 6. Selección y configuración de fases

Selector común propuesto, **no implementado**:

```dotenv
G6_SECURITY_MODE=G7_AUTHENTICATED
```

Valores admitidos: `PUBLIC_READ_ONLY`, `SIMULATED_AUTH`, `G7_AUTHENTICATED`. El default es `G7_AUTHENTICATED`; aceptar solo valores reconocidos. Valor inválido, modo sin configuración requerida o incompatibilidad entre Gateway y servicio causa fallo cerrado al arrancar o denegación segura. No hay fallback automático. Cambio de configuración puede requerir reinicio/redeploy. No se permiten estados intermedios que amplíen acceso por desalineación: Gateway y servicio deben declarar fase compatible y la operación se deniega si discrepan.

Antes de migrar, cada owner inventaría flags y defaults existentes en su SHA real. El inventario no elimina, renombra ni reinterpreta flags actuales. Una futura migración al selector común requerirá plan por servicio, compatibilidad, revisión de Marco y cambios de código autorizados; esta política no afirma que el selector esté disponible.

## 7. Flujo conceptual y responsabilidades por capa

```text
Cliente
  → Caddy / HTTPS público
  → API Gateway (rutas contractuales, límites y política de entrada)
  → identificación exacta de operación
  → fase activa: excepción pública aprobada | JWT demo | JWT G7
  → autorización por operación y contexto
  → microservicio owner (verificación independiente)
  → validaciones, reglas de negocio y persistencia
  → respuesta contractual
```

Gateway no puede convertir una cabecera de identidad en identidad validada ni otorgar permisos comerciales. Cada microservicio verifica según su propia frontera; tráfico interno usa red privada y autenticación autorizada. Una operación interna, M2M o `x-internal` no se publica por quedar accesible desde Gateway. El acceso directo externo a puertos de servicio permanece bloqueado en todas las fases.

## 8. Criterios de prueba y aceptación

| Caso | Fase 1 | Fase 2 | Fase 3 |
|---|---|---|---|
| Lectura pública incluida en matriz | Sin JWT solo para operación aprobada | JWT demo válido según permiso | JWT G7 válido según permiso |
| POST de búsqueda/consulta | Sin JWT solo con evidencia de no mutación y aprobación | JWT demo válido | JWT G7 válido |
| Escritura sin JWT | Denegada | Denegada | Denegada |
| JWT ausente/erróneo, firma o issuer incorrecto | No concede excepción fuera de lectura aprobada | 401 contractual | 401 contractual |
| Audience/expiración incorrectas | Deniega operación protegida | 401 contractual | 401 contractual |
| Scope/rol insuficiente | Denegado | 403 contractual | 403 contractual |
| Humano/M2M válido | No aplica excepción por identidad | Prueba actor/permisos declarados | Token G7 genuino y grant efectivo |
| Identidad u operación desconocida | Denegada | Denegada | Denegada |
| JWKS/issuer indisponible | Solo lectura pública ya aprobada puede seguir si su configuración no depende de identidad | Falla cerrada | Falla cerrada |
| Configuración inválida o fase incompatible | Arranque/operación falla cerrada | Arranque/operación falla cerrada | Arranque/operación falla cerrada |
| Desactivar modo público/demo y volver a G7 | Verificar denegación anónima | Verificar tokens demo rechazados | Regresión de permisos con G7 |

Cada ejecución indica fase, operación, versión de contrato, commit SHA, entorno y evidencias. Separar pruebas de código, CI, prueba Oracle y homologación externa. JWT simulado nunca acredita H4 autenticado. Una lectura pública exitosa no acredita escritura, gateway completo, despliegue ni integración M2M.

## 9. Transiciones reversibles

Transiciones previstas: `PUBLIC_READ_ONLY → SIMULATED_AUTH`, `SIMULATED_AUTH → G7_AUTHENTICATED` y `PUBLIC_READ_ONLY → G7_AUTHENTICATED`. La configuración del selector sigue siendo propuesta y aún no está implementada. Caddy verifica HTTPS, host, ruta al Gateway y ausencia de exposición directa de puertos; la selección de fase se valida en Gateway y microservicios, que deben mantener una configuración efectiva compatible.

| Transición/componente | Criterio verificable antes y después |
|---|---|
| Caddy, cualquier fase | Registrar SHA/configuración efectiva y comprobar HTTPS/certificado, host y upstream Gateway. Confirmar que no enruta a microservicios directamente y que puertos internos no son alcanzables desde Internet. Caddy no decide ni degrada el modo de seguridad. |
| Gateway al activar Fase 1 | Confirmar al arranque el modo y la versión de lista exacta `operationId`/método/ruta; probar anónimo permitido solo para filas `PUBLICA_APROBADA`, y rechazo de escrituras, privadas, excepciones, rutas desconocidas y lecturas pendientes. No usar bypass por método/prefijo. |
| Microservicios al activar Fase 1 | Confirmar por servicio modo efectivo y lista/guard compatible; probar las lecturas aprobadas por ruta directa interna sin cambiar el control del Gateway. Verificar que las denegadas no mutan BD, stocks, precios, cupones, trabajos ni eventos. Registrar respuestas, logs sanitizados y SHA. |
| `PUBLIC_READ_ONLY → SIMULATED_AUTH` | Cambiar configuración explícita en Gateway y los ocho servicios; Caddy conserva TLS/ruta. Una petición anónima a cada lectura antes pública debe ser rechazada por Gateway y por servicio cuando se invoque directamente; JWT demo válido solo pasa scopes/roles/identidad autorizados. Probar token inválido, issuer/audience incorrectos, vencido y scope/rol insuficiente. |
| `SIMULATED_AUTH → G7_AUTHENTICATED` | Configurar issuer/JWKS G7 efectivo en Gateway y servicios. Probar que un JWT del emisor simulado se rechaza en todas las rutas y que un token genuino G7 solo obtiene las operaciones/scopes/roles concedidos. JWT ausente, issuer/JWKS inaccesible o claims inválidos fallan cerrados, sin volver a demo o público. |
| `PUBLIC_READ_ONLY → G7_AUTHENTICATED` | Aplicar directamente los gates de salida de Fase 1 y entrada de Fase 3: ninguna lectura anónima antes aprobada queda accesible; tokens simulados se rechazan; token genuino G7 se prueba por rol/scope; acceso a rutas internas y puertos permanece cerrado. |
| Cualquier reversión autorizada | Marco registra motivo, alcance, duración y SHA/configuración de rollback. Caddy, Gateway y cada servicio deben observar la fase autorizada; rechazar el modo inválido o el desalineamiento. Comprobar anónimo denegado al salir de Fase 1, JWT demo denegado en Fase 3 y que scopes, roles, allowlists M2M y guards autenticados no se amplían ni eliminan. No hay fallback automático ante fallos. |

La recuperación operativa puede volver a un modo menos restrictivo solo con autorización explícita de Marco, análisis de incidente y alcance temporal documentado; jamás por fallo automático. Toda transición requiere respaldar configuración no secreta, revisar flags y operaciones, ejecutar pruebas positivas/negativas y conservar un rollback controlado. Cambiar JWKS no basta para integrar G7: issuer, audience, claims, clients, grants, scopes, verificadores, secretos y pruebas bilaterales también deben estar listos.

## 10. Responsabilidades

- **Marco:** autoridad de decisión transversal, aprobación de cambios Gateway y selector, autorización explícita de cambios de fase y releases.
- **Owners de servicios:** inventario de operaciones/flags, lógica de su servicio, política y pruebas por operación, evidencia por SHA; no modifican otros servicios.
- **G7 Seguridad:** issuer/JWKS, contratos de identidad, registro de clients/scopes, grants y credenciales genuinas.
- **Módulos consumidores G1–G5:** homologación bilateral y pruebas de permisos y flujos bajo su ownership.
- **Infraestructura:** HTTPS/Caddy, redes/puertos, secretos runtime, reinicio/redeploy y recuperación, con verificación y autorización aplicables.

## 11. Plan de implementación documental y por owner

Por cada uno de los ocho servicios, registrar: inventario y clasificación de operaciones; guards; flags reales; dependencias; política de fase 1; matriz de fase 2; compatibilidad G7; pruebas; evidencias por SHA; estado de preparación; pendientes externos. Fase 1 puede implementarse antes de construir emisor JWT de demo. No se exige implementar ese emisor para desplegar lecturas públicas autorizadas. Ambas fases conservan el camino estructural a G7. Taxonomy y Catalog son prioridad operativa inmediata; los nueve componentes están dentro de la cobertura normativa.

Estados requeridos por separado: `CONTRATO`, `CÓDIGO`, `CI`, `AUTORIZACIÓN`, `HOMOLOGACIÓN`, `DESPLIEGUE`, `E2E`. Un estado sin evidencia permanece pendiente. Una dependencia externa identifica owner, operación afectada y condición verificable de desbloqueo.

## 12. Reconciliación documental y decisiones sustituidas

| Documento anterior | Regla anterior | Regla vigente y alcance exacto | Consecuencia / pendiente |
|---|---|---|---|
| Backend `ops/oracle/H4-MODO-DEMO-AUTH-REVERSIBLE.md` §2, §2.1, §2.2 y regla final; Backend #144 | Demo sin JWT solo `RESTRICTED_DEMO`, perímetro privado obligatorio; se prohíbe exposición anónima a Internet y se conserva auth por operación | Para filas expresamente aprobadas como lectura pública, la Fase 1 permite Internet anónimo sin VPN/Tailscale/IP allowlist. La decisión sustituye únicamente el requisito de perímetro privado para esas operaciones. Fase 2/3, escrituras, administración sensible, M2M interno, puertos, DB, RabbitMQ, credenciales y rutas no aprobadas mantienen protección | **Prerequisito para activar Fase 1 en Oracle:** Marco/owner de política actualiza y aprueba `ops/oracle/H4-MODO-DEMO-AUTH-REVERSIBLE.md` en un cambio separado de Backend, lo alinea con esta política ya publicada y registra el SHA desplegado/revisado. Hasta entonces, no activar Fase 1 pública en Oracle. Owners de servicio implementan la lista exacta y pruebas; esta PR no edita Backend |
| Backend #144 §3, flags por servicio | Flags heterogéneos; no había selector global aprobado | Se propone documentalmente `G6_SECURITY_MODE`; no está implementado ni elimina/reinterpreta flags actuales | Owners inventarían flags reales por SHA y Marco coordina futura migración de código |
| Backend #144 §2.4 y Docs Arquitectura §21; OpenAPI `0.6.0-rc.3` | JWT G7, scopes/audience/allowlist contractual; sin grants G7 demostrados | Se conservan íntegros. Lectura pública es una excepción operativa específica que no retira `security` de OpenAPI ni habilita actores M2M | Resolver divergencias operación-contracto explícitamente; no atribuir grants |
| Docs `arquitectura/Arquitectura.md` §21 y trazabilidad DEC-F | JWT G7 como política ordinaria; notas de cortes anteriores dicen que bypass de demo no estaba aprobado | Las notas anteriores siguen siendo evidencia histórica del corte que describen. Esta decisión añade fase pública solo para operaciones aprobadas; el camino autenticado queda objetivo | Actualizar backend y revisar referencias derivadas después de este PR, preservando la fecha/alcance de evidencias históricas |
| Acuerdos G1–G6, G2–G6, G5–G6 y OpenAPI/AsyncAPI candidatos | Scopes, roles, identidad, operación y efectos contractuales por consumidor | Ningún acuerdo ni contrato se reescribe por esta capa. La nueva política no autoriza una lectura que viole sensibilidad/invariantes ni cambia autorización externa | G7 concede grants; consumidores y G6 homologan seguridad y pruebas por operación |

La sustitución es precisa: **solo** desaparece la exigencia de perímetro privado para las operaciones confirmadas y aprobadas en la matriz como lecturas públicas. No desaparecen restricciones de puertos internos, administración sensible, escrituras, RabbitMQ, PostgreSQL, identidad de sistema ni secretos. La actualización aprobada del documento Backend citado es un gate previo a activar Fase 1 en Oracle; permanece pendiente y no se modifica en este PR documental.

## 13. Fuentes canónicas

- [Matriz de operaciones de seguridad](MATRIZ-OPERACIONES-SEGURIDAD-G6.md).
- [Backend: política H4 previa y reversible](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/master/ops/oracle/H4-MODO-DEMO-AUTH-REVERSIBLE.md) y [Backend #144](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/144).
- [OpenAPI](../../contratos/http/openapi.yaml), [AsyncAPI](../../contratos/eventos/asyncapi.yaml), [Registro DEC-F](REGISTRO_DEC_F.md), [Matriz de trazabilidad DEC-F](MATRIZ_TRAZABILIDAD_DEC_F.md), [Acuerdo G1–G6 H4](../../integraciones/ACUERDO_G1_G6_H4_2026-10-20.md), [alineación Marketplace](../../integraciones/ALINEACION_MARKETPLACE.md) y [pruebas de contrato](../../contratos/pruebas/pruebas-contrato.md).
