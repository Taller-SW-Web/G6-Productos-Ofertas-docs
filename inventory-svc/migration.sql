-- Migration script for inventory‑svc

-- Table: stock_balance
CREATE TABLE IF NOT EXISTS stock_balance (
    sku_id UUID NOT NULL,
    location_id UUID NOT NULL,
    on_hand INTEGER NOT NULL DEFAULT 0,
    reserved INTEGER NOT NULL DEFAULT 0,
    blocked INTEGER NOT NULL DEFAULT 0,
    available INTEGER GENERATED ALWAYS AS (GREATEST(on_hand - reserved - blocked, 0)) STORED,
    threshold INTEGER,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (sku_id, location_id)
);

-- Table: reservations
CREATE TABLE IF NOT EXISTS reservations (
    id UUID PRIMARY KEY,
    order_id UUID NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('created','consumed','released','expired')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

-- Table: reservation_lines
CREATE TABLE IF NOT EXISTS reservation_lines (
    reservation_id UUID NOT NULL REFERENCES reservations(id) ON DELETE CASCADE,
    sku_id UUID NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (reservation_id, sku_id)
);

-- Table: inventory_operations
CREATE TABLE IF NOT EXISTS inventory_operations (
    id UUID PRIMARY KEY,
    type TEXT NOT NULL CHECK (type IN ('adjust','consumption','release','expiration')),
    sku_id UUID NOT NULL,
    location_id UUID NOT NULL,
    quantity INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table: kardex (audit log)
CREATE TABLE IF NOT EXISTS kardex (
    id UUID PRIMARY KEY,
    operation_id UUID NOT NULL REFERENCES inventory_operations(id),
    sku_id UUID NOT NULL,
    location_id UUID NOT NULL,
    quantity_before INTEGER NOT NULL,
    quantity_after INTEGER NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for fast look‑ups
CREATE INDEX IF NOT EXISTS idx_reservations_status ON reservations(status);
CREATE INDEX IF NOT EXISTS idx_inventory_operations_type ON inventory_operations(type);
