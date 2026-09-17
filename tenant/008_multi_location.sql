-- Migration 008: Multi-Location / Multi-Warehouse Support
-- This migration adds a `locations` master table, stock transfer support,
-- and nullable location_id columns on all transaction tables.
-- Existing tenants get a "Main Location" created by the application-side
-- data migration script (backend/scripts/migrate_phase6.js).

-- ─────────────────────────────────────────────────────────────────────────────
-- LOCATIONS MASTER
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS locations (
    id              VARCHAR(36)  PRIMARY KEY,
    name            VARCHAR(255) NOT NULL,
    address         TEXT,
    city            VARCHAR(100),
    state           VARCHAR(100),
    is_default      TINYINT(1)   NOT NULL DEFAULT 0,
    status          VARCHAR(50)  NOT NULL DEFAULT 'Active',
    notes           TEXT,
    deleted_at      DATETIME,
    deleted_by      VARCHAR(36),
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_locations_status (status),
    INDEX idx_locations_deleted (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────────────────────────
-- STOCK TRANSFERS
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS stock_transfers (
    id                  VARCHAR(36)     PRIMARY KEY,
    transfer_number     VARCHAR(100)    NOT NULL UNIQUE,
    from_location_id    VARCHAR(36)     NOT NULL,
    to_location_id      VARCHAR(36)     NOT NULL,
    item_type           VARCHAR(50)     NOT NULL,   -- raw_material, finished_good, wip
    item_id             VARCHAR(36)     NOT NULL,
    quantity            DECIMAL(15,4)   NOT NULL,
    notes               TEXT,
    created_by          VARCHAR(36),
    deleted_at          DATETIME,
    deleted_by          VARCHAR(36),
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (from_location_id) REFERENCES locations(id),
    FOREIGN KEY (to_location_id)   REFERENCES locations(id),
    INDEX idx_stock_transfers_from (from_location_id),
    INDEX idx_stock_transfers_to   (to_location_id),
    INDEX idx_stock_transfers_item (item_type, item_id),
    INDEX idx_stock_transfers_date (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────────────────────────
-- USER-LOCATION ASSIGNMENTS (optional access scoping)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_location_assignments (
    id          VARCHAR(36) PRIMARY KEY,
    user_id     VARCHAR(36) NOT NULL,
    location_id VARCHAR(36) NOT NULL,
    created_at  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id)     REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_location (user_id, location_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────────────────────────
-- ADD location_id TO TRANSACTION TABLES
-- ─────────────────────────────────────────────────────────────────────────────
-- All columns are nullable so existing rows are valid (backfilled by data migration)

ALTER TABLE inventory_ledger
    ADD COLUMN IF NOT EXISTS location_id VARCHAR(36) AFTER item_id,
    ADD INDEX IF NOT EXISTS idx_inventory_ledger_location (location_id);

ALTER TABLE procurements
    ADD COLUMN IF NOT EXISTS location_id VARCHAR(36),
    ADD INDEX IF NOT EXISTS idx_procurements_location (location_id);

ALTER TABLE production_batches
    ADD COLUMN IF NOT EXISTS location_id VARCHAR(36),
    ADD INDEX IF NOT EXISTS idx_production_batches_location (location_id);

ALTER TABLE sales
    ADD COLUMN IF NOT EXISTS location_id VARCHAR(36),
    ADD INDEX IF NOT EXISTS idx_sales_location (location_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- NUMBERING SERIES FOR STOCK TRANSFERS
-- ─────────────────────────────────────────────────────────────────────────────
INSERT IGNORE INTO numbering_series (document_type, prefix, next_number, padding_digits, reset_period)
VALUES ('stock_transfer', 'TRF-', 1, 4, 'FY');

-- ─────────────────────────────────────────────────────────────────────────────
-- MIGRATION TRACKING
-- ─────────────────────────────────────────────────────────────────────────────

