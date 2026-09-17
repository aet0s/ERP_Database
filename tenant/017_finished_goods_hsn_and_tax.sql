-- Tenant Migration 017: Add HSN Code and Tax Rate to Finished Goods
ALTER TABLE finished_goods ADD COLUMN hsn_code VARCHAR(50) NULL;
ALTER TABLE finished_goods ADD COLUMN tax_rate DECIMAL(5,2) NOT NULL DEFAULT 18.00;
