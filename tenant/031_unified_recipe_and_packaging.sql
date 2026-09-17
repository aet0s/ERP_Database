-- 031_unified_recipe_and_packaging.sql
-- Unified Manufacturing Formula & Hierarchical Packaging Engine Consolidation

-- 1. Base Selling Price on Output Items
ALTER TABLE finished_goods 
  ADD COLUMN IF NOT EXISTS base_selling_price DECIMAL(15,4) NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS base_selling_price_effective_from DATETIME NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE items 
  ADD COLUMN IF NOT EXISTS base_selling_price DECIMAL(15,4) NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS base_selling_price_effective_from DATETIME NULL DEFAULT CURRENT_TIMESTAMP;

-- Backfill base selling price from default_price where not set
UPDATE finished_goods 
SET base_selling_price = COALESCE(default_price, 0)
WHERE base_selling_price IS NULL;

UPDATE items 
SET base_selling_price = COALESCE(default_price, last_purchase_price, 0)
WHERE base_selling_price IS NULL;

-- 2. Production Run Output Allocations (Multi-package + Loose splitting with live remainder tracking)
CREATE TABLE IF NOT EXISTS production_run_output_allocations (
    id VARCHAR(36) PRIMARY KEY,
    run_output_id VARCHAR(36) NOT NULL,
    packaging_level_id VARCHAR(36) NULL, -- NULL represents loose / unpackaged
    package_count DECIMAL(15,4) NOT NULL DEFAULT 0.0000,
    base_units_consumed DECIMAL(15,4) NOT NULL DEFAULT 0.0000,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (run_output_id) REFERENCES production_run_outputs(id) ON DELETE CASCADE,
    INDEX idx_proa_run_output (run_output_id),
    INDEX idx_proa_pkg_level (packaging_level_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Ensure complete data migration from packaging_configs to product_packaging_levels (if table exists)
-- A) Migrate Root Levels (parent_config_id IS NULL)
INSERT IGNORE INTO product_packaging_levels 
  (id, product_id, product_type, level_number, name, package_unit, contains_quantity, contains_unit, parent_level_id, base_quantity_equivalent, selling_price, mrp, barcode, is_default, status, notes, created_at, updated_at)
SELECT 
  id, product_id, product_type, 1, package_name, package_unit,
  COALESCE(fill_quantity, units_per_package, 1),
  COALESCE(fill_unit, package_unit),
  NULL,
  COALESCE(units_per_package, 1),
  COALESCE(selling_price, 0),
  COALESCE(mrp, 0),
  barcode,
  COALESCE(is_default, 0),
  'active',
  notes,
  created_at,
  updated_at
FROM packaging_configs
WHERE parent_config_id IS NULL;

-- B) Migrate Nested Levels (parent_config_id IS NOT NULL)
INSERT IGNORE INTO product_packaging_levels 
  (id, product_id, product_type, level_number, name, package_unit, contains_quantity, contains_unit, parent_level_id, base_quantity_equivalent, selling_price, mrp, barcode, is_default, status, notes, created_at, updated_at)
SELECT 
  pc.id, pc.product_id, pc.product_type, 2, pc.package_name, pc.package_unit,
  COALESCE(pc.fill_quantity, pc.units_per_package, 1),
  COALESCE(pc.fill_unit, pc.package_unit),
  pc.parent_config_id,
  COALESCE(pc.units_per_package, 1),
  COALESCE(pc.selling_price, 0),
  COALESCE(pc.mrp, 0),
  pc.barcode,
  COALESCE(pc.is_default, 0),
  'active',
  pc.notes,
  pc.created_at,
  pc.updated_at
FROM packaging_configs pc
WHERE pc.parent_config_id IS NOT NULL;

-- 4. Backfill packaging_level_id on sales_items from legacy packaging_config_id
UPDATE sales_items 
SET packaging_level_id = packaging_config_id 
WHERE packaging_level_id IS NULL AND packaging_config_id IS NOT NULL;

-- 5. Drop legacy packaging_configs table
DROP TABLE IF EXISTS packaging_configs;

-- 6. Clean up legacy packaging columns on production_batches (if table exists)
ALTER TABLE production_batches
  DROP COLUMN IF EXISTS packaging_config_id,
  DROP COLUMN IF EXISTS package_unit,
  DROP COLUMN IF EXISTS total_packages,
  DROP COLUMN IF EXISTS units_per_package;
