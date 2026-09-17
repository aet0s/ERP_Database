-- 018_add_deleted_at_to_purchase_orders.sql
ALTER TABLE purchase_orders ADD COLUMN IF NOT EXISTS deleted_at DATETIME NULL;
