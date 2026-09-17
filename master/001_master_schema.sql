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
