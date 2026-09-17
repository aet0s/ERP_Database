-- Migration 005: Generalized Packaging Configurations & Unit Conversion Engine
CREATE TABLE IF NOT EXISTS packaging_configs (
    id VARCHAR(36) PRIMARY KEY,
    product_id VARCHAR(36) NOT NULL,
    product_type VARCHAR(50) NOT NULL DEFAULT 'finished_good',
    package_name VARCHAR(255) NOT NULL,
    package_unit VARCHAR(50) NOT NULL,
    units_per_package DECIMAL(15,4) NOT NULL DEFAULT 1,
    mrp DECIMAL(15,4) DEFAULT 0,
    selling_price DECIMAL(15,4) DEFAULT 0,
    barcode VARCHAR(100),
    is_default TINYINT(1) DEFAULT 0,
    notes TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE production_batches ADD COLUMN packaging_config_id VARCHAR(36);
ALTER TABLE production_batches ADD COLUMN package_unit VARCHAR(50);
ALTER TABLE production_batches ADD COLUMN total_packages DECIMAL(15,4) DEFAULT 0;
ALTER TABLE production_batches ADD COLUMN units_per_package DECIMAL(15,4) DEFAULT 1;
