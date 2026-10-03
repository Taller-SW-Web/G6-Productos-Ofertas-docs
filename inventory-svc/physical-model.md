# Physical Model – inventory‑svc

## Tables

### `stock_balance`
- `sku_id` **PK** – UUID
- `location_id` – UUID (FK to `location`)
- `on_hand` – integer, default 0
- `reserved` – integer, default 0
- `blocked` – integer, default 0
- `available` – generated: `GREATEST(on_hand - reserved - blocked, 0)`
- `threshold` – integer, nullable
- `updated_at` – timestamp with time zone, default `NOW()`

### `reservations`
- `id` **PK** – UUID
- `order_id` – UUID (reference to order context)
- `status` – enum (`created`, `consumed`, `released`, `expired`)
- `created_at` – timestamp
- `expires_at` – timestamp (optional)

### `reservation_lines`
- `reservation_id` **FK** → `reservations.id`
- `sku_id` **FK** → `stock_balance.sku_id`
- `quantity` – integer, >0
- Composite PK (`reservation_id`, `sku_id`)

### `inventory_operations`
- `id` **PK** – UUID
- `type` – enum (`adjust`, `consumption`, `release`, `expiration`)
- `sku_id` – FK
- `location_id` – FK
- `quantity` – integer (positive or negative)
- `created_at` – timestamp

### `kardex`
- Audit log of all inventory movements
- Columns: `id`, `operation_id`, `sku_id`, `location_id`, `quantity_before`, `quantity_after`, `timestamp`

## Constraints & Indexes
- Unique index on (`sku_id`, `location_id`) in `stock_balance`
- Check constraints to ensure `available >= 0`
- Indexes on `reservations.status`, `inventory_operations.type` for fast queries

*This file is a high‑level description; the concrete DDL is in `migration.sql`.*
