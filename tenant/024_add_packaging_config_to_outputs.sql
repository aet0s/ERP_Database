-- Migration 024: Add packaging configuration to production run outputs
ALTER TABLE production_run_outputs
  ADD COLUMN packaging_config_id VARCHAR(36) NULL AFTER item_id,
  ADD COLUMN packaging_name VARCHAR(100) NULL AFTER unit,
  ADD COLUMN units_per_package DECIMAL(15,4) NOT NULL DEFAULT 1.0000 AFTER packaging_name,
  ADD COLUMN base_quantity DECIMAL(15,4) NULL AFTER units_per_package;
