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
