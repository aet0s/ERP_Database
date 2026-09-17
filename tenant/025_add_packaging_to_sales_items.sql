-- Migration 025: Add packaging configuration columns to sales_items
ALTER TABLE sales_items
  ADD COLUMN packaging_config_id VARCHAR(64) NULL AFTER finished_good_id,
  ADD COLUMN package_name VARCHAR(128) NULL AFTER packaging_config_id,
  ADD COLUMN units_per_package DECIMAL(15,4) NOT NULL DEFAULT 1.0000 AFTER package_name;
