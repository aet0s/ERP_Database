-- Migration 003: Vendor & Item Catalog Restructure, Customer Parallel Structure, GST Invoicing, POs, Notes & Series
-- MySQL Tenant Database Dialect

-- 1. Vendor Master Expansion
ALTER TABLE vendors ADD COLUMN vendor_code VARCHAR(100);
ALTER TABLE vendors ADD COLUMN contact_person_name VARCHAR(255);
ALTER TABLE vendors ADD COLUMN phone VARCHAR(50);
ALTER TABLE vendors ADD COLUMN email VARCHAR(255);
ALTER TABLE vendors ADD COLUMN address_line1 TEXT;
ALTER TABLE vendors ADD COLUMN address_line2 TEXT;
ALTER TABLE vendors ADD COLUMN city VARCHAR(100);
ALTER TABLE vendors ADD COLUMN state VARCHAR(100);
ALTER TABLE vendors ADD COLUMN pincode VARCHAR(20);
ALTER TABLE vendors ADD COLUMN country VARCHAR(100) DEFAULT 'India';
ALTER TABLE vendors ADD COLUMN gstin VARCHAR(50);
ALTER TABLE vendors ADD COLUMN pan VARCHAR(50);
ALTER TABLE vendors ADD COLUMN payment_terms VARCHAR(100) DEFAULT 'Net 30';
ALTER TABLE vendors ADD COLUMN bank_account_name VARCHAR(255);
ALTER TABLE vendors ADD COLUMN bank_account_number VARCHAR(100);
ALTER TABLE vendors ADD COLUMN bank_ifsc VARCHAR(50);
ALTER TABLE vendors ADD COLUMN notes TEXT;
ALTER TABLE vendors ADD COLUMN status VARCHAR(50) DEFAULT 'Active';

-- 2. Item Master Table
CREATE TABLE IF NOT EXISTS items (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(100) UNIQUE,
    item_type VARCHAR(50) NOT NULL DEFAULT 'Raw Material',
    unit VARCHAR(50) NOT NULL DEFAULT 'kg',
    hsn_code VARCHAR(50),
    last_purchase_price DECIMAL(15,4) DEFAULT 0,
    reorder_level DECIMAL(15,4),
    tax_rate DECIMAL(15,4) DEFAULT 18,
    notes TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'Active',
    deleted_at DATETIME,
    deleted_by VARCHAR(36),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_items_code (code),
    INDEX idx_items_type (item_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Backfill existing raw_materials into items table if empty
INSERT IGNORE INTO items (id, name, unit, reorder_level, created_at, updated_at)
SELECT id, name, unit, reorder_level, created_at, updated_at
FROM raw_materials;

-- 3. Vendor-Item Link Table
CREATE TABLE IF NOT EXISTS vendor_items (
    id VARCHAR(36) PRIMARY KEY,
    vendor_id VARCHAR(36) NOT NULL,
    item_id VARCHAR(36) NOT NULL,
    vendor_item_code VARCHAR(100),
    last_purchase_price DECIMAL(15,4) DEFAULT 0,
    last_purchase_date DATE,
    is_preferred_vendor TINYINT(1) NOT NULL DEFAULT 0,
    notes TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (vendor_id) REFERENCES vendors(id) ON DELETE CASCADE,
    UNIQUE KEY unique_vendor_item (vendor_id, item_id),
    INDEX idx_vendor_items_vendor (vendor_id),
    INDEX idx_vendor_items_item (item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Multi-Line Procurement Structure
ALTER TABLE procurements ADD COLUMN procurement_number VARCHAR(100);
ALTER TABLE procurements ADD COLUMN purchase_order_id VARCHAR(36);
ALTER TABLE procurements ADD COLUMN subtotal DECIMAL(15,4) DEFAULT 0;
ALTER TABLE procurements ADD COLUMN tax_amount DECIMAL(15,4) DEFAULT 0;
ALTER TABLE procurements ADD COLUMN discount_amount DECIMAL(15,4) DEFAULT 0;

CREATE TABLE IF NOT EXISTS procurement_items (
    id VARCHAR(36) PRIMARY KEY,
    procurement_id VARCHAR(36) NOT NULL,
    item_id VARCHAR(36) NOT NULL,
    quantity DECIMAL(15,4) NOT NULL,
    rate_per_unit DECIMAL(15,4) NOT NULL,
    tax_rate DECIMAL(15,4) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(15,4) NOT NULL DEFAULT 0,
    line_total DECIMAL(15,4) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (procurement_id) REFERENCES procurements(id) ON DELETE CASCADE,
    INDEX idx_procurement_items_proc (procurement_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Backfill procurement_items and vendor_items from legacy procurements
INSERT IGNORE INTO procurement_items (id, procurement_id, item_id, quantity, rate_per_unit, tax_rate, tax_amount, line_total)
SELECT UUID(), id, raw_material_id, quantity, rate_per_unit, 0, 0, (quantity * rate_per_unit)
FROM procurements
WHERE raw_material_id IS NOT NULL;

-- 5. Customer Master Expansion
ALTER TABLE customers ADD COLUMN customer_code VARCHAR(100);
ALTER TABLE customers ADD COLUMN contact_person_name VARCHAR(255);
ALTER TABLE customers ADD COLUMN phone VARCHAR(50);
ALTER TABLE customers ADD COLUMN email VARCHAR(255);
ALTER TABLE customers ADD COLUMN billing_address TEXT;
ALTER TABLE customers ADD COLUMN shipping_address TEXT;
ALTER TABLE customers ADD COLUMN city VARCHAR(100);
ALTER TABLE customers ADD COLUMN state VARCHAR(100);
ALTER TABLE customers ADD COLUMN pincode VARCHAR(20);
ALTER TABLE customers ADD COLUMN country VARCHAR(100) DEFAULT 'India';
ALTER TABLE customers ADD COLUMN gstin VARCHAR(50);
ALTER TABLE customers ADD COLUMN pan VARCHAR(50);
ALTER TABLE customers ADD COLUMN payment_terms VARCHAR(100) DEFAULT 'Net 30';
ALTER TABLE customers ADD COLUMN credit_limit DECIMAL(15,4);
ALTER TABLE customers ADD COLUMN notes TEXT;
ALTER TABLE customers ADD COLUMN status VARCHAR(50) DEFAULT 'Active';

-- 6. Customer-Product Link Table
CREATE TABLE IF NOT EXISTS customer_items (
    id VARCHAR(36) PRIMARY KEY,
    customer_id VARCHAR(36) NOT NULL,
    finished_good_id VARCHAR(36) NOT NULL,
    last_selling_price DECIMAL(15,4) DEFAULT 0,
    last_sale_date DATE,
    notes TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    UNIQUE KEY unique_customer_product (customer_id, finished_good_id),
    INDEX idx_customer_items_customer (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. Sales & GST Invoicing System
ALTER TABLE sales MODIFY COLUMN total_amount DECIMAL(15,4) NOT NULL DEFAULT 0;
ALTER TABLE sales MODIFY COLUMN amount_due DECIMAL(15,4) NOT NULL DEFAULT 0;
ALTER TABLE sales ADD COLUMN invoice_number VARCHAR(100);
ALTER TABLE sales ADD COLUMN due_date DATE;
ALTER TABLE sales ADD COLUMN place_of_supply VARCHAR(100);
ALTER TABLE sales ADD COLUMN subtotal DECIMAL(15,4) DEFAULT 0;
ALTER TABLE sales ADD COLUMN cgst_amount DECIMAL(15,4) DEFAULT 0;
ALTER TABLE sales ADD COLUMN sgst_amount DECIMAL(15,4) DEFAULT 0;
ALTER TABLE sales ADD COLUMN igst_amount DECIMAL(15,4) DEFAULT 0;
ALTER TABLE sales ADD COLUMN total_tax DECIMAL(15,4) DEFAULT 0;
ALTER TABLE sales ADD COLUMN discount_amount DECIMAL(15,4) DEFAULT 0;
ALTER TABLE sales ADD COLUMN pre_rounding_total DECIMAL(15,4) DEFAULT 0;
ALTER TABLE sales ADD COLUMN round_off_amount DECIMAL(15,4) DEFAULT 0;
ALTER TABLE sales ADD COLUMN payment_status VARCHAR(50) DEFAULT 'Unpaid';
ALTER TABLE sales ADD COLUMN terms_and_conditions TEXT;

CREATE TABLE IF NOT EXISTS sales_items (
    id VARCHAR(36) PRIMARY KEY,
    sale_id VARCHAR(36) NOT NULL,
    finished_good_id VARCHAR(36) NOT NULL,
    quantity DECIMAL(15,4) NOT NULL,
    rate_per_unit DECIMAL(15,4) NOT NULL,
    discount_percent DECIMAL(15,4) DEFAULT 0,
    taxable_value DECIMAL(15,4) NOT NULL DEFAULT 0,
    tax_rate DECIMAL(15,4) NOT NULL DEFAULT 0,
    cgst_rate DECIMAL(15,4) DEFAULT 0,
    cgst_amount DECIMAL(15,4) DEFAULT 0,
    sgst_rate DECIMAL(15,4) DEFAULT 0,
    sgst_amount DECIMAL(15,4) DEFAULT 0,
    igst_rate DECIMAL(15,4) DEFAULT 0,
    igst_amount DECIMAL(15,4) DEFAULT 0,
    line_total DECIMAL(15,4) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
    INDEX idx_sales_items_sale (sale_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Backfill sales_items from legacy single-item sales
INSERT IGNORE INTO sales_items (id, sale_id, finished_good_id, quantity, rate_per_unit, taxable_value, line_total)
SELECT UUID(), id, finished_good_id, quantity, rate_per_unit, (quantity * rate_per_unit), (quantity * rate_per_unit)
FROM sales
WHERE finished_good_id IS NOT NULL;

-- 8. Credit Notes Table
CREATE TABLE IF NOT EXISTS credit_notes (
    id VARCHAR(36) PRIMARY KEY,
    credit_note_number VARCHAR(100) NOT NULL UNIQUE,
    sale_id VARCHAR(36),
    customer_id VARCHAR(36),
    date DATE NOT NULL,
    reason TEXT,
    total_amount DECIMAL(15,4) NOT NULL DEFAULT 0,
    notes TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sale_id) REFERENCES sales(id),
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    INDEX idx_credit_notes_customer (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS credit_note_items (
    id VARCHAR(36) PRIMARY KEY,
    credit_note_id VARCHAR(36) NOT NULL,
    finished_good_id VARCHAR(36) NOT NULL,
    quantity DECIMAL(15,4) NOT NULL,
    rate_per_unit DECIMAL(15,4) NOT NULL,
    tax_rate DECIMAL(15,4) DEFAULT 0,
    line_total DECIMAL(15,4) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (credit_note_id) REFERENCES credit_notes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. Purchase Orders & Purchase Order Items
CREATE TABLE IF NOT EXISTS purchase_orders (
    id VARCHAR(36) PRIMARY KEY,
    po_number VARCHAR(100) NOT NULL UNIQUE,
    vendor_id VARCHAR(36) NOT NULL,
    date DATE NOT NULL,
    expected_delivery_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'Draft',
    subtotal DECIMAL(15,4) DEFAULT 0,
    total_tax DECIMAL(15,4) DEFAULT 0,
    total_amount DECIMAL(15,4) DEFAULT 0,
    notes TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (vendor_id) REFERENCES vendors(id),
    INDEX idx_po_vendor (vendor_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS purchase_order_items (
    id VARCHAR(36) PRIMARY KEY,
    po_id VARCHAR(36) NOT NULL,
    item_id VARCHAR(36) NOT NULL,
    quantity DECIMAL(15,4) NOT NULL,
    received_quantity DECIMAL(15,4) NOT NULL DEFAULT 0,
    rate_per_unit DECIMAL(15,4) NOT NULL,
    tax_rate DECIMAL(15,4) DEFAULT 0,
    line_total DECIMAL(15,4) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (po_id) REFERENCES purchase_orders(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. Debit Notes Table
CREATE TABLE IF NOT EXISTS debit_notes (
    id VARCHAR(36) PRIMARY KEY,
    debit_note_number VARCHAR(100) NOT NULL UNIQUE,
    procurement_id VARCHAR(36),
    vendor_id VARCHAR(36),
    date DATE NOT NULL,
    reason TEXT,
    total_amount DECIMAL(15,4) NOT NULL DEFAULT 0,
    notes TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (procurement_id) REFERENCES procurements(id),
    FOREIGN KEY (vendor_id) REFERENCES vendors(id),
    INDEX idx_debit_notes_vendor (vendor_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS debit_note_items (
    id VARCHAR(36) PRIMARY KEY,
    debit_note_id VARCHAR(36) NOT NULL,
    item_id VARCHAR(36) NOT NULL,
    quantity DECIMAL(15,4) NOT NULL,
    rate_per_unit DECIMAL(15,4) NOT NULL,
    tax_rate DECIMAL(15,4) DEFAULT 0,
    line_total DECIMAL(15,4) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (debit_note_id) REFERENCES debit_notes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. Item Unit Conversions
CREATE TABLE IF NOT EXISTS item_unit_conversions (
    id VARCHAR(36) PRIMARY KEY,
    item_id VARCHAR(36) NOT NULL,
    procurement_unit VARCHAR(50) NOT NULL,
    base_unit VARCHAR(50) NOT NULL,
    conversion_factor DECIMAL(15,4) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_item_unit_conversion (item_id, procurement_unit)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 12. Numbering Series Configurations
CREATE TABLE IF NOT EXISTS numbering_series (
    document_type VARCHAR(100) PRIMARY KEY,
    prefix VARCHAR(50) NOT NULL,
    next_number INT NOT NULL DEFAULT 1,
    padding_digits INT NOT NULL DEFAULT 4,
    reset_period VARCHAR(50) NOT NULL DEFAULT 'FY',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Default numbering series seeds
INSERT IGNORE INTO numbering_series (document_type, prefix, next_number, padding_digits, reset_period)
VALUES
  ('invoice', 'INV-', 1, 4, 'FY'),
  ('purchase_order', 'PO-', 1, 4, 'FY'),
  ('credit_note', 'CN-', 1, 4, 'FY'),
  ('debit_note', 'DN-', 1, 4, 'FY'),
  ('procurement', 'PROC-', 1, 4, 'FY'),
  ('vendor', 'VEN-', 1, 4, 'never'),
  ('customer', 'CUST-', 1, 4, 'never'),
  ('item', 'SKU-', 1, 4, 'never');
