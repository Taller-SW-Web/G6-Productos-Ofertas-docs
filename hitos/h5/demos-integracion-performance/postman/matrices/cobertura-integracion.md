# Matriz de Trazabilidad y Cobertura — Suite Postman/Newman G6 Hito 5

> **Nota normativa:** Esta matriz pertenece exclusivamente al paquete aislado de Postman/Newman y **no modifica** la matriz oficial del Hito 5 (`hitos/h5/07_MATRIZ_TRAZABILIDAD_Y_EVIDENCIAS.md`) ni la matriz de 158 operaciones (`hitos/h5/MATRIZ_158_OPERACIONES_H5_R2.csv`).

## Alcance y denominadores diferenciados

- **Operaciones totales del contrato OpenAPI `0.7.0-rc.3`:** 158 operaciones (incluyendo mutaciones `POST`/`PATCH`/`PUT`/`DELETE`, operaciones privadas internas no publicadas por Gateway y operaciones sujetas a feature flags o grants pendientes).
- **Operaciones de lectura/consulta cubiertas por esta suite Postman:** **38 solicitudes** distribuidas en los **8 microservicios** de G6 + **API Gateway** (25 de lectura segura + 13 casos negativos contractuales y vistas de proveedor externo).
- **Operaciones mutantes y mensajeria asincrona (Service Bus):** Excluidas intencionalmente del perfil ejecutable por defecto para no alterar datos compartidos de Supabase ni simular entregas asincronas. `INT-05` e `INT-10` requieren el harness especializado de Azure Service Bus en Backend.
- **Estado de APIM:** No existe instancia operativa de Azure API Management desplegada (`NOT_RUN_BLOCKED_INFRA`); las ejecuciones reales apuntan al **API Gateway ACA autorizado** (`api-gateway.calmgrass-aec0b33c.chilecentral.azurecontainerapps.io`).

## Resumen por microservicio

| Microservicio | Casos implementados (PM) | Lectura | Negativos | Casos INT vinculados | Limite / Bloqueo principal |
|---|---:|---:|---:|---|---|
| API Gateway | 6 (`PM-001`, `001B`, `004`, `004B`, `005`, `008`) | 2 | 4 | INT-07 | `PM-005` requiere token restringido G7; APIM en `NOT_RUN_BLOCKED_INFRA` |
| Catalog | 9 (`PM-002`, `003A`, `003B`, `003C`, `006`, `007A`, `007B`, `010`, `011`, `080`) | 6 | 3 | INT-01, INT-09 | Requiere JWT G7 valido (`G6_ACCESS_TOKEN` / `G6_SERVICE_ACCESS_TOKEN`); traza downstream Catalog→Pricing requiere telemetria Azure |
| Pricing | 3 (`PM-003D`, `040`, `041`) + participacion en `PM-003A/B` | 2 | 1 | INT-01, INT-05 | Requiere JWT G7 valido |
| Inventory | 6 (`PM-012`, `070`, `071`, `072`, `081`, `082`) | 6 | 0 | INT-02, INT-09 | Solo lectura; reservas/confirmaciones excluidas por proteccion de stock |
| Taxonomy | 5 (`PM-050`, `051`, `052`, `053`, `054`) | 4 | 1 | INT-06 | Parte HTTP de lectura; bajas R18 requieren harness Service Bus |
| Promotions | 3 (`PM-060`, `061`, `062`) | 3 | 0 | INT-03 | Solo lectura; sin consumo ni restauracion de cupones |
| Combos | 2 (`PM-020`, `021`) | 1 | 1 | INT-01 | Requiere JWT G7 valido |
| Bulk | 2 (`PM-030`, `031`) | 1 | 1 | INT-04 | Solo lectura (plantilla CSV v2 y 404); sin iniciar importaciones |
| Price Audit | 1 (`PM-042`) + `PM-005` | 1 | 0 | INT-05 | Solo lectura historica; no modifica precios ni sustituye prueba Service Bus R16 |

Para el detalle fila por fila (incluyendo `ID PM`, `ID INT`, endpoint, scope, nivel, estado y bloqueos), consulte [`cobertura-integracion.csv`](cobertura-integracion.csv).
