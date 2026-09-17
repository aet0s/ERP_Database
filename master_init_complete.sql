-- Production Master Schema
-- Target: lamssolarman_erp_master

-- File: 001_master_schema.sql
-- Master database schema for Database-Per-Company ERP
-- MySQL 8.0+ dialect

-- Global Company Registry
CREATE TABLE IF NOT EXISTS companies (
    id VARCHAR(36) PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    company_code VARCHAR(100) NOT NULL UNIQUE,
    database_name VARCHAR(100) NOT NULL UNIQUE,
    database_host VARCHAR(255),
    database_port INT,
    database_user VARCHAR(100),
    database_password VARCHAR(255),
    status VARCHAR(50) NOT NULL DEFAULT 'provisioning',
    business_type VARCHAR(100),
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    plan VARCHAR(50) NOT NULL DEFAULT 'trial',
    logo_url TEXT,
    accent_color VARCHAR(20) NOT NULL DEFAULT '#2563eb',
    onboarding_completed_at DATETIME,
    suspended_at DATETIME,
    last_activity_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_companies_status (status),
    INDEX idx_companies_last_activity (last_activity_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Global Identity Mapping (user email -> company mapping)
CREATE TABLE IF NOT EXISTS company_users (
    id VARCHAR(36) PRIMARY KEY,
    company_id VARCHAR(36) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    user_id VARCHAR(36) NOT NULL,
    role VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    INDEX idx_company_users_email (email),
    INDEX idx_company_users_company (company_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Master Audit Log for platform-level actions
CREATE TABLE IF NOT EXISTS master_audit_log (
    id VARCHAR(36) PRIMARY KEY,
    company_id VARCHAR(36),
    user_id VARCHAR(36),
    action VARCHAR(100) NOT NULL,
    metadata JSON NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Master Schema Migrations Versioning
CREATE TABLE IF NOT EXISTS master_schema_migrations (
    version INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    applied_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- File: 002_company_invites.sql
-- Migration 002: Add company_invites table to erp_master for O(1) single master DB invitation token resolution

CREATE TABLE IF NOT EXISTS company_invites (
    id VARCHAR(36) PRIMARY KEY,
    company_id VARCHAR(36) NOT NULL,
    email VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    expires_at DATETIME NOT NULL,
    accepted_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    INDEX idx_company_invites_token (token),
    INDEX idx_company_invites_company (company_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- File: 003_subscription_schema.sql
-- Migration 003: Subscription & Billing Lifecycle Schema for erp_master

ALTER TABLE companies ADD COLUMN subscription_id VARCHAR(255);
ALTER TABLE companies ADD COLUMN subscription_status VARCHAR(50) DEFAULT 'trialing';
ALTER TABLE companies ADD COLUMN current_period_end DATETIME;
ALTER TABLE companies ADD COLUMN trial_ends_at DATETIME;
ALTER TABLE companies ADD COLUMN canceled_at DATETIME;
ALTER TABLE companies ADD COLUMN graceful_read_only_until DATETIME;

-- Idempotency table for Billing Webhook Events
CREATE TABLE IF NOT EXISTS master_webhook_events (
    id VARCHAR(36) PRIMARY KEY,
    event_id VARCHAR(255) NOT NULL UNIQUE,
    provider VARCHAR(100) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    payload JSON NOT NULL,
    processed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_master_webhook_events_event (event_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_companies_subscription_status ON companies(subscription_status);


-- File: 004_master_refresh_tokens.sql
-- Master Refresh Tokens Table for O(1) Token Lookup Across Tenants
CREATE TABLE IF NOT EXISTS master_refresh_tokens (
    id VARCHAR(36) PRIMARY KEY,
    company_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at DATETIME NOT NULL,
    revoked_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    INDEX idx_master_refresh_token_hash (token_hash)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- File: 005_master_gst_branding.sql
-- Add GST & State location fields to Master companies table
ALTER TABLE companies ADD COLUMN gstin VARCHAR(50);
ALTER TABLE companies ADD COLUMN state VARCHAR(100) DEFAULT 'Delhi';
ALTER TABLE companies ADD COLUMN pan VARCHAR(50);


-- File: 006_platform_admins.sql
-- Platform Super Admins (isolated from company users)
CREATE TABLE IF NOT EXISTS platform_admins (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    last_login_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_platform_admins_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- File: 007_platform_settings.sql
-- Platform Settings Table
CREATE TABLE IF NOT EXISTS platform_settings (
    id VARCHAR(36) PRIMARY KEY,
    default_trial_days INT NOT NULL DEFAULT 14,
    max_active_tenant_pools INT NOT NULL DEFAULT 50,
    tenant_db_pool_max INT NOT NULL DEFAULT 5,
    master_db_pool_max INT NOT NULL DEFAULT 20,
    default_currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    invoice_rounding_method VARCHAR(50) NOT NULL DEFAULT 'round_half_up',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- File: 008_global_portal_identities.sql
-- Master Migration 008: Global Portal Users & Memberships
-- Enables single global identity and password for vendors and customers across multiple workspaces.

CREATE TABLE IF NOT EXISTS global_portal_users (
    id VARCHAR(36) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'Active',
    last_login_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_global_portal_users_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS global_portal_memberships (
    id VARCHAR(36) PRIMARY KEY,
    global_user_id VARCHAR(36) NOT NULL,
    company_id VARCHAR(36) NOT NULL,
    entity_id VARCHAR(36) NOT NULL,
    portal_type VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'Active',
    invite_token VARCHAR(255) NULL,
    invite_expires_at DATETIME NULL,
    joined_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_global_portal_member (global_user_id, company_id, portal_type),
    INDEX idx_gpm_user (global_user_id),
    INDEX idx_gpm_company (company_id),
    INDEX idx_gpm_token (invite_token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- File: 009_master_support_contact.sql
-- Master Migration 009: Add Support Contact Fields
ALTER TABLE companies ADD COLUMN support_email VARCHAR(255) NULL;
ALTER TABLE companies ADD COLUMN support_phone VARCHAR(50) NULL;


-- File: 010_platform_portal_permissions.sql
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


-- File: 011_company_connect_code.sql
-- Master Migration 011: Company Connect Code & Bidirectional Connection Model
-- Gives each workspace a unique shareable Company Connect Code and adds initiated_by to memberships.

ALTER TABLE companies ADD COLUMN IF NOT EXISTS connect_code VARCHAR(50) NULL;
ALTER TABLE companies ADD UNIQUE INDEX IF NOT EXISTS uk_company_connect_code (connect_code);

-- Backfill connect_code with company_code for existing companies
UPDATE companies SET connect_code = company_code WHERE connect_code IS NULL;

-- Add initiated_by to global_portal_memberships ('workspace' or 'partner')
ALTER TABLE global_portal_memberships ADD COLUMN IF NOT EXISTS initiated_by VARCHAR(20) NOT NULL DEFAULT 'workspace';
ALTER TABLE global_portal_memberships ADD COLUMN IF NOT EXISTS notes TEXT NULL;


-- File: 012_company_address_and_bank.sql
-- Master Migration 012: Add Address & Bank Account Details to Companies
ALTER TABLE companies ADD COLUMN address TEXT NULL;
ALTER TABLE companies ADD COLUMN city VARCHAR(100) NULL;
ALTER TABLE companies ADD COLUMN pincode VARCHAR(20) NULL;
ALTER TABLE companies ADD COLUMN bank_name VARCHAR(255) NULL;
ALTER TABLE companies ADD COLUMN bank_account_name VARCHAR(255) NULL;
ALTER TABLE companies ADD COLUMN bank_account_number VARCHAR(100) NULL;
ALTER TABLE companies ADD COLUMN bank_ifsc VARCHAR(50) NULL;
ALTER TABLE companies ADD COLUMN bank_branch VARCHAR(255) NULL;


-- File: 013_add_currency_column.sql
-- Master Migration 013: Add Currency to Companies
ALTER TABLE companies ADD COLUMN currency VARCHAR(10) NOT NULL DEFAULT 'INR';


-- File: 014_add_number_system_column.sql
-- 014_add_number_system_column.sql
-- Add configurable numbering & decimal system for workspace (indian / international)

ALTER TABLE companies ADD COLUMN number_system VARCHAR(32) DEFAULT 'indian';
UPDATE companies SET number_system = 'indian' WHERE number_system IS NULL;


-- File: 015_add_primary_owner_to_companies.sql
-- Master migration 015: Add primary_owner_id and primary_owner_email to companies
ALTER TABLE companies ADD COLUMN IF NOT EXISTS primary_owner_id VARCHAR(36) NULL;
ALTER TABLE companies ADD COLUMN IF NOT EXISTS primary_owner_email VARCHAR(255) NULL;


-- File: 016_add_pan_to_global_portal_users.sql
-- Master migration 016: Add pan column to global_portal_users
ALTER TABLE global_portal_users ADD COLUMN IF NOT EXISTS pan VARCHAR(50) NULL;


-- File: 017_enterprise_platform_settings_and_user_roles.sql
-- Master Migration 017: Enterprise Platform Settings, User Roles, and Master Audit Hash-Chaining
-- Ensures a brand new server has complete schemas for companies, platform_settings, company_users, and master_audit_log.

-- 1. Companies enterprise backup and lifecycle columns
ALTER TABLE companies ADD COLUMN IF NOT EXISTS status_reason TEXT NULL;
ALTER TABLE companies ADD COLUMN IF NOT EXISTS status_reason_updated_at DATETIME NULL;
ALTER TABLE companies ADD COLUMN IF NOT EXISTS status_reason_updated_by VARCHAR(255) NULL;
ALTER TABLE companies ADD COLUMN IF NOT EXISTS auto_backup_enabled TINYINT(1) DEFAULT 1;
ALTER TABLE companies ADD COLUMN IF NOT EXISTS auto_backup_frequency VARCHAR(20) DEFAULT 'daily';
ALTER TABLE companies ADD COLUMN IF NOT EXISTS auto_backup_retention_days INT DEFAULT 30;
ALTER TABLE companies ADD COLUMN IF NOT EXISTS auto_backup_time VARCHAR(10) DEFAULT '02:00';
ALTER TABLE companies ADD COLUMN IF NOT EXISTS last_auto_backup_at DATETIME NULL;

-- 2. Company users role matrix and contact
ALTER TABLE company_users ADD COLUMN IF NOT EXISTS roles TEXT NULL;
ALTER TABLE company_users ADD COLUMN IF NOT EXISTS phone VARCHAR(50) NULL;

-- 3. Master audit log cryptographic hash-chaining
ALTER TABLE master_audit_log ADD COLUMN IF NOT EXISTS prev_hash VARCHAR(64) NULL;
ALTER TABLE master_audit_log ADD COLUMN IF NOT EXISTS hash VARCHAR(64) NULL;

-- 4. Platform settings enterprise configurations
ALTER TABLE platform_settings ADD COLUMN IF NOT EXISTS payment_grace_period_days INT DEFAULT 7;
ALTER TABLE platform_settings ADD COLUMN IF NOT EXISTS platform_name VARCHAR(255) DEFAULT 'ERP Enterprise Studio';
ALTER TABLE platform_settings ADD COLUMN IF NOT EXISTS platform_support_email VARCHAR(255) DEFAULT 'support@erpplatform.com';
ALTER TABLE platform_settings ADD COLUMN IF NOT EXISTS platform_company_legal_name VARCHAR(255) DEFAULT 'ERP Global Systems Technologies Inc.';
ALTER TABLE platform_settings ADD COLUMN IF NOT EXISTS allow_workspace_registration TINYINT(1) DEFAULT 1;
ALTER TABLE platform_settings ADD COLUMN IF NOT EXISTS auto_freeze_on_grace_expiry TINYINT(1) DEFAULT 1;
ALTER TABLE platform_settings ADD COLUMN IF NOT EXISTS default_tax_rate_pct DECIMAL(5,2) DEFAULT 18.00;
ALTER TABLE platform_settings ADD COLUMN IF NOT EXISTS jwt_session_expiry_hours INT DEFAULT 24;
ALTER TABLE platform_settings ADD COLUMN IF NOT EXISTS max_login_attempts_lockout INT DEFAULT 5;
ALTER TABLE platform_settings ADD COLUMN IF NOT EXISTS enforce_strong_passwords TINYINT(1) DEFAULT 1;
ALTER TABLE platform_settings ADD COLUMN IF NOT EXISTS audit_log_retention_days INT DEFAULT 90;
ALTER TABLE platform_settings ADD COLUMN IF NOT EXISTS tenant_pool_queue_timeout_ms INT DEFAULT 5000;
ALTER TABLE platform_settings ADD COLUMN IF NOT EXISTS maintenance_mode_enabled TINYINT(1) DEFAULT 0;
ALTER TABLE platform_settings ADD COLUMN IF NOT EXISTS maintenance_message TEXT NULL;
ALTER TABLE platform_settings ADD COLUMN IF NOT EXISTS master_auto_backup_enabled TINYINT(1) DEFAULT 1;
ALTER TABLE platform_settings ADD COLUMN IF NOT EXISTS master_auto_backup_frequency VARCHAR(20) DEFAULT 'daily';
ALTER TABLE platform_settings ADD COLUMN IF NOT EXISTS master_auto_backup_retention_days INT DEFAULT 30;
ALTER TABLE platform_settings ADD COLUMN IF NOT EXISTS master_auto_backup_time VARCHAR(10) DEFAULT '01:00';
ALTER TABLE platform_settings ADD COLUMN IF NOT EXISTS master_last_auto_backup_at DATETIME NULL;

-- 5. Seed default platform settings row if table is empty
INSERT IGNORE INTO platform_settings (
    id, default_trial_days, max_active_tenant_pools, tenant_db_pool_max, master_db_pool_max,
    default_currency, invoice_rounding_method, payment_grace_period_days, platform_name,
    platform_support_email, platform_company_legal_name, allow_workspace_registration,
    auto_freeze_on_grace_expiry, default_tax_rate_pct, jwt_session_expiry_hours,
    max_login_attempts_lockout, enforce_strong_passwords, audit_log_retention_days,
    tenant_pool_queue_timeout_ms, maintenance_mode_enabled, master_auto_backup_enabled,
    master_auto_backup_frequency, master_auto_backup_retention_days, master_auto_backup_time
) VALUES (
    'default-platform-settings-uuid', 14, 50, 5, 20,
    'INR', 'round_half_up', 7, 'ERP Enterprise Studio',
    'support@erpplatform.com', 'ERP Global Systems Technologies Inc.', 1,
    1, 18.00, 24,
    5, 1, 90,
    5000, 0, 1,
    'daily', 30, '01:00'
);

-- ==========================================
-- Track all migrations as applied
-- ==========================================
CREATE TABLE IF NOT EXISTS master_schema_migrations (
    version INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    applied_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO master_schema_migrations (version, name) VALUES
(1, '001_master_schema.sql'),
(2, '002_company_invites.sql'),
(3, '003_subscription_schema.sql'),
(4, '004_master_refresh_tokens.sql'),
(5, '005_master_gst_branding.sql'),
(6, '006_platform_admins.sql'),
(7, '007_platform_settings.sql'),
(8, '008_global_portal_identities.sql'),
(9, '009_master_support_contact.sql'),
(10, '010_platform_portal_permissions.sql'),
(11, '011_company_connect_code.sql'),
(12, '012_company_address_and_bank.sql'),
(13, '013_add_currency_column.sql'),
(14, '014_add_number_system_column.sql'),
(15, '015_add_primary_owner_to_companies.sql'),
(16, '016_add_pan_to_global_portal_users.sql'),
(17, '017_enterprise_platform_settings_and_user_roles.sql');

-- ==========================================
-- Initial Platform Super Admin User
-- Email: admin@platform.com
-- Password: PlatformAdmin2026!
-- ==========================================
INSERT IGNORE INTO platform_admins (id, name, email, password_hash, status)
VALUES (
    'admin-super-uuid-0001',
    'Platform Super Admin',
    'admin@platform.com',
    '$2b$12$qW1sDwANy8ENaTEDZq6Mgu46ZrIn8hWG6OSdRSy4gDN5gkeASC9hK',
    'active'
);



