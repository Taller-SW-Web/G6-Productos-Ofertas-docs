-- Validation script for inventory‑svc

-- Verify that available stock never goes negative
SELECT sku_id, location_id, available
FROM stock_balance
WHERE available < 0;

-- Verify that reserved quantity does not exceed on_hand
SELECT sb.sku_id, sb.location_id, sb.reserved, sb.on_hand
FROM stock_balance sb
WHERE sb.reserved > sb.on_hand;

-- Verify that each reservation line references an existing reservation
SELECT rl.*
FROM reservation_lines rl
LEFT JOIN reservations r ON rl.reservation_id = r.id
WHERE r.id IS NULL;

-- Verify that each reservation line references an existing stock_balance entry
SELECT rl.*
FROM reservation_lines rl
LEFT JOIN stock_balance sb ON rl.sku_id = sb.sku_id
WHERE sb.sku_id IS NULL;

-- Verify that inventory_operations quantity correctly updates stock_balance (simple check)
-- This is a placeholder; in real deployment you would compare before/after values.
