-- Migration 040: Ensure essential auth columns exist on users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS roles TEXT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS vendor_id VARCHAR(36) NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS customer_id VARCHAR(36) NULL;
