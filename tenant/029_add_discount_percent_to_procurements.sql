-- Migration 029: Add discount_percent to procurements table
ALTER TABLE procurements ADD COLUMN IF NOT EXISTS discount_percent DECIMAL(5,2) DEFAULT 0;
