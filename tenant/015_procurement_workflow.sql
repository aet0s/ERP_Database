-- 015_procurement_workflow.sql
-- Adds procurement workflow status, vendor notes, and dispatch tracking to procurements table

ALTER TABLE procurements ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'Pending Vendor Confirmation';
ALTER TABLE procurements ADD COLUMN IF NOT EXISTS vendor_notes TEXT NULL;
ALTER TABLE procurements ADD COLUMN IF NOT EXISTS dispatch_tracking_ref VARCHAR(100) NULL;
ALTER TABLE procurements ADD COLUMN IF NOT EXISTS dispatch_date DATETIME NULL;
ALTER TABLE procurements ADD COLUMN IF NOT EXISTS rejection_reason TEXT NULL;

CREATE INDEX IF NOT EXISTS idx_procurements_status ON procurements(status);
