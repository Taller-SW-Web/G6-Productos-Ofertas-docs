-- Pricing admite precio global (channel_id NULL) y overrides por canal.
-- La clave natural sigue siendo SKU/canal; NULL representa global, no omisión.
ALTER TABLE promotions.price_projection
  DROP CONSTRAINT pk_price_projection,
  ALTER COLUMN channel_id DROP NOT NULL,
  ADD COLUMN id uuid NOT NULL DEFAULT gen_random_uuid(),
  ADD CONSTRAINT pk_price_projection PRIMARY KEY(id),
  ADD CONSTRAINT uq_price_projection_sku_channel UNIQUE NULLS NOT DISTINCT(sku,channel_id);
