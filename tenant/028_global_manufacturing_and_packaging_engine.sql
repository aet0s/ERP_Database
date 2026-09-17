-- Migration 028: Global Manufacturing Formulas & Multi-Level Packaging Engine
-- Generalized, industry-agnostic manufacturing formula and hierarchical packaging engine.

-- 1. MANUFACTURING FORMULAS (Header)
CREATE TABLE IF NOT EXISTS production_formulas (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(100),
    version INT NOT NULL DEFAULT 1,
    status VARCHAR(50) NOT NULL DEFAULT 'active', -- 'draft', 'active', 'archived'
    cost_allocation_method VARCHAR(50) NOT NULL DEFAULT 'manual_percentage', -- 'manual_percentage', 'value_based', 'equal_split'
    notes TEXT,
    created_by VARCHAR(36),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    deleted_by VARCHAR(36),
    INDEX idx_formulas_status (status),
    INDEX idx_formulas_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. MANUFACTURING FORMULA INPUTS (Bill of Materials / Components)
CREATE TABLE IF NOT EXISTS production_formula_inputs (
    id VARCHAR(36) PRIMARY KEY,
    formula_id VARCHAR(36) NOT NULL,
    item_type VARCHAR(50) NOT NULL DEFAULT 'raw_material', -- 'raw_material', 'finished_good', 'item', 'wip', 'packaging'
    item_id VARCHAR(36) NOT NULL,
    quantity DECIMAL(15,4) NOT NULL,
    uom VARCHAR(50) NOT NULL,
    expected_loss_percent DECIMAL(7,4) NOT NULL DEFAULT 0.0000,
    sequence INT NOT NULL DEFAULT 1,
    notes TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (formula_id) REFERENCES production_formulas(id) ON DELETE CASCADE,
    INDEX idx_pfi_formula (formula_id),
    INDEX idx_pfi_item (item_type, item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. MANUFACTURING FORMULA OUTPUTS (Finished Goods / Co-Products / By-Products)
CREATE TABLE IF NOT EXISTS production_formula_outputs (
    id VARCHAR(36) PRIMARY KEY,
    formula_id VARCHAR(36) NOT NULL,
    item_type VARCHAR(50) NOT NULL DEFAULT 'finished_good', -- 'finished_good', 'item', 'by_product', 'scrap'
    item_id VARCHAR(36) NOT NULL,
    quantity DECIMAL(15,4) NOT NULL,
    uom VARCHAR(50) NOT NULL,
    cost_allocation_percent DECIMAL(7,4) NOT NULL DEFAULT 100.0000,
    sequence INT NOT NULL DEFAULT 1,
    notes TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (formula_id) REFERENCES production_formulas(id) ON DELETE CASCADE,
    INDEX idx_pfo_formula (formula_id),
    INDEX idx_pfo_item (item_type, item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. PRODUCT PACKAGING LEVELS (Arbitrary, recursive packaging hierarchy)
CREATE TABLE IF NOT EXISTS product_packaging_levels (
    id VARCHAR(36) PRIMARY KEY,
    product_id VARCHAR(36) NOT NULL,
    product_type VARCHAR(50) NOT NULL DEFAULT 'finished_good',
    level_number INT NOT NULL DEFAULT 1,
    name VARCHAR(255) NOT NULL,
    package_unit VARCHAR(50) NOT NULL,
    contains_quantity DECIMAL(15,4) NOT NULL,
    contains_unit VARCHAR(50) NOT NULL,
    parent_level_id VARCHAR(36) NULL,
    base_quantity_equivalent DECIMAL(15,4) NOT NULL,
    selling_price DECIMAL(15,4) NOT NULL DEFAULT 0,
    mrp DECIMAL(15,4) NOT NULL DEFAULT 0,
    barcode VARCHAR(100),
    is_default TINYINT(1) NOT NULL DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT 'active', -- 'active', 'archived'
    notes TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_ppl_product (product_id),
    INDEX idx_ppl_parent (parent_level_id),
    INDEX idx_ppl_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. PRODUCT PACKAGING MATERIALS (BOM components for packaging, e.g., bottles, boxes, caps, labels)
CREATE TABLE IF NOT EXISTS product_packaging_materials (
    id VARCHAR(36) PRIMARY KEY,
    packaging_level_id VARCHAR(36) NOT NULL,
    item_id VARCHAR(36) NOT NULL,
    quantity DECIMAL(15,4) NOT NULL,
    uom VARCHAR(50) NOT NULL,
    cost_per_unit DECIMAL(15,4) NOT NULL DEFAULT 0,
    notes TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (packaging_level_id) REFERENCES product_packaging_levels(id) ON DELETE CASCADE,
    INDEX idx_ppm_level (packaging_level_id),
    INDEX idx_ppm_item (item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. PRODUCTION RUNS EXTENSIONS (Formula linkage & Yield tracking)
ALTER TABLE production_runs
    ADD COLUMN IF NOT EXISTS formula_id VARCHAR(36) NULL,
    ADD COLUMN IF NOT EXISTS formula_version INT NULL,
    ADD COLUMN IF NOT EXISTS yield_percent DECIMAL(15,4) NULL;

ALTER TABLE production_run_inputs
    ADD COLUMN IF NOT EXISTS expected_quantity DECIMAL(15,4) NULL,
    ADD COLUMN IF NOT EXISTS variance_quantity DECIMAL(15,4) NULL,
    ADD COLUMN IF NOT EXISTS uom VARCHAR(50) NULL;

ALTER TABLE production_run_outputs
    ADD COLUMN IF NOT EXISTS expected_quantity DECIMAL(15,4) NULL,
    ADD COLUMN IF NOT EXISTS variance_quantity DECIMAL(15,4) NULL,
    ADD COLUMN IF NOT EXISTS packaging_level_id VARCHAR(36) NULL;

-- 7. SALES ITEMS EXTENSIONS
ALTER TABLE sales_items
    ADD COLUMN IF NOT EXISTS packaging_level_id VARCHAR(36) NULL;

-- 8. DATA MIGRATION: Migrate existing usable packaging_configs into product_packaging_levels
-- A) Migrate Root Levels (parent_config_id is null)
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

-- B) Migrate Child / Nested Levels
INSERT IGNORE INTO product_packaging_levels 
  (id, product_id, product_type, level_number, name, package_unit, contains_quantity, contains_unit, parent_level_id, base_quantity_equivalent, selling_price, mrp, barcode, is_default, status, notes, created_at, updated_at)
SELECT 
  id, product_id, product_type, 2, package_name, package_unit,
  COALESCE(fill_quantity, units_per_package, 1),
  COALESCE(fill_unit, package_unit),
  parent_config_id,
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
WHERE parent_config_id IS NOT NULL;
