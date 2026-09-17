-- Add GST & State location fields to Master companies table
ALTER TABLE companies ADD COLUMN gstin VARCHAR(50);
ALTER TABLE companies ADD COLUMN state VARCHAR(100) DEFAULT 'Delhi';
ALTER TABLE companies ADD COLUMN pan VARCHAR(50);
