# Reporte de Pruebas de Integracion HTTP — G6 Hito 5

- **Run ID:** `azure-apim-integration-jws-2026-11-28`
- **Fecha UTC:** `2026-11-28T05:03:29.930Z`
- **Entorno:** `azure-apim-chile` (`https://apim-g6-productos-chile.azure-api.net`)
- **Perfil:** `integration`
- **Veredicto global:** **`FAIL`**
- **Nivel de evidencia:** `LAB_AZURE`
- **Estado de despliegue:** `APIM_LIVE_145_OPS`
- **Contrato OpenAPI:** `0.7.0-rc.3`
- **Node.js / Newman:** `24.16.0` / `6.2.3`
- **SHA Docs (local):** `769fac059c1ca2543fd57b639bbd5a18d2a7dc5c`
- **SHA Backend (local, solo lectura):** `36f619da6c44a3c14b93917d1fddf2d09bd569db`
- **SHA Frontend (local, solo lectura):** `2c6ad931b8dd48e4a4fe883a18ac899fb48b0c81`
- **SHA-256 Coleccion:** `de0f6d6345168f46256b89ee77d680b96f19971e0789c5379139d9a43a37d961`

## Resumen y reconciliacion de ejecucion

| Metrica | Valor |
|---|---:|
| Casos planificados | 36 |
| Casos ejecutados en Newman | 33 |
| PASS | 27 |
| FAIL | 5 |
| INCONCLUSIVE | 0 |
| NOT_RUN | 4 |
| Aserciones totales | 33 |
| Aserciones aprobadas | 28 |
| Aserciones fallidas | 5 |
| Duracion total (ms) | 19101 |

## Resultados por caso

| ID PM | ID INT | Caso | Metodo | HTTP | Aserciones | Duracion (ms) | Correlation ID | Estado | Bloqueo / Nota |
|---|---|---|---|---:|---:|---:|---|---|---|
| PM-002 | INT-01 | PM-002 - Gateway -> Catalog: Listar productos autorizados | GET | 200 | 1/1 | 660 | `df6a4842-0628-49ac-a63c-723fe53d0f9b` | **PASS** | - |
| PM-003A | INT-01 | PM-003A - Catalog -> Pricing: Filtro por rango de precio amplio (con paginacion completa) | GET | 200 | 1/1 | 1109 | `c47a643b-07eb-4ce5-a9fc-e08c9481315a` | **PASS** | - |
| PM-003B | INT-01 | PM-003B - Catalog -> Pricing: Filtro rango acotado y relacion de subconjunto estricta | GET | 200 | 2/2 | 993 | `db350c18-71b1-46b0-a187-57db90b27258` | **PASS** | - |
| PM-003C | INT-01 | PM-003C - Catalog: Detalle comercial y extraccion de todos los SKUs elegibles | GET | 200 | 1/1 | 754 | `e083df56-be8f-439d-a320-e858002f6112` | **PASS** | - |
| PM-003D | INT-01 | PM-003D - Pricing: Consultar precios efectivos de todos los SKUs elegibles del producto | GET | 200 | 1/1 | 470 | `b93a17cc-f87f-444e-a4b9-b2a109012e1d` | **PASS** | - |
| PM-010 | INT-01 | PM-010 - Catalog: Estado de preparacion del producto | GET | 200 | 1/1 | 405 | `e687bdb1-d60e-4163-ae70-d6906b29b6b1` | **PASS** | - |
| PM-011 | INT-01 | PM-011 - Catalog: Listar variantes de producto | GET | 200 | 1/1 | 657 | `47deea43-a2fe-4526-a6bd-9d9ac93a14ac` | **PASS** | - |
| PM-012 | INT-02 | PM-012 - Inventory: Disponibilidad autoritativa por SKU encadenado | GET | 400 | 0/1 | 170 | `fa7bbf89-19eb-4713-ac88-5c9ad91e95e7` | **FAIL** | - |
| PM-020 | INT-01 | PM-020 - Combos: Listar combos administrativos | GET | 200 | 1/1 | 1244 | `d509ecd1-cfab-4503-a473-d5991cf1a8d2` | **PASS** | - |
| PM-021 | INT-01 | PM-021 - Combos: Negativo combo inexistente (404) | GET | 404 | 1/1 | 272 | `c36d4632-8ae7-45c9-a2b9-fcbe3f3d137d` | **PASS** | - |
| PM-030 | INT-04 | PM-030 - Bulk: Descargar plantilla CSV v2 | GET | 401 | 0/1 | 254 | `5f844a46-4258-49ff-aaec-2303d2b52cc2` | **FAIL** | - |
| PM-031 | INT-04 | PM-031 - Bulk: Negativo lote de importacion inexistente (404) | GET | 401 | 0/1 | 46 | `bedaa5f8-dba5-4b79-a2ec-5c415bc335cd` | **FAIL** | - |
| PM-040 | INT-05 | PM-040 - Pricing: Obtener precio vigente por SKU | GET | 200 | 1/1 | 783 | `f21dde7f-a754-487f-a17a-153d59bea89e` | **PASS** | - |
| PM-041 | INT-05 | PM-041 - Pricing: Negativo SKU inexistente (404) | GET | 404 | 1/1 | 242 | `74bae6c6-196b-4714-a07b-26524545a62b` | **PASS** | - |
| PM-042 | INT-05 | PM-042 - Price Audit: Consultar historial de auditoria de precios | GET | 200 | 1/1 | 1880 | `edd99929-62a4-420b-a0fa-1e6eccce5e6d` | **PASS** | - |
| PM-050 | INT-06 | PM-050 - Taxonomy: Listar categorias (administracion) | GET | 200 | 1/1 | 402 | `6e388c3f-11f3-4dfc-a48f-dcff25e24063` | **PASS** | - |
| PM-051 | INT-06 | PM-051 - Taxonomy: Listar marcas (administracion) | GET | 200 | 1/1 | 373 | `d0887ae7-9976-4f21-a2d8-bb069f0daf36` | **PASS** | - |
| PM-052 | INT-06 | PM-052 - Taxonomy: Obtener arbol de categorias | GET | 200 | 1/1 | 684 | `8c234e2d-d764-4dee-a297-7fa6dcba583e` | **PASS** | - |
| PM-053 | INT-06 | PM-053 - Taxonomy: Listar tipos de producto | GET | 200 | 1/1 | 482 | `74a579cb-55ac-4cd1-af8c-a3f7f869d8b8` | **PASS** | - |
| PM-054 | INT-06 | PM-054 - Taxonomy: Negativo categoria inexistente (404) | GET | 404 | 1/1 | 376 | `921d9719-0aa4-4244-a49f-2753ba46f753` | **PASS** | - |
| PM-060 | INT-03 | PM-060 - Promotions: Listar promociones vigentes por canal | GET | 200 | 1/1 | 885 | `0fcac911-5a03-4289-a2ba-c25d733dbbe2` | **PASS** | - |
| PM-061 | INT-03 | PM-061 - Promotions: Listar promociones (administracion) | GET | 200 | 1/1 | 670 | `f1841280-2a9f-4013-aced-9c96084357fb` | **PASS** | - |
| PM-062 | INT-03 | PM-062 - Promotions: Listar cupones (solo lectura) | GET | 200 | 1/1 | 466 | `6992ffab-6dd4-4820-a95e-ae7ab7ab83a6` | **PASS** | - |
| PM-070 | INT-02 | PM-070 - Inventory: Consultar umbrales de inventario | GET | 200 | 1/1 | 121 | `4fb9cc97-7669-4bfe-a46f-e951af32a317` | **PASS** | - |
| PM-071 | INT-02 | PM-071 - Inventory: Consultar dashboard operativo | GET | 200 | 1/1 | 207 | `ffb2e001-2bc2-47c5-af97-13667e494315` | **PASS** | - |
| PM-072 | INT-02 | PM-072 - Inventory: Listar ubicaciones de inventario | GET | 200 | 1/1 | 328 | `d05b9d8b-cbff-49a8-ae4e-891d5ec62924` | **PASS** | - |
| PM-004 | INT-07 | PM-004 - Negativo: Solicitud sin autenticacion (401) | GET | 401 | 0/1 | 37 | `11ec7f75-db43-4597-a17a-a5ed506382c8` | **FAIL** | - |
| PM-004B | INT-07 | PM-004B - Negativo: Token malformado o invalido (401) | GET | 401 | 0/1 | 38 | `4c7d28be-a770-4056-a6f2-a6eb65a31f95` | **FAIL** | - |
| PM-005 | INT-07 | PM-005 - Negativo: Autorizacion insuficiente (403 estricto) | GET | - | 0/0 | 0 | `-` | **NOT_RUN** | BLOCKED_AUTH: Requiere G6_RESTRICTED_ACCESS_TOKEN (identidad autenticada sin permiso para validar 403). |
| PM-006 | INT-01 | PM-006 - Negativo: Recurso inexistente (404) | GET | 404 | 1/1 | 237 | `bd89fd92-52cb-48a6-ae7d-ec64dda3d7ad` | **PASS** | - |
| PM-007A | INT-01 | PM-007A - Negativo: Rango de precios inconsistente (precioMin > precioMax) | GET | 400 | 1/1 | 44 | `48d41407-282e-42f4-ad6e-b90c87f545ff` | **PASS** | - |
| PM-007B | INT-01 | PM-007B - Negativo: Canal y paginacion invalidos (400) | GET | 400 | 1/1 | 49 | `6fe5f170-fd44-4a40-a0cf-d387baa103a6` | **PASS** | - |
| PM-008 | INT-07 | PM-008 - Negativo: Ruta desconocida en APIM/Gateway (404) | GET | 404 | 1/1 | 40 | `ec48d078-896c-4d3f-b5ba-25cc173cb01f` | **PASS** | - |
| PM-080 | INT-09 | PM-080 - Proveedor G6 para G1 Marketplace: Listar productos (modulo-marketplace) | GET | - | 0/0 | 0 | `-` | **NOT_RUN** | BLOCKED_AUTH: Requiere G6_MARKETPLACE_ACCESS_TOKEN (serviceBearer modulo-marketplace). |
| PM-081 | INT-09 | PM-081 - Proveedor G6 para G1 Marketplace: Disponibilidad comercial (modulo-marketplace) | GET | - | 0/0 | 0 | `-` | **NOT_RUN** | BLOCKED_AUTH: Requiere G6_MARKETPLACE_ACCESS_TOKEN (serviceBearer modulo-marketplace). |
| PM-082 | INT-09 | PM-082 - Proveedor G6 para G5 Ventas: Disponibilidad autoritativa (modulo-ventas) | GET | - | 0/0 | 0 | `-` | **NOT_RUN** | BLOCKED_AUTH: Requiere G6_VENTAS_ACCESS_TOKEN (serviceBearer modulo-ventas). |

## Detalle de fallos

### PM-012 — PM-012 - Inventory: Disponibilidad autoritativa por SKU encadenado
- Asercion fallida: **PM-012: HTTP 200, JSON Schema DisponibilidadStock e invariante de stock** — `expected response to have status code 200 but got 400`

### PM-030 — PM-030 - Bulk: Descargar plantilla CSV v2
- Asercion fallida: **PM-030: HTTP 200, text/csv y cabeceras presentes** — `expected response to have status code 200 but got 401`

### PM-031 — PM-031 - Bulk: Negativo lote de importacion inexistente (404)
- Asercion fallida: **PM-031: HTTP 404 Problem Details** — `expected response to have status code 404 but got 401`

### PM-004 — PM-004 - Negativo: Solicitud sin autenticacion (401)
- Asercion fallida: **PM-004: HTTP 401 Problem Details TOKEN_INVALIDO sin fuga** — `PM-004 requiere title: expected {[BODY_REDACTED]} to have property 'title'`

### PM-004B — PM-004B - Negativo: Token malformado o invalido (401)
- Asercion fallida: **PM-004B: HTTP 401 Problem Details TOKEN_INVALIDO sin fuga** — `PM-004B requiere title: expected {[BODY_REDACTED]} to have property 'title'`


## Bloqueos y advertencias

- Ejecucion parcial (FAIL): 4 de 36 casos planificados quedaron NOT_RUN.
