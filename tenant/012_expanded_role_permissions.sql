-- Tenant Migration 012: Role Permissions Table with Expanded Capabilities
CREATE TABLE IF NOT EXISTS role_permissions (
    id VARCHAR(100) PRIMARY KEY,
    role VARCHAR(50) NOT NULL,
    module VARCHAR(50) NOT NULL,
    can_view TINYINT(1) NOT NULL DEFAULT 1,
    can_create TINYINT(1) NOT NULL DEFAULT 0,
    can_edit TINYINT(1) NOT NULL DEFAULT 0,
    can_delete TINYINT(1) NOT NULL DEFAULT 0,
    can_approve TINYINT(1) NOT NULL DEFAULT 0,
    can_export TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_role_module (role, module),
    INDEX idx_rp_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
