# Inventario y estado de k6

Revisión de referencia. Backend `36f619da6c44a3c14b93917d1fddf2d09bd569db`, Frontend `2c6ad931b8dd48e4a4fe883a18ac899fb48b0c81` y Docs `5f30802129ba4bbc0674dcc5878f10065f443118`. Los estados de publicación, grants y ambientes se verifican para la revisión ejecutada. El manifiesto candidato G5 del Backend consultado es de preparación y no acredita despliegue ni activación de N01.

| Caso y owner | Contrato, datos y referencia Backend | Entrega y estado |
|---|---|---|
| PERF-01 · Poma | `GET /api/v1/productos`, `listarProductos`, bearer con `catalogo:leer` para el cliente habilitado. Canal, páginas e IDs sintéticos en orden estable. Referencias `apps/catalog-svc/test/performance/h5/catalog-pagination.k6.js` y `scripts/run-h5-perf01-k6-smoke.mjs`. | P1. Script y wrapper independientes. `PASS` en fixture HTTP L1. Azure `NOT_RUN` hasta confirmar revisión, ventana, token, dataset y origen autorizados. |
| PERF-02 · Vera | `GET /api/v1/precios/skus/{sku}`, `obtenerPrecioSku`, bearer de prueba con `precios:leer` o identidad de usuario autorizada según contrato. SKU sintético y canal. | P2. Lectura preparada. Ejecución HTTP `NOT_RUN` hasta verificar publicación y grant. Las métricas de k6 describen el extremo a extremo HTTP. La atribución a Pricing requiere telemetría del servidor. |
| PERF-03 · Taco | `GET /api/v1/inventario/disponibilidad/comercial`, `consultarDisponibilidadComercial`, `serviceBearer` con `inventario:disponibilidad:leer` y cliente/canal permitidos. Mezcla de SKU sintéticos disponibles y no disponibles. Referencia `scripts/h5/performance/inventory-availability.k6.js`. | P2. Lectura preparada sin reserva ni escritura. Ejecución HTTP `NOT_RUN` hasta verificar publicación, grant y dataset. |
| PERF-04 · Axel | `apps/promotions-svc/test/performance/coupon-admission.k6.js`. N01, identidad aprobada, idempotencia y base descartable. | Depende del manifiesto efectivo. Si excluye N01, `OUT_OF_SCOPE`. Si lo incluye, falta autorización de escritura y ambiente descartable. La demo no envía escrituras. |
| PERF-05 · Axel | Service Bus, SDK y métricas de backlog/drenaje. | Evidencia del harness de Service Bus; fuera del runner HTTP. |
| PERF-06 · Poma | Recorridos de navegador y tiempos UI. | Evidencia de Playwright; fuera del runner HTTP. |
| PERF-07 · Castilla | Bulk y efectos terminales de importación. | Evidencia del harness Bulk; fuera de la demo de lectura. |
| PERF-08 · Castilla | APIM y origen privado de control, misma operación, datos, backend, región y recursos. | P3/P4 `NOT_RUN`. Falta ruta privada autorizada y par comparable. |
| RL-01–06 · owners por regla | Política efectiva APIM y `ops/azure/apim/tests/apim-rl-k6.js`. | P4 `NOT_RUN`. Falta autorización de ventana/capacidad, manifest/política efectivos e identidades de test. |

P3 dispone de wrapper y comparador por caso/perfil. Sin los seis sujetos medidos y su telemetría, el veredicto es `INCONCLUSIVE`. El resultado del fixture acredita el flujo de demostración y la validación HTTP sintética. El resultado `PASS` de una sola corrida describe únicamente esa corrida.

## P4 y coordinación con CI

1. Castilla e Infra confirman políticas, SKU, orígenes, ventana, costos y límites efectivos. G7 confirma identidades/grants. Revisa la [normativa APIM](../04_API_MANAGEMENT.md) y las reglas en [la normativa de performance](../03_PRUEBAS_DE_PERFORMANCE.md).
2. Tras estabilizar Backend #310 y Frontend #103, Vera y los responsables verifican el SHA del arnés compartido. Lee sus guardas y `options` en ese SHA antes de invocarlo. Confronta los IDs de los checks existentes con los IDs normativos: cuota, concurrencia y aislamiento aparecen rotulados de forma distinta en algunos checks del arnés consultado.
3. Usa el arnés de APIM que mantiene el equipo, su manifiesto y parámetros efectivos. Registra admitidas, rechazadas, `Retry-After` y recuperación según la política observada. Un rechazo autorizado por cuota no tiene por qué ser 429. Reutiliza el dashboard nativo de k6 para la exposición y telemetría de Gateway/servicio para correlacionar solicitudes.
4. PERF-08 requiere una ruta privada de control aprobada y recursos equivalentes. Picos 5→50→5, estrés 10→20→50 y resistencia quedan como protocolos opt-in. Cada uno necesita presupuesto, límite de parada, política y ventana confirmados antes de preparar su invocación. No se configuran como perfiles ejecutables por defecto.
