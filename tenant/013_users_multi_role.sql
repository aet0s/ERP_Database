-- Tenant Migration 013: Multi-Role and User Status support
ALTER TABLE users ADD COLUMN roles TEXT NULL;
ALTER TABLE users ADD COLUMN status VARCHAR(50) NOT NULL DEFAULT 'active';
