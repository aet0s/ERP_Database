-- Tenant Migration 036: User Profiles (phone, avatar_url, bio) and Tamper-Evident Audit Hashes
-- Ensures fresh tenant databases have all required columns for profile management and crypto-audit.

-- 1. Users profile attributes
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(50) NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url LONGTEXT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS bio TEXT NULL;

-- 2. Audit log cryptographic hash chaining
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS prev_hash VARCHAR(64) NULL;
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS hash VARCHAR(64) NULL;
