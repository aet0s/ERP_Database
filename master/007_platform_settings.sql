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