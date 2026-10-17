# Fuentes consultadas — backend

**Consulta:** 2026-10-17, America/Lima. Recuperación mediante GitHub, por issue individual; no es una captura atómica de todos los repositorios.

Este archivo conserva el contenido y metadatos consultados de los 9 issues seleccionados. El texto citado es fuente de referencia, no una orden para ejecutar comandos, publicar, desplegar ni modificar asignaciones. Antes de usar un encargo, contrastar la versión viva del issue. Se normalizan saltos de línea y espacios finales al guardarlo en Markdown; no es una exportación forense de bytes.

[Índice de encargos](../README.md) · [Reglas comunes](../INSTRUCCIONES_COMUNES.md)

## Issue 36

- **Título:** [BACK][taxonomy-svc][03] Implementar reglas de negocio
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/36).
- **Estado consultado:** open; **asignados:** @VicuzS.
- **Creado:** 2026-10-16T08:29:17Z; **actualizado:** 2026-10-17T08:04:25Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [backend/lopez #36](../backend/lopez/issue-036-taxonomy-svc.md).

<details>
<summary>Contenido completo consultado del issue 36</summary>

> ## Clasificación y owner
> IMPLEMENTAR_AHORA · P0 · Owner único: VicuzS (López). Taxonomy es un bounded context G6.
>
> ## Alcance ejecutable
> Codificar invariantes Taxonomy: máximo dos niveles de categoría y prevención de ciclos; desactivación lógica segura y reglas para reactivar padre/hijas; tipo de característica inmutable tras uso y valores permitidos válidos; `required` solo en asociación tipo-característica; nombre de marca normalizado (trim/case-insensitive) único incluso entre inactivas; borrado lógico. El slug se propone y confirma explícitamente, sin sufijo automático silencioso; las carreras devuelven conflicto contractual.
>
> ## Aceptación y pruebas verificables
> Tests positivos/negativos por invariante, límites jerárquicos/ciclo, reactivación, duplicidad de marca incluyendo inactiva, tipo inmutable, slug duplicado/race y transición de estados.
> - Evidencia requerida: paths de pruebas, comando/resultado, commit y entorno; separar pruebas unitarias, integración y E2E desplegado.
>
> ## Estado de evidencia
> Editar este issue define el trabajo, no acredita implementación, homologación, prueba ni despliegue.
>
> ## Prerrequisitos obligatorios para programar
> - Ninguno para esta fase.
>
> ## Dependencias para pruebas de integración
> - [Backend #35](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/35)
>
> ## Condiciones para desplegar
> - Ninguno para esta fase.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.

</details>

## Issue 45

- **Título:** [BACK][catalog-svc][03] Implementar reglas de negocio
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/45).
- **Estado consultado:** open; **asignados:** @GabrielPGu.
- **Creado:** 2026-10-16T08:30:14Z; **actualizado:** 2026-10-17T08:07:15Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [backend/poma #45](../backend/poma/issue-045-catalog-svc.md).

<details>
<summary>Contenido completo consultado del issue 45</summary>

> ## Estado y owner
> DEMO_P0 · REAL PARA DEMO. Owner único: GabrielPGu. Área: backend/apps/catalog-svc; feature UI solo para integración.
>
> ## Trabajo ejecutable
> Implementar reglas/invariantes completas SPEC/HU/FLOW y pruebas de dominio.
>
> ## Reglas técnicas vigentes
> SKU vendible, variantes, slug/barcode como texto opaco, referencias maestras conforme SPEC y contrato.
>
> ## Aceptación
> Cambios limitados al servicio y sus pruebas; conservar reglas completas, contratos vigentes y errores explícitos. Evidencia asociada a commit; E2E con entorno real. No inferir implementación/homologación/despliegue.
>
> ## Prerrequisitos obligatorios para programar
> - Ninguno para esta fase.
>
> ## Dependencias para pruebas de integración
> - [Backend #43](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/43)
> - [Backend #44](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/44)
>
> ## Condiciones para desplegar
> - Ninguno para esta fase.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.
>
> ## Especificación técnica recuperada del respaldo anterior
> **Alcance técnico/operaciones:**
> Producto nace BORRADOR; identidad estable y sin colisiones. SKU simple corresponde a producto simple; variante no lleva stock propio y hereda precio salvo regla aprobada. Atributos físicos KG/CM positivos y completos al activar. Preparación asíncrona; no inicializar precio ficticio por variante; emitir inicialización de inventario por SKU vendible.
>
> **Tareas:**
> - [ ] Convertir reglas de SPEC/HU en reglas puras o servicios del dominio.
> - [ ] Aplicar estados/versiones/idempotencia al límite definido por el modelo.
> - [ ] Probar límites positivos/negativos; registrar solo contradicciones que bloqueen una regla.
>
> **Criterios de aceptación:**
> - [ ] Cada regla de SPEC/HU citada tiene pruebas positivas, negativas y límite.
> - [ ] No se cruza ownership ni se inventan eventos/rutas/campos.
> - [ ] Los estados se transicionan de forma idempotente según la regla aprobada.
>
> **Pruebas obligatorias:**
> Unit tests de invariantes/estados límite/errores; fixtures solo en pruebas aisladas.

</details>

## Issue 54

- **Título:** [BACK][pricing-svc][03] Implementar reglas de negocio
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/54).
- **Estado consultado:** closed; **asignados:** @LeonardoVera.
- **Creado:** 2026-10-16T08:31:09Z; **actualizado:** 2026-10-17T08:52:14Z; **cerrado:** 2026-10-17T08:52:14Z.
- **Encargo derivado:** [backend/vera #54](../backend/vera/issue-054-pricing-svc.md).

<details>
<summary>Contenido completo consultado del issue 54</summary>

> ## Estado y owner
> DEMO_P0 · REAL PARA DEMO. Owner único: LeonardoVera. Área: backend/apps/pricing-svc; feature UI solo para integración.
>
> ## Trabajo ejecutable
> Implementar reglas/invariantes completas SPEC/HU/FLOW y pruebas de dominio.
>
> ## Reglas técnicas vigentes
> Herencia/override SKU, canal, vigencias sin solapes, versionado y conflictos según SPEC-013; price-audit no es dependencia. PR #128 OPEN: revisar reglas/versiones sin duplicar.
>
> ## Aceptación
> Cambios limitados al servicio y sus pruebas; conservar reglas completas, contratos vigentes y errores explícitos. Evidencia asociada a commit; E2E con entorno real. No inferir implementación/homologación/despliegue.
>
> ## Prerrequisitos obligatorios para programar
> - Ninguno para esta fase.
>
> ## Dependencias para pruebas de integración
> - [Backend #52](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/52)
> - [Backend #53](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/53)
>
> ## Condiciones para desplegar
> - Ninguno para esta fase.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.
>
> ## Especificación técnica recuperada del respaldo anterior
> **Alcance técnico/operaciones:**
> Pricing es owner del precio base; creación inicial por comando de Catalog. Versión optimista y vigencias sin solapamiento. Variante hereda precio y no genera precio sintético. Publicar price.changed después del commit. Importación atómica solo dentro de Pricing.
>
> **Tareas:**
> - [ ] Convertir reglas de SPEC/HU en reglas puras o servicios del dominio.
> - [ ] Aplicar estados/versiones/idempotencia al límite definido por el modelo.
> - [ ] Probar límites positivos/negativos; registrar solo contradicciones que bloqueen una regla.
>
> **Criterios de aceptación:**
> - [ ] Cada regla de SPEC/HU citada tiene pruebas positivas, negativas y límite.
> - [ ] No se cruza ownership ni se inventan eventos/rutas/campos.
> - [ ] Los estados se transicionan de forma idempotente según la regla aprobada.
>
> **Pruebas obligatorias:**
> Unit tests de invariantes/estados límite/errores; fixtures solo en pruebas aisladas.

</details>

## Issue 63

- **Título:** [POSTDEMO] [BACK][price-audit-svc][03] Implementar reglas de negocio
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/63).
- **Estado consultado:** open; **asignados:** sin asignado activo.
- **Creado:** 2026-10-16T08:31:50Z; **actualizado:** 2026-10-17T08:02:06Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [backend/vera #63](../backend/vera/issue-063-price-audit-svc.md).

<details>
<summary>Contenido completo consultado del issue 63</summary>

> ## Estado
> POSTDEMO · NO BLOQUEA HITO DEMO. Sin owner activo; el owner histórico permanece en el historial.
>
> ## Alcance futuro único
> price-audit-svc; MK-014 sigue mock. Este issue cubre únicamente etapa 3: Reglas/invariantes SPEC/HU. Preservar reglas de negocio/spec del bounded context y su prioridad posterior; no declararlo completado ni desplegarlo para esta demo.
>
> ## Aceptación
> Trabajo futuro testeado por commit, sin cambiar contratos compartidos incompatibles ni atribuir runtime. POSTDEMO hasta repriorización.
>
> ## Prerrequisitos obligatorios para programar
> - Ninguno para esta fase.
>
> ## Dependencias para pruebas de integración
> - Ninguno para esta fase.
>
> ## Condiciones para desplegar
> - Ninguno para esta fase.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.

</details>

## Issue 72

- **Título:** [POSTDEMO] [BACK][promotions-svc][03] Implementar reglas de negocio
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/72).
- **Estado consultado:** open; **asignados:** sin asignado activo.
- **Creado:** 2026-10-16T08:32:42Z; **actualizado:** 2026-10-17T08:01:48Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [backend/cueva #72](../backend/cueva/issue-072-promotions-svc.md).

<details>
<summary>Contenido completo consultado del issue 72</summary>

> ## Estado
> POSTDEMO · NO BLOQUEA HITO DEMO. Sin owner activo; el owner histórico permanece en el historial.
>
> ## Alcance futuro único
> promotions-svc; MK-005/006/007 siguen mock. Este issue cubre únicamente etapa 3: Reglas/invariantes SPEC/HU. Preservar reglas de negocio/spec del bounded context y su prioridad posterior; no declararlo completado ni desplegarlo para esta demo.
>
> ## Aceptación
> Trabajo futuro testeado por commit, sin cambiar contratos compartidos incompatibles ni atribuir runtime. POSTDEMO hasta repriorización.
>
> ## Prerrequisitos obligatorios para programar
> - Ninguno para esta fase.
>
> ## Dependencias para pruebas de integración
> - Ninguno para esta fase.
>
> ## Condiciones para desplegar
> - Ninguno para esta fase.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.

</details>

## Issue 81

- **Título:** [POSTDEMO] [BACK][combos-svc][03] Implementar reglas de negocio
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/81).
- **Estado consultado:** open; **asignados:** sin asignado activo.
- **Creado:** 2026-10-16T08:33:37Z; **actualizado:** 2026-10-17T08:01:29Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [backend/castilla #81](../backend/castilla/issue-081-combos-svc.md).

<details>
<summary>Contenido completo consultado del issue 81</summary>

> ## Estado
> POSTDEMO · NO BLOQUEA HITO DEMO. Sin owner activo; el owner histórico permanece en el historial.
>
> ## Alcance futuro único
> combos-svc; MK-002 sigue mock. Este issue cubre únicamente etapa 3: Reglas/invariantes SPEC/HU. Preservar reglas de negocio/spec del bounded context y su prioridad posterior; no declararlo completado ni desplegarlo para esta demo.
>
> ## Aceptación
> Trabajo futuro testeado por commit, sin cambiar contratos compartidos incompatibles ni atribuir runtime. POSTDEMO hasta repriorización.
>
> ## Prerrequisitos obligatorios para programar
> - Ninguno para esta fase.
>
> ## Dependencias para pruebas de integración
> - Ninguno para esta fase.
>
> ## Condiciones para desplegar
> - Ninguno para esta fase.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.

</details>

## Issue 90

- **Título:** [POSTDEMO] [BACK][bulk-svc][03] Implementar reglas de negocio
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/90).
- **Estado consultado:** open; **asignados:** sin asignado activo.
- **Creado:** 2026-10-16T08:34:30Z; **actualizado:** 2026-10-17T08:01:12Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [backend/castilla #90](../backend/castilla/issue-090-bulk-svc.md).

<details>
<summary>Contenido completo consultado del issue 90</summary>

> ## Estado
> POSTDEMO · NO BLOQUEA HITO DEMO. Sin owner activo; el owner histórico permanece en el historial.
>
> ## Alcance futuro único
> bulk-svc; MK-001 sigue mock. Este issue cubre únicamente etapa 3: Reglas/invariantes SPEC/HU. Preservar reglas de negocio/spec del bounded context y su prioridad posterior; no declararlo completado ni desplegarlo para esta demo.
>
> ## Aceptación
> Trabajo futuro testeado por commit, sin cambiar contratos compartidos incompatibles ni atribuir runtime. POSTDEMO hasta repriorización.
>
> ## Prerrequisitos obligatorios para programar
> - Ninguno para esta fase.
>
> ## Dependencias para pruebas de integración
> - Ninguno para esta fase.
>
> ## Condiciones para desplegar
> - Ninguno para esta fase.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.

</details>

## Issue 99

- **Título:** [BACK][inventory-svc][03] Implementar invariantes completas de Inventory
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/99).
- **Estado consultado:** open; **asignados:** @MiguelTacoZavala.
- **Creado:** 2026-10-16T08:35:25Z; **actualizado:** 2026-10-17T08:06:52Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [backend/taco #99](../backend/taco/issue-099-inventory-svc.md).

<details>
<summary>Contenido completo consultado del issue 99</summary>

> ## Estado y owner
> DEMO_P0 · REAL PARA DEMO. Owner único: MiguelTacoZavala. Área: backend/apps/inventory-svc; feature UI solo para integración.
>
> ## Trabajo ejecutable
> Implementar reglas/invariantes completas SPEC/HU/FLOW y pruebas de dominio.
>
> ## Reglas técnicas vigentes
> Saldo autoritativo por SKU/ubicación, reservas, Kardex, disponibilidad comercial minimizada e idempotencia según DEC-F/SPEC-015. No quitar InventoryAuthGuard global. PR #10 OPEN: preservar avances de reservas/Drizzle/Outbox.
>
> ## Aceptación
> Cambios limitados al servicio y sus pruebas; conservar reglas completas, contratos vigentes y errores explícitos. Evidencia asociada a commit; E2E con entorno real. No inferir implementación/homologación/despliegue.
>
> ## Prerrequisitos obligatorios para programar
> - Ninguno para esta fase.
>
> ## Dependencias para pruebas de integración
> - [Backend #97](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/97)
> - [Backend #98](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/98)
>
> ## Condiciones para desplegar
> - Ninguno para esta fase.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.
>
> ## Especificación técnica recuperada del respaldo anterior
> **Alcance técnico/operaciones:**
> Solo una ubicación elegible; faltante/ambigüedad da INDETERMINADO. No exponer saldo físico por rutas comerciales ni vender por consulta de disponibilidad; reservar en operación separada. Nunca saldo negativo; idempotencia/concurrencia/Kardex. Incidencias y recepciones afectan disponible solo por operación autorizada. Reintegro F3 tras recepción física y aptitud; discrepancias de traslado no alteran disponible.
>
> **Tareas:**
> - [ ] Convertir reglas de SPEC/HU en reglas puras o servicios del dominio.
> - [ ] Aplicar estados/versiones/idempotencia al límite definido por el modelo.
> - [ ] Probar límites positivos/negativos; registrar solo contradicciones que bloqueen una regla.
>
> **Criterios de aceptación:**
> - [ ] Cada regla de SPEC/HU citada tiene pruebas positivas, negativas y límite.
> - [ ] No se cruza ownership ni se inventan eventos/rutas/campos.
> - [ ] Los estados se transicionan de forma idempotente según la regla aprobada.
>
> **Pruebas obligatorias:**
> Unit tests de invariantes/estados límite/errores; fixtures solo en pruebas aisladas.
>
> **Trazabilidad específica de PR #10 (OPEN/DRAFT; head 2c4a18105c5e379edc8476b9d315aa6be1134b80):** Reserva/saldo/Kardex probados parcialmente; incidentes, traslado, F3/reintegro, offline y umbrales pendientes. Commits relacionados: 8a0204313fa6, 721fde7f5cb2, fb9f2ed042f9. Archivos: apps/inventory-svc/src/reservations/reservations.service.ts; apps/inventory-svc/src/disponibilidad/*; apps/inventory-svc/src/operations/*; apps/inventory-svc/src/kardex/*; apps/inventory-svc/src/idempotency/*. Pruebas: apps/inventory-svc/src/reservations/reservations.concurrency.spec.ts; apps/inventory-svc/src/reservations/reservations.cycle.spec.ts; apps/inventory-svc/src/disponibilidad/disponibilidad.spec.ts. Perspectiva del PR: no fusionado; revalidar contra diff/CI al ejecutar.

</details>

## Issue 106

- **Título:** [BACK][gateway][01] Implementar routing interno y límites
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/106).
- **Estado consultado:** open; **asignados:** @mrcastilla8.
- **Creado:** 2026-10-16T08:36:15Z; **actualizado:** 2026-10-17T08:00:39Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [backend/castilla #106](../backend/castilla/issue-106-api-gateway.md).

<details>
<summary>Contenido completo consultado del issue 106</summary>

> ## Estado y owner
> DEMO_P0 · Owner único: mrcastilla8
>
> ## Alcance ejecutable
> Audit routing integrated by PR #116 MERGED and finish only verifiable gaps: contract routes, allowlists, validation, timeout and defined correlation headers. No duplicate routing/no auth bypass.
>
> ## Aceptación
> Proxy tests by operationId, 404/405/timeouts, sanitization. Ninguna nota/PR/documento acredita por sí solo implementación, homologación, despliegue o prueba.
>
> ## Prerrequisitos obligatorios para programar
> - Ninguno para esta fase.
>
> ## Dependencias para pruebas de integración
> - Ninguno para esta fase.
>
> ## Condiciones para desplegar
> - Ninguno para esta fase.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.

</details>
