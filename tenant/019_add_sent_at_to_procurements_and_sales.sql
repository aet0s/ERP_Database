-- 019_add_sent_at_to_procurements_and_sales.sql
ALTER TABLE procurements ADD COLUMN IF NOT EXISTS sent_at DATETIME NULL;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS sent_at DATETIME NULL;
