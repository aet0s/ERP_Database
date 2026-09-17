-- Master migration 015: Add primary_owner_id and primary_owner_email to companies
ALTER TABLE companies ADD COLUMN IF NOT EXISTS primary_owner_id VARCHAR(36) NULL;
ALTER TABLE companies ADD COLUMN IF NOT EXISTS primary_owner_email VARCHAR(255) NULL;
