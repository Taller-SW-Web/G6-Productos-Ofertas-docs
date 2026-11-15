# Benchmark sintético de Pricing G6 — 2026-11-14

## Reproducibilidad

- Backend SHA: `e572723c7e4cc278fd4405b8bfeef050de3eed7e`.
- GitHub Actions run: [43644256265](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43644256265), job `Medir lotes de Pricing con PostgreSQL desechable`; 3 pruebas PASS.
- Artefacto `pricing-batch-benchmark-e572723c7e4cc278fd4405b8bfeef050de3eed7e`, retención de 7 días.
- PostgreSQL 16 desechable, pool de Pricing max 2, fixture HTTP loopback de Catálogo con 4 ms de latencia añadida, timeout de consultas 2 s. Cada caso de equivalencia tiene 100 muestras y assert de igualdad de respuesta.
- Incluye canales `MARKETPLACE`, `CHATBOT`, `RETAIL`, `VENTAS`, SKU 1/20/100, duplicados, variantes, override/global, históricas, ausencia y error 503.

## Comparación legacy individual → lote nuevo

Los percentiles son milisegundos p50/p95/p99. Las solicitudes son llamadas de contexto a Catálogo; los SELECT corresponden al acceso de Pricing.

| Canal | SKU | Solicitudes legacy → lote | SELECT legacy → lote | p50 ms legacy → lote | p95 ms legacy → lote | p99 ms legacy → lote |
|---|---:|---:|---:|---:|---:|---:|
| MARKETPLACE | 1 | 1 → 1 | 1 → 1 | 6.03 → 6.23 | 6.48 → 7.01 | 8.17 → 9.23 |
| MARKETPLACE | 20 | 20 → 1 | 38 → 2 | 121.43 → 7.16 | 129.41 → 7.83 | 135.09 → 8.01 |
| MARKETPLACE | 100 | 100 → 1 | 194 → 2 | 599.09 → 9.62 | 618.59 → 10.53 | 645.13 → 13.96 |
| CHATBOT | 1 | 1 → 1 | 1 → 1 | 5.43 → 5.59 | 5.57 → 5.77 | 5.62 → 6.02 |
| CHATBOT | 20 | 20 → 1 | 38 → 2 | 117.11 → 6.93 | 122.79 → 7.20 | 124.14 → 7.71 |
| CHATBOT | 100 | 100 → 1 | 194 → 2 | 589.29 → 9.40 | 597.91 → 9.96 | 604.81 → 13.26 |
| RETAIL | 1 | 1 → 1 | 1 → 1 | 5.35 → 5.46 | 5.54 → 5.59 | 5.68 → 5.65 |
| RETAIL | 20 | 20 → 1 | 38 → 2 | 117.17 → 6.84 | 121.30 → 7.33 | 123.87 → 7.98 |
| RETAIL | 100 | 100 → 1 | 194 → 2 | 587.97 → 9.31 | 597.52 → 11.92 | 669.92 → 13.65 |
| VENTAS | 1 | 1 → 1 | 1 → 1 | 5.38 → 5.52 | 5.57 → 5.71 | 5.69 → 5.72 |
| VENTAS | 20 | 20 → 1 | 38 → 2 | 117.39 → 6.83 | 122.12 → 7.24 | 123.85 → 10.34 |
| VENTAS | 100 | 100 → 1 | 194 → 2 | 587.29 → 9.34 | 594.20 → 10.35 | 605.00 → 13.08 |

## Calibración de concurrencia en 100 SKU

El fixture individual de Catálogo se midió con 100 muestras por nivel. No se observaron más solicitudes simultáneas que el límite configurado.

| Concurrencia | Observada máxima | p50 ms | p95 ms | p99 ms |
|---:|---:|---:|---:|---:|
| 1 | 1 | 443.98 | 452.83 | 454.99 |
| 2 | 2 | 236.19 | 245.83 | 261.55 |
| 4 | 4 | 126.02 | 136.44 | 155.97 |
| 8 | 8 | 77.06 | 85.85 | 109.00 |
| 16 | 16 | 49.35 | 60.51 | 69.05 |

La medición demuestra el coste de latencia secuencial del cliente contra un fixture controlado; no somete el controller batch real de Catálogo a esa concurrencia, ni captura pool/conexiones de Catálogo/Gateway. Por ello no prueba que 16 sea un límite productivo seguro. La decisión de usar el endpoint batch reduce el fan-out normal a una llamada; cualquier límite de concurrencia del fallback individual requiere medición contra un Catalog provider con pool representativo antes de cambiarse.

## EXPLAIN (ANALYZE, BUFFERS)

Las dos consultas candidatas para 100 SKU / RETAIL se ejecutaron con PostgreSQL real desechable:

| Relación | Plan | Filas | Tiempo ejecución ms | Shared hit | Shared read |
|---|---|---:|---:|---:|---:|
| `prices` | Seq Scan | 98 | 0.136 | 3 | 0 |
| `price_validities` | Seq Scan | 98 | 0.177 | 8 | 0 |

Estos planes son de una fixture sintética de 98 filas por relación; no sustentan cambios de índices ni predicen planes con cardinalidad productiva. El benchmark no mide bytes HTTP, throughput concurrente sostenido ni p50/p95/p99 de Gateway/Azure. No extrapolar al entorno productivo.
