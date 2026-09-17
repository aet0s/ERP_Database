-- 022_add_dispatch_fields_to_pos.sql
-- Adds dispatch_tracking_ref and dispatch_date columns to purchase_orders table

ALTER TABLE purchase_orders ADD COLUMN IF NOT EXISTS dispatch_tracking_ref VARCHAR(255) NULL;
ALTER TABLE purchase_orders ADD COLUMN IF NOT EXISTS dispatch_date DATETIME NULL;
