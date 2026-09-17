-- 014_sales_order_workflow.sql
-- Adds order status, dispatch, and delivery tracking columns to sales table

ALTER TABLE sales ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'Confirmed';
ALTER TABLE sales ADD COLUMN IF NOT EXISTS location_id VARCHAR(36) NULL;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS customer_notes TEXT NULL;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS decline_reason TEXT NULL;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS dispatch_tracking_ref VARCHAR(100) NULL;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS dispatch_date DATETIME NULL;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS delivered_date DATETIME NULL;

CREATE INDEX IF NOT EXISTS idx_sales_status ON sales(status);
CREATE INDEX IF NOT EXISTS idx_sales_location ON sales(location_id);
