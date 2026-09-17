-- Migration 032: Production Orders & Staff Shift Logs
-- Adds two-stage production workflow:
--   1. production_orders    — created by Production Manager (what to make, by when)
--   2. production_shift_logs — created by Staff (how much was made per shift)
-- Also adds required_by_date to production_runs for ad-hoc runs with deadlines.

-- ─────────────────────────────────────────────────────────────────────────────
-- PRODUCTION ORDERS (header table)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS production_orders (
    id                  VARCHAR(36)     PRIMARY KEY,
    order_number        VARCHAR(100)    NOT NULL UNIQUE,
    formula_id          VARCHAR(36),
    formula_version     INT             NOT NULL DEFAULT 1,
    target_item_id      VARCHAR(36)     NOT NULL,   -- finished_goods.id
    target_item_type    VARCHAR(50)     NOT NULL DEFAULT 'finished_good',
    target_quantity     DECIMAL(15,4)   NOT NULL,
    target_uom          VARCHAR(50)     NOT NULL DEFAULT 'unit',
    required_by_date    DATE            NOT NULL,
    location_id         VARCHAR(36),
    priority            VARCHAR(20)     NOT NULL DEFAULT 'normal',  -- low | normal | high | urgent
    notes               TEXT,
    status              VARCHAR(30)     NOT NULL DEFAULT 'open',   -- open | in_progress | completed | cancelled
    created_by          VARCHAR(36),
    deleted_at          DATETIME,
    deleted_by          VARCHAR(36),
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (formula_id) REFERENCES production_formulas(id) ON DELETE SET NULL,
    INDEX idx_prod_orders_status        (status),
    INDEX idx_prod_orders_required_date (required_by_date),
    INDEX idx_prod_orders_deleted       (deleted_at),
    INDEX idx_prod_orders_item          (target_item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────────────────────────
-- PRODUCTION SHIFT LOGS (staff-facing shift-by-shift production log)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS production_shift_logs (
    id                  VARCHAR(36)     PRIMARY KEY,
    order_id            VARCHAR(36)     NOT NULL,
    log_date            DATE            NOT NULL,
    shift               VARCHAR(20)     NOT NULL,  -- morning | evening | night
    quantity_produced   DECIMAL(15,4)   NOT NULL,
    uom                 VARCHAR(50)     NOT NULL DEFAULT 'unit',
    notes               TEXT,
    created_by          VARCHAR(36),
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES production_orders(id) ON DELETE CASCADE,
    INDEX idx_shift_logs_order   (order_id),
    INDEX idx_shift_logs_date    (log_date),
    INDEX idx_shift_logs_shift   (shift)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────────────────────────
-- ALTER production_runs — add required_by_date & order_id
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE production_runs
    ADD COLUMN IF NOT EXISTS required_by_date DATE AFTER date,
    ADD COLUMN IF NOT EXISTS order_id VARCHAR(36) AFTER formula_version,
    ADD INDEX IF NOT EXISTS idx_prod_runs_required_date (required_by_date);

-- ─────────────────────────────────────────────────────────────────────────────
-- NUMBERING SERIES FOR PRODUCTION ORDERS
-- ─────────────────────────────────────────────────────────────────────────────
INSERT IGNORE INTO numbering_series (document_type, prefix, next_number, padding_digits, reset_period)
VALUES ('production_order', 'PO-', 1, 4, 'FY');
