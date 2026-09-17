-- Master Migration 009: Add Support Contact Fields
ALTER TABLE companies ADD COLUMN support_email VARCHAR(255) NULL;
ALTER TABLE companies ADD COLUMN support_phone VARCHAR(50) NULL;
