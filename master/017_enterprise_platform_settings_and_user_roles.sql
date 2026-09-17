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
