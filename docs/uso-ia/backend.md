# Evidencia de uso de IA en backend

- **Registro:** IA-BE-001.
- **Documentado retrospectivamente:** 2026-10-17.
- **Repositorio:** `Taller-SW-Web/G6-Productos-Ofertas-backend`.
- **Revisión local identificada:** rama `cueva`, SHA `3f42e0e474071a13eb1b3120819d142cfeda4a95`.

## 1. Intervención identificada

Se recuperó la conversación **«Trabajar desde la rama cueva»**, ID `01a1473e-fb4f-7fb1-a48b-917690c56218`, del proyecto backend en Codex. En el turno `01a14740-0b09-7591-bbb4-ac6e675f3927`, el usuario solicitó sincronizar dependencias, repetir validaciones, conservar el consumidor deshabilitado, actualizar evidencias y agregar una prueba de restauración única.

Extracto de la instrucción conservada:

> Agrega una prueba de restauración que verifique que una segunda operación no modifica `restored_at` ni libera dos veces el cupo.

La respuesta final de ese turno informa la incorporación de la prueba y el commit `eac3b1e8c233817f28e9b5a4e3145116094c6bc1`. El commit existe y su diff incluye el script de prueba y documentación de Promotions. Esto vincula una instrucción humana concreta con una intervención de Codex y un resultado versionado.

**Tipo de aporte:** modificación de pruebas, actualización de evidencias y asistencia en sincronización de dependencias. No se atribuye a esta sesión la generación original de todos los servicios ni de toda la lógica de cupones.

## 2. Fuentes de contexto identificadas

El [README de Promotions en la revisión consultada](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/3f42e0e474071a13eb1b3120819d142cfeda4a95/apps/promotions-svc/README.md) declara como base Docs `c36bd9a18f4fdb188df0d7e5158a431cf4b4ea7b`, Arquitectura, SPEC-005/006/007, modelo físico, registro DEC-F, OpenAPI `0.6.0-rc.1` y AsyncAPI `0.6.0-rc.2`.

Esta es una base documental declarada por el reporte del servicio. La recuperación actual no reconstruye todos los archivos efectivamente enviados como contexto en cada turno histórico.

## 3. Resultado y código relacionado

| Evidencia | Qué permite identificar |
|---|---|
| [Commit de corrección](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/commit/eac3b1e8c233817f28e9b5a4e3145116094c6bc1) | Versión vinculada con la respuesta de Codex. |
| [Prueba aislada de cupones](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/eac3b1e8c233817f28e9b5a4e3145116094c6bc1/apps/promotions-svc/test/coupons.isolated.smoke.mjs) | Script modificado por ese commit, con el escenario de segunda restauración. |
| [Reporte de la corrección](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/eac3b1e8c233817f28e9b5a4e3145116094c6bc1/apps/promotions-svc/REVISION-MASTER-2026-10-16.md) | Alcance, validaciones informadas y dependencias conservadas. |
| [Transacciones de cupones](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/3f42e0e474071a13eb1b3120819d142cfeda4a95/apps/promotions-svc/src/coupons/coupon-transactions.ts) | Código relacionado: la restauración actualiza `restored_at` condicionado a que siga nulo. Su presencia no atribuye su autoría a la sesión recuperada. |
| [Reporte posterior a #117](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/3f42e0e474071a13eb1b3120819d142cfeda4a95/apps/promotions-svc/REVISION-POST-117-2026-10-16.md) | Continuidad de la revisión y sincronización; mantiene límites de integración y activación. |

## 4. Intervención humana y revisión

El usuario definió el comportamiento a verificar, las dependencias que debían preservarse, la rama y los límites de integración. Codex informó cambios y resultados; el usuario solicitó posteriormente otra sincronización antes de autorizar el merge. Se conserva así evidencia de instrucciones y seguimiento humanos.

El owner de Promotions es Axel Cueva según [Equipo y responsabilidades](../../EQUIPO_Y_RESPONSABILIDADES.md). La identidad de quien realizó cada edición manual y la aprobación final de esta reconstrucción quedan por completar. La respuesta del agente y la solicitud de revisión no se registran como aprobación de merge.

## 5. Validaciones históricas consultadas

La conversación y el reporte posterior registran 67 pruebas unitarias de Promotions, 6 HTTP, pruebas generales y comprobaciones aisladas. El reporte posterior cita 289 unitarias generales y 347 HTTP, con 20 omitidas por configuración privada. Estos resultados pertenecen a sus ejecuciones históricas y al alcance descrito en esos reportes.

El [JSON de cupones aislados](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/3f42e0e474071a13eb1b3120819d142cfeda4a95/apps/promotions-svc/test/evidence/coupons-isolated-2026-10-16.json) conserva `result=PASS`, entorno descartable y límites explícitos. Identifica la fuente normativa de Docs y `working_tree=LOCAL_UNPUBLISHED`: no debe interpretarse su `source_commit` como el SHA del backend probado.

En esta recopilación se consultaron conversación, commits y artefactos. No se repitieron pruebas ni se verificó nuevamente el estado remoto de CI. La evidencia no acredita homologación con G5, consumidor habilitado, despliegue ni ejecución de las APIs administrativas de Promotions.

## 6. Código generado por herramientas

El [archivo coupon-contract.generated.ts](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/3f42e0e474071a13eb1b3120819d142cfeda4a95/apps/promotions-svc/src/coupons/coupon-contract.generated.ts) indica que deriva del contrato de Docs; existe un [script generador](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/3f42e0e474071a13eb1b3120819d142cfeda4a95/apps/promotions-svc/test/generate-coupon-contract.mjs). Esa generación contractual debe registrarse separadamente de la generación por IA. La palabra `generated` no determina por sí sola la procedencia de IA.

## 7. Cobertura pendiente

El monorepo contiene ocho servicios de negocio y Gateway. Este caso cubre una intervención en Promotions. Faltan registros específicos de generación, modificación y revisión de los demás componentes, con sus instrucciones, versiones y contribuciones humanas. Usar la [plantilla](plantilla-intervencion.md) y la [matriz](matriz-trazabilidad.md) para incorporarlos.
