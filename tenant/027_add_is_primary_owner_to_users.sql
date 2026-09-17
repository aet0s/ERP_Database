-- Tenant migration 027: Add is_primary_owner flag to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_primary_owner TINYINT(1) NOT NULL DEFAULT 0;
