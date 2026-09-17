-- Migration 037: Add location_code and expense_number + Numbering Series Defaults
-- MySQL Dialect

-- 1. Location Code
ALTER TABLE locations ADD COLUMN IF NOT EXISTS location_code VARCHAR(100) NULL;

-- 2. Expense Number
ALTER TABLE expenses ADD COLUMN IF NOT EXISTS expense_number VARCHAR(100) NULL;

-- 3. Numbering Series Defaults
INSERT IGNORE INTO numbering_series (document_type, prefix, next_number, padding_digits, reset_period)
VALUES
  ('vendor', 'VEN-', 1, 4, 'never'),
  ('customer', 'CUST-', 1, 4, 'never'),
  ('item', 'SKU-', 1, 4, 'never'),
  ('location', 'LOC-', 1, 4, 'never'),
  ('expense', 'EXP-', 1, 4, 'FY'),
  ('production_order', 'MFG-', 1, 4, 'FY'),
  ('production_run', 'RUN-', 1, 4, 'never'),
  ('stock_transfer', 'TRF-', 1, 4, 'FY'),
  ('return_request', 'RET-', 1, 4, 'FY')
ON DUPLICATE KEY UPDATE updated_at = NOW();
