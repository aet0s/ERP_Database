-- Migration 006: Generalized Packaging Engine & Multi-Level Hierarchy Support

-- 1. Process Stage Types (processing, manufacturing, packaging)
ALTER TABLE process_stages ADD COLUMN stage_type VARCHAR(50) NOT NULL DEFAULT 'processing';

-- 2. Enhanced Packaging Configurations (Fill Quantity, Fill Unit, Parent Config Hierarchy, Packaging Material Link)
ALTER TABLE packaging_configs ADD COLUMN fill_quantity DECIMAL(15,4);
ALTER TABLE packaging_configs ADD COLUMN fill_unit VARCHAR(50);
ALTER TABLE packaging_configs ADD COLUMN parent_config_id VARCHAR(36);
ALTER TABLE packaging_configs ADD COLUMN packaging_item_id VARCHAR(36);

-- Backfill fill_quantity and fill_unit from units_per_package and package_unit if missing
UPDATE packaging_configs SET fill_quantity = units_per_package WHERE fill_quantity IS NULL AND units_per_package IS NOT NULL;
UPDATE packaging_configs SET fill_unit = package_unit WHERE fill_unit IS NULL AND package_unit IS NOT NULL;

-- 3. Production Batches Packaging Extensions
ALTER TABLE production_batches ADD COLUMN fill_quantity DECIMAL(15,4);
ALTER TABLE production_batches ADD COLUMN fill_unit VARCHAR(50);
ALTER TABLE production_batches ADD COLUMN packaging_material_cost DECIMAL(15,4) DEFAULT 0;

-- 4. Item Unit Conversions Schema Guarantee
CREATE TABLE IF NOT EXISTS item_unit_conversions (
    id VARCHAR(36) PRIMARY KEY,
    item_id VARCHAR(36) NOT NULL,
    procurement_unit VARCHAR(50) NOT NULL,
    base_unit VARCHAR(50) NOT NULL,
    conversion_factor DECIMAL(15,4) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_item_unit_conversion (item_id, procurement_unit)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
