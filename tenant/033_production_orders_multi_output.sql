-- Migration 033: Production Orders Multi-Output & Shift Logging by Item
-- Enables a single production order to track multiple finished product outputs
-- and logs shift production yields attributed to specific finished products.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. PRODUCTION ORDER OUTPUTS (child table for multiple finished goods per order)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS production_order_outputs (
    id                  VARCHAR(36)     PRIMARY KEY,
    order_id            VARCHAR(36)     NOT NULL,
    item_id             VARCHAR(36)     NOT NULL,   -- finished_goods.id or items.id
    item_type           VARCHAR(50)     NOT NULL DEFAULT 'finished_good',
    target_quantity     DECIMAL(15,4)   NOT NULL,
    uom                 VARCHAR(50)     NOT NULL DEFAULT 'unit',
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES production_orders(id) ON DELETE CASCADE,
    INDEX idx_prod_order_outputs_order (order_id),
    INDEX idx_prod_order_outputs_item  (item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. ALTER production_shift_logs — add item_id
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE production_shift_logs
    ADD COLUMN IF NOT EXISTS item_id VARCHAR(36) AFTER order_id,
    ADD INDEX IF NOT EXISTS idx_shift_logs_item (item_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. BACKFILL DATA
-- ─────────────────────────────────────────────────────────────────────────────

-- Backfill outputs from existing single-item production_orders
INSERT IGNORE INTO production_order_outputs (id, order_id, item_id, item_type, target_quantity, uom)
SELECT UUID(), po.id, po.target_item_id, po.target_item_type, po.target_quantity, po.target_uom
FROM production_orders po
WHERE NOT EXISTS (
    SELECT 1 FROM production_order_outputs poo WHERE poo.order_id = po.id AND poo.item_id = po.target_item_id
);

-- Backfill item_id on existing shift logs from parent production_orders
UPDATE production_shift_logs psl
JOIN production_orders po ON po.id = psl.order_id
SET psl.item_id = po.target_item_id
WHERE psl.item_id IS NULL;
