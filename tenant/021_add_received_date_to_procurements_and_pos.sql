-- 021_add_received_date_to_procurements_and_pos.sql
-- Adds received_date column to procurements and purchase_orders tables

ALTER TABLE procurements ADD COLUMN IF NOT EXISTS received_date DATETIME NULL;
ALTER TABLE purchase_orders ADD COLUMN IF NOT EXISTS received_date DATETIME NULL;
