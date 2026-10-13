-- Tenant Migration 041: Add location_id to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS location_id VARCHAR(36) NULL;
CREATE INDEX IF NOT EXISTS idx_users_location ON users (location_id);
