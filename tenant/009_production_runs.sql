-- Migration 009: Simplified 2-Stage Production with Multi-Output
-- Introduces `production_runs`, `production_run_inputs`, `production_run_outputs`
-- to replace the complex multi-stage production_batches workflow.
-- Historical production_batches data is preserved and migrated to production_runs
-- by the application-side data migration script (backend/scripts/migrate_phase6.js).

-- ─────────────────────────────────────────────────────────────────────────────
-- PRODUCTION RUNS (header)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS production_runs (
    id              VARCHAR(36)     PRIMARY KEY,
    run_number      VARCHAR(100)    NOT NULL UNIQUE,
    date            DATE            NOT NULL,
    location_id     VARCHAR(36),
    labor_cost      DECIMAL(15,4)   NOT NULL DEFAULT 0,
    other_cost      DECIMAL(15,4)   NOT NULL DEFAULT 0,
    total_input_cost DECIMAL(15,4)  NOT NULL DEFAULT 0,  -- computed: raw mat cost + labor + other
    notes           TEXT,
    status          VARCHAR(50)     NOT NULL DEFAULT 'Completed',  -- Completed is the only status for MVP
    migrated_from_batch_id VARCHAR(36),  -- set when created via data migration
    created_by      VARCHAR(36),
    deleted_at      DATETIME,
    deleted_by      VARCHAR(36),
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_production_runs_date     (date),
    INDEX idx_production_runs_deleted  (deleted_at),
    INDEX idx_production_runs_location (location_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────────────────────────
-- PRODUCTION RUN INPUTS (multiple raw materials per run)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS production_run_inputs (
    id              VARCHAR(36)     PRIMARY KEY,
    run_id          VARCHAR(36)     NOT NULL,
    item_type       VARCHAR(50)     NOT NULL DEFAULT 'raw_material',  -- raw_material or wip
    item_id         VARCHAR(36)     NOT NULL,   -- raw_material_id or items.id
    quantity        DECIMAL(15,4)   NOT NULL,
    unit_cost       DECIMAL(15,4)   NOT NULL DEFAULT 0,  -- weighted-avg cost at time of run
    line_total_cost DECIMAL(15,4)   NOT NULL DEFAULT 0,  -- quantity * unit_cost
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (run_id) REFERENCES production_runs(id) ON DELETE CASCADE,
    INDEX idx_run_inputs_run_id  (run_id),
    INDEX idx_run_inputs_item    (item_type, item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────────────────────────
-- PRODUCTION RUN OUTPUTS (multiple finished goods per run)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS production_run_outputs (
    id                      VARCHAR(36)     PRIMARY KEY,
    run_id                  VARCHAR(36)     NOT NULL,
    item_type               VARCHAR(50)     NOT NULL DEFAULT 'finished_good', -- finished_good or wip
    item_id                 VARCHAR(36)     NOT NULL,   -- finished_good_id or items.id
    quantity_produced       DECIMAL(15,4)   NOT NULL,
    unit                    VARCHAR(50)     NOT NULL,
    cost_allocation_percent DECIMAL(7,4)    NOT NULL DEFAULT 0,  -- % of total run cost
    allocated_cost          DECIMAL(15,4)   NOT NULL DEFAULT 0,  -- absolute cost allocated to this output
    unit_cost               DECIMAL(15,4)   NOT NULL DEFAULT 0,  -- per-unit cost
    created_at              DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (run_id) REFERENCES production_runs(id) ON DELETE CASCADE,
    INDEX idx_run_outputs_run_id (run_id),
    INDEX idx_run_outputs_item   (item_type, item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────────────────────────
-- ARCHIVE MARKER on process_stages (no data dropped; just marks deprecated)
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE process_stages
    ADD COLUMN IF NOT EXISTS archived_at DATETIME COMMENT 'Set when stage concept was deprecated in Phase 6. Historical data preserved.';

-- ─────────────────────────────────────────────────────────────────────────────
-- NUMBERING SERIES FOR PRODUCTION RUNS
-- ─────────────────────────────────────────────────────────────────────────────
INSERT IGNORE INTO numbering_series (document_type, prefix, next_number, padding_digits, reset_period)
VALUES ('production_run', 'RUN-', 1, 4, 'FY');

-- ─────────────────────────────────────────────────────────────────────────────
-- MIGRATION TRACKING
-- ─────────────────────────────────────────────────────────────────────────────

