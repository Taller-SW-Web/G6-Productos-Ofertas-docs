# Modelo lógico — `inventory` (`inventory-svc`)

- **Issue:** #54 — Modelo lógico para inventory-svc
- **Responsable:** Marco
- **Bounded context:** inventory
- **Microservicio:** inventory-svc
- **Schema objetivo:** inventory
- **Última actualización:** 2026-10-03
- **Estado:** APROBADO

## Fuentes

Este modelo deriva de las fuentes funcionales, arquitectónicas y contractuales vigentes.

Revisar como mínimo, según corresponda:

- `Modelo_Conceptual.md`
- `Arquitectura.md`
- `Contrato_Api.md`
- OpenAPI vigente
- AsyncAPI vigente
- SPEC asociadas
- HU asociadas
- WF asociados
- FLOW asociados
- convenciones comunes de base de datos
- decisiones inter-módulo aplicables

---

## 1. Propósito

Describir la estructura lógica de información propiedad del bounded context `inventory`.

Este documento define:

- entidades lógicas;
- atributos relevantes;
- identificadores;
- relaciones;
- cardinalidades;
- reglas de integridad;
- referencias a otros bounded contexts;
- datos derivados o proyectados;
- necesidades de persistencia técnica cuando correspondan.

Este documento **no define todavía la implementación PostgreSQL**.

---

## 2. Responsabilidad del bounded context

### 2.1. Datos propios

El bounded context es autoridad sobre:

- `stock_balance`
- `reservations`
- `reservation_lines`
- `inventory_operations`
- `kardex`
- `outbox`
- `inbox`
- `stock_threshold_override`
- `dashboard_projection`
- `incidencias`
- `traslados`
- `traslado_recepciones`

### 2.2. Datos que NO posee

No es autoridad sobre:

- `catalog-svc` datos como `product`, `sku` (referenciados)
- `ventas-svc` datos de órdenes

Las referencias externas se mantienen únicamente como claves contractuales.

---

## 3. Entidades lógicas

### 3.1. `stock_balance`

**Propósito:** Mantener el estado físico del inventario por SKU y ubicación.

**Identificador lógico:** (`sku_id`, `location_id`)

#### Atributos

| Atributo | Naturaleza lógica | Obligatorio | Descripción |
|---|---|---:|---|
| `sku_id` | Referencia externa | Sí | Identificador del producto (propiedad de catalog-svc) |
| `location_id` | Referencia externa | Sí | Identificador de la ubicación (propiedad de inventory-svc) |
| `on_hand` | Número entero | Sí | Cantidad disponible sin reservas ni bloqueos |
| `reserved` | Número entero | Sí | Cantidad reservada para pedidos |
| `blocked` | Número entero | Sí | Cantidad bloqueada por incidencias |
| `stock_version` | Número entero | Sí | Versión para control de concurrencia |
| `created_at` | Fecha/hora | Sí | Timestamp de creación |
| `updated_at` | Fecha/hora | Sí | Timestamp de última actualización |

#### Reglas

- CHECK (`on_hand` >= 0)
- CHECK (`reserved` >= 0)
- CHECK (`blocked` >= 0)
- CHECK (`reserved` + `blocked` <= `on_hand`)

---

### 3.2. `reservations`

**Propósito:** Punto de entrada para reservar stock.

**Identificador lógico:** `reservation_id`

#### Atributos

| Atributo | Naturaleza lógica | Obligatorio | Descripción |
|---|---|---:|---|
| `reservation_id` | UUID | Sí | Identificador único de la reserva |
| `expires_at` | timestamptz | Sí | Fecha límite de expiración |
| `idempotency_key` | text | Sí | Clave para garantizar idempotencia |
| `status` | text | Sí | Estado (`EXPIRADA`, `CONSUMIDA`, etc.) |
| `created_at` | timestamptz | Sí | Timestamp de creación |
| `updated_at` | timestamptz | Sí | Timestamp de última actualización |

#### Reglas

- UNIQ (`idempotency_key`)
- CHECK (`status` IN ('PENDIENTE','EXPIRADA','CONSUMIDA'))

---

## 4. Catálogos de estados y valores controlados

### 4.1. `reservation_status`

Valores:

```text
PENDIENTE
EXPIRADA
CONSUMIDA
```

---

## 5. Relaciones y cardinalidades

| Origen | Relación | Destino | Cardinalidad | Propiedad |
|---|---|---|---:|---|
| `reservations` | `1:N` | `reservation_lines` | 1:N | Interna |
| `stock_balance` | `N:1` | `sku` (catalog-svc) | N:1 | Externa, sin ownership |
| `stock_balance` | `N:1` | `location` (inventory-svc) | N:1 | Interna |

---

## 6. Referencias interdominio

Las referencias hacia otros bounded contexts **no transfieren ownership**.

| Referencia | Owner | Uso local | ¿FK cross-context? |
|---|---|---|---:|
| `product_id` | catalog-svc | Identificar producto en stock | No |
| `sku_id` | catalog-svc | Identificar SKU en reservaciones | No |

---

## 7. Reglas de integridad lógica

- `stock_balance` debe existir antes de crear una `reservation_line`.
- No se permite crear reservas para `sku_id` inexistente.
- La suma de `reserved` y `blocked` nunca supera a `on_hand`.

---
