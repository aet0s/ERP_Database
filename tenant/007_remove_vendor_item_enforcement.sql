-- Migration 007: Remove Vendor-Item Procurement Enforcement
-- Decision: vendor_items table is PRESERVED as an optional price history reference.
-- The table records "last price paid to a given vendor for a given item" and is updated
-- automatically on every procurement save (via ON DUPLICATE KEY UPDATE).
-- This is purely informational — it no longer restricts which items can be procured from which vendor.
-- No data is dropped. Historical vendor_items records remain intact.

-- Add a performance index for price history lookups (most recent price per item+vendor)
CREATE INDEX IF NOT EXISTS idx_vendor_items_price_history
  ON vendor_items (item_id, vendor_id, last_purchase_date DESC);

-- Similarly, customer_items is repurposed as optional sales price history (not a sales restriction)
CREATE INDEX IF NOT EXISTS idx_customer_items_price_history
  ON customer_items (finished_good_id, customer_id, last_sale_date DESC);

-- Track this migration

