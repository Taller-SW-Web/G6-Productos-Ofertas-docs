# Matriz de k6 H5

Los comandos y la cobertura ejecutable están en [Backend, `scripts/h5/k6/`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/829b51aa69d03201d59b5e99e2e3e08a63810090/scripts/h5/k6/README.md). Los responsables y criterios oficiales se mantienen en [H5-03](../03_PRUEBAS_DE_PERFORMANCE.md).

| Caso · responsable | Cobertura | Evidencia y límite |
|---|---|---|
| PERF-01 · Poma | `listarProductos`, paginación y orden; oráculo y fixture canónicos de Catálogo. | k6 ejecutado en loopback contra el fixture HTTP. Scope `L1_FIXTURE_SINTETICO`. |
| PERF-02 · Vera | `obtenerPrecioSku` con controlador, guard, JWKS de prueba y resolución de precios de Pricing. | k6 ejecutado contra Nest en loopback, con Catálogo y precios controlados. Scope `L1_NEST_FIXTURES`. |
| PERF-03 · Taco | `consultarDisponibilidadComercial` con módulo/guard de Inventario, fixture DB y grupos del manifiesto canónico. | k6 ejecutado contra Nest en loopback con disponible, agotado e indeterminado. El script canónico conserva su cobertura GET/POST informativa ponderada. |
| PERF-04 · Axel | Admisión idempotente N01. | Se conserva su arnés. La ejecución depende del manifiesto efectivo y de autorización de escritura en base descartable. |
| PERF-05 · Axel | Throughput y drenaje Service Bus. | Se conserva la evidencia del harness SDK. |
| PERF-06 · Poma | Recorridos de navegador. | Se conserva la evidencia de Playwright. |
| PERF-07 · Castilla | Importación Bulk y efectos terminales. | Se conserva su arnés. |
| PERF-08 · Castilla | Comparar APIM con origen privado equivalente. | Pendiente de ambos orígenes autorizados y un par comparable. |
| RL-01–06 · responsables por regla | Límites, cuota, recuperación, aislamiento y no duplicación. | Pendiente de política, ventana, capacidades y verificación de IDs contra el arnés APIM vigente. |

Los perfiles de 5 y 20 VU se verificaron con `k6 inspect`. Una corrida en APIM necesita manifest efectivo, permisos G7, ventana aprobada y datos sintéticos. La comparación formal exige tres repeticiones por sujeto y perfil, telemetría y condiciones comparables. La integración con CI espera el merge de Backend #310. Ninguna corrida local certifica H5-03.
