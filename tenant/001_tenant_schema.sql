-- Tenant database schema for Database-Per-Company ERP
-- MySQL 8.0+ dialect (Each company has its own isolated database)

-- Users within this company
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    roles TEXT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    deleted_at DATETIME,
    last_login_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Raw materials
CREATE TABLE IF NOT EXISTS raw_materials (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    unit VARCHAR(50) NOT NULL,
    reorder_level DECIMAL(15,4) NULL,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    deleted_by VARCHAR(36),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_raw_materials_deleted (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Process stages
CREATE TABLE IF NOT EXISTS process_stages (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    sequence_order INT NOT NULL UNIQUE,
    is_final_stage TINYINT(1) NOT NULL DEFAULT 0,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    deleted_by VARCHAR(36),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_process_stages_deleted (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Finished goods
CREATE TABLE IF NOT EXISTS finished_goods (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    unit VARCHAR(50) NOT NULL,
    default_price DECIMAL(15,4) NULL,
    reorder_level DECIMAL(15,4) NULL,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    deleted_by VARCHAR(36),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_finished_goods_deleted (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Vendors
CREATE TABLE IF NOT EXISTS vendors (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    contact VARCHAR(255),
    address TEXT,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    deleted_by VARCHAR(36),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_vendors_deleted (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Customers
CREATE TABLE IF NOT EXISTS customers (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    contact VARCHAR(255),
    address TEXT,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    deleted_by VARCHAR(36),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_customers_deleted (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Procurements
CREATE TABLE IF NOT EXISTS procurements (
    id VARCHAR(36) PRIMARY KEY,
    vendor_id VARCHAR(36),
    raw_material_id VARCHAR(36),
    quantity DECIMAL(15,4) NOT NULL,
    rate_per_unit DECIMAL(15,4) NOT NULL,
    total_amount DECIMAL(15,4) GENERATED ALWAYS AS (quantity * rate_per_unit) STORED,
    amount_paid DECIMAL(15,4) NOT NULL DEFAULT 0,
    amount_due DECIMAL(15,4) GENERATED ALWAYS AS ((quantity * rate_per_unit) - amount_paid) STORED,
    date DATE NOT NULL,
    notes TEXT,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    deleted_by VARCHAR(36),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vendor_id) REFERENCES vendors(id),
    FOREIGN KEY (raw_material_id) REFERENCES raw_materials(id),
    INDEX idx_procurements_date (date),
    INDEX idx_procurements_deleted (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Production batches
CREATE TABLE IF NOT EXISTS production_batches (
    id VARCHAR(36) PRIMARY KEY,
    process_stage_id VARCHAR(36) NOT NULL,
    batch_number VARCHAR(100) NOT NULL UNIQUE,
    input_material_type VARCHAR(50) NOT NULL,
    input_reference_id VARCHAR(36) NULL,
    input_quantity DECIMAL(15,4) NOT NULL,
    output_quantity DECIMAL(15,4) NOT NULL,
    output_unit VARCHAR(50) NOT NULL,
    wastage_quantity DECIMAL(15,4) GENERATED ALWAYS AS (input_quantity - output_quantity) STORED,
    yield_percent DECIMAL(15,4) GENERATED ALWAYS AS (IF(input_quantity > 0, (output_quantity / input_quantity) * 100, NULL)) STORED,
    labor_cost DECIMAL(15,4) NOT NULL DEFAULT 0,
    other_cost DECIMAL(15,4) NOT NULL DEFAULT 0,
    finished_good_id VARCHAR(36),
    date DATE NOT NULL,
    notes TEXT,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    deleted_by VARCHAR(36),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (process_stage_id) REFERENCES process_stages(id),
    FOREIGN KEY (finished_good_id) REFERENCES finished_goods(id),
    INDEX idx_production_date (date),
    INDEX idx_production_deleted (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Sales
CREATE TABLE IF NOT EXISTS sales (
    id VARCHAR(36) PRIMARY KEY,
    customer_id VARCHAR(36),
    finished_good_id VARCHAR(36),
    quantity DECIMAL(15,4) NOT NULL,
    rate_per_unit DECIMAL(15,4) NOT NULL,
    total_amount DECIMAL(15,4) GENERATED ALWAYS AS (quantity * rate_per_unit) STORED,
    amount_received DECIMAL(15,4) NOT NULL DEFAULT 0,
    amount_due DECIMAL(15,4) GENERATED ALWAYS AS ((quantity * rate_per_unit) - amount_received) STORED,
    date DATE NOT NULL,
    notes TEXT,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    deleted_by VARCHAR(36),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (finished_good_id) REFERENCES finished_goods(id),
    INDEX idx_sales_date (date),
    INDEX idx_sales_deleted (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Expenses
CREATE TABLE IF NOT EXISTS expenses (
    id VARCHAR(36) PRIMARY KEY,
    category VARCHAR(100) NOT NULL,
    amount DECIMAL(15,4) NOT NULL,
    date DATE NOT NULL,
    notes TEXT,
    created_by VARCHAR(36) NULL,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    deleted_by VARCHAR(36),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_expenses_date (date),
    INDEX idx_expenses_deleted (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Inventory ledger
CREATE TABLE IF NOT EXISTS inventory_ledger (
    id VARCHAR(36) PRIMARY KEY,
    item_type VARCHAR(50) NOT NULL,
    item_id VARCHAR(36) NULL,
    transaction_type VARCHAR(50) NOT NULL,
    quantity DECIMAL(15,4) NOT NULL,
    unit_cost DECIMAL(15,4) NOT NULL DEFAULT 0,
    reason TEXT,
    reference_table VARCHAR(100),
    reference_id VARCHAR(36) NULL,
    date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(36),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_inventory_item (item_type, item_id, date),
    INDEX idx_inventory_reference (reference_table, reference_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Payments log
CREATE TABLE IF NOT EXISTS payments_log (
    id VARCHAR(36) PRIMARY KEY,
    related_type VARCHAR(50) NOT NULL,
    related_id VARCHAR(36) NOT NULL,
    amount DECIMAL(15,4) NOT NULL,
    date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    created_by VARCHAR(36),
    deleted_at DATETIME,
    deleted_by VARCHAR(36),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_payments_date (date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Workspace Invites (company employee invitations)
CREATE TABLE IF NOT EXISTS workspace_invites (
    id VARCHAR(36) PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    invited_by VARCHAR(36),
    accepted_at DATETIME,
    expires_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (invited_by) REFERENCES users(id),
    INDEX idx_invites_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Refresh tokens
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    token_hash VARCHAR(255) NOT NULL,
    expires_at DATETIME NOT NULL,
    revoked_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_refresh_tokens_user (user_id, revoked_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Audit log
CREATE TABLE IF NOT EXISTS audit_log (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(100) NOT NULL,
    entity_id VARCHAR(36),
    metadata JSON NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    INDEX idx_audit_date (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Schema Migrations Tracking
CREATE TABLE IF NOT EXISTS schema_migrations (
    version INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    applied_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
