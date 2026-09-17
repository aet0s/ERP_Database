-- Migration 023: Add default_price (Catalog Selling Price) to items table
ALTER TABLE items ADD COLUMN default_price DECIMAL(15,4) NULL DEFAULT NULL AFTER last_purchase_price;
