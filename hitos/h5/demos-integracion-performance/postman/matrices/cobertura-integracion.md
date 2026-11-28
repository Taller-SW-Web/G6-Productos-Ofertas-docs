# Matriz de Trazabilidad y Cobertura — Suite Postman/Newman G6 Hito 5

> **Nota normativa:** Esta matriz pertenece exclusivamente al paquete aislado de Postman/Newman y **no modifica** la matriz oficial del Hito 5 (`hitos/h5/07_MATRIZ_TRAZABILIDAD_Y_EVIDENCIAS.md`) ni la matriz de 158 operaciones (`hitos/h5/MATRIZ_158_OPERACIONES_H5_R2.csv`).

## Reconciliacion exacta de denominadores HTTP (H10)

| Universo | Cantidad | Composicion verificada |
|---|---:|---|
| OpenAPI canonico `0.7.0-rc.3` (`contratos/http/openapi.yaml`) | **156** | Operaciones HTTP contractuales (lectura + mutacion + internas) |
| APIM live (`apim-g6-productos-chile.azure-api.net`, `/api/v1`) | **145** | 156 OpenAPI menos 5 rutas internas G6→G6, 4 rutas G5 pendientes de publicacion en candidato #307 (149) y 2 lecturas admin Pricing excluidas |
| Matriz certificadora R2 (`MATRIZ_158_OPERACIONES_H5_R2.csv`) | **158** | 156 OpenAPI + 2 probes privados de Gateway (`/health/live`, `/health/ready`) |
| **Suite Postman/Newman (`G6 - H5 Integration Suite`)** | **38** | **38 solicitudes implementadas** (100% conciliadas con `CASE_METADATA` y [`cobertura-integracion.csv`](cobertura-integracion.csv)): 25 lectura segura + 10 negativos contractuales + 3 vistas de proveedor externo M2M |

- **Operaciones mutantes (`POST`/`PATCH`/`PUT`/`DELETE`) y mensajeria asincrona (Service Bus):** Excluidas intencionalmente del perfil ejecutable por defecto para no alterar datos compartidos de Supabase ni simular entregas asincronas. `INT-05` e `INT-10` requieren el harness especializado de Azure Service Bus en Backend.

## Resumen por microservicio (38 casos implementados)

| Microservicio propietario | Casos implementados (PM) | Total | Lectura | Negativos | Casos INT vinculados | Limite / Bloqueo principal |
|---|---|---:|---:|---:|---|---|
| API Gateway / APIM | `PM-001`, `PM-001B`, `PM-004`, `PM-004B`, `PM-005`, `PM-008` | 6 | 2 | 4 | INT-07 | `PM-001`/`001B` son probes privados de Gateway (403 en ACA directo Modalidad B); `PM-005` requiere `G6_RESTRICTED_ACCESS_TOKEN` (nunca aprueba con 401) |
| Catalog | `PM-002`, `PM-003A`, `PM-003B`, `PM-003C`, `PM-006`, `PM-007A`, `PM-007B`, `PM-010`, `PM-011`, `PM-080` | 10 | 7 | 3 | INT-01, INT-09 | Requiere `G6_ACCESS_TOKEN` (`userBearer`) o `G6_MARKETPLACE_ACCESS_TOKEN` (`PM-080`); DTOs estrictos `product_id`/`sku_base`/`variants` |
| Pricing | `PM-003D`, `PM-040`, `PM-041` (+ participacion en `PM-003A/B`) | 3 | 2 | 1 | INT-01, INT-05 | Requiere `G6_ACCESS_TOKEN`; valida DTO `Precio` (`precio_regular`, `precio_oferta`, `vigencia_id`, `origen`) |
| Inventory | `PM-012`, `PM-070`, `PM-071`, `PM-072`, `PM-081`, `PM-082` | 6 | 6 | 0 | INT-02, INT-09 | Solo lectura; `PM-081` usa `G6_MARKETPLACE_ACCESS_TOKEN` y `PM-082` usa `G6_VENTAS_ACCESS_TOKEN` |
| Taxonomy | `PM-050`, `PM-051`, `PM-052`, `PM-053`, `PM-054` | 5 | 4 | 1 | INT-06 | Parte HTTP de lectura; bajas R18 requieren harness Service Bus |
| Promotions | `PM-060`, `PM-061`, `PM-062` | 3 | 3 | 0 | INT-03 | Solo lectura; sin consumo ni restauracion de cupones |
| Combos | `PM-020`, `PM-021` | 2 | 1 | 1 | INT-01 | Requiere `G6_ACCESS_TOKEN` |
| Bulk | `PM-030`, `PM-031` | 2 | 1 | 1 | INT-04 | Solo lectura (plantilla CSV v2 y 404); sin iniciar importaciones |
| Price Audit | `PM-042` | 1 | 1 | 0 | INT-05 | Solo lectura historica; no modifica precios ni sustituye prueba Service Bus R16 |
| **Total conciliado** | **38 casos `PM-*`** | **38** | **27** | **11** | — | Validado automaticamente por `npm run validate` |

Para el detalle fila por fila (incluyendo `ID PM`, `ID INT`, endpoint, scope, nivel, estado y bloqueos), consulte [`cobertura-integracion.csv`](cobertura-integracion.csv).
