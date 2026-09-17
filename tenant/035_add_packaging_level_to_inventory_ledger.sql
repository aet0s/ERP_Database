-- Migration 035: Add packaging_level_id and package_count to inventory_ledger
-- Allows warehouse inventory to strictly track actual packaged finished goods
-- vs loose units, and prevents sales of unproduced packaging formats.

ALTER TABLE `inventory_ledger`
  ADD COLUMN `packaging_level_id` VARCHAR(36) NULL DEFAULT NULL AFTER `location_id`,
  ADD COLUMN `package_count` DECIMAL(15, 4) NULL DEFAULT NULL AFTER `packaging_level_id`;

CREATE INDEX `idx_inv_ledger_pkg` ON `inventory_ledger` (`item_type`, `item_id`, `packaging_level_id`);
