-- Master Migration 010: Platform Portal Permissions & Universal Partner Profile
-- Moves Vendor/Customer permissions exclusively to Platform Super Admin control in erp_master
-- and adds universal business profile & email verification columns to global_portal_users.

-- 1. Universal Business Profile & Verification Fields
ALTER TABLE global_portal_users ADD COLUMN IF NOT EXISTS company_name VARCHAR(255) NULL;
ALTER TABLE global_portal_users ADD COLUMN IF NOT EXISTS gstin VARCHAR(50) NULL;
ALTER TABLE global_portal_users ADD COLUMN IF NOT EXISTS address TEXT NULL;
ALTER TABLE global_portal_users ADD COLUMN IF NOT EXISTS city VARCHAR(100) NULL;
ALTER TABLE global_portal_users ADD COLUMN IF NOT EXISTS state VARCHAR(100) NULL;
ALTER TABLE global_portal_users ADD COLUMN IF NOT EXISTS pincode VARCHAR(20) NULL;
ALTER TABLE global_portal_users ADD COLUMN IF NOT EXISTS business_type VARCHAR(100) NULL;
ALTER TABLE global_portal_users ADD COLUMN IF NOT EXISTS email_verified_at DATETIME NULL;
ALTER TABLE global_portal_users ADD COLUMN IF NOT EXISTS verification_token VARCHAR(255) NULL;
ALTER TABLE global_portal_users ADD COLUMN IF NOT EXISTS verification_token_expires_at DATETIME NULL;

-- Backfill email_verified_at for existing users so their accounts remain active
UPDATE global_portal_users SET email_verified_at = NOW() WHERE email_verified_at IS NULL;

-- 2. Platform Portal Permissions Matrix (Super Admin Controlled)
CREATE TABLE IF NOT EXISTS platform_portal_permissions (
    id VARCHAR(36) PRIMARY KEY,
    role VARCHAR(50) NOT NULL, -- 'vendor' or 'customer'
    module VARCHAR(50) NOT NULL,
    can_view TINYINT NOT NULL DEFAULT 0,
    can_create TINYINT NOT NULL DEFAULT 0,
    can_edit TINYINT NOT NULL DEFAULT 0,
    can_delete TINYINT NOT NULL DEFAULT 0,
    can_approve TINYINT NOT NULL DEFAULT 0,
    can_export TINYINT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_portal_role_module (role, module)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Seed Default Global Portal Permissions
INSERT INTO platform_portal_permissions (id, role, module, can_view, can_create, can_edit, can_delete, can_approve, can_export)
VALUES
    ('perm_vendor_orders', 'vendor', 'vendor_orders', 1, 0, 1, 0, 0, 1),
    ('perm_vendor_returns', 'vendor', 'returns', 1, 1, 1, 0, 0, 1),
    ('perm_customer_orders', 'customer', 'customer_orders', 1, 0, 1, 0, 0, 1),
    ('perm_customer_returns', 'customer', 'returns', 1, 1, 1, 0, 0, 1)
ON DUPLICATE KEY UPDATE
    can_view = VALUES(can_view),
    can_create = VALUES(can_create),
    can_edit = VALUES(can_edit),
    can_delete = VALUES(can_delete),
    can_approve = VALUES(can_approve),
    can_export = VALUES(can_export);
