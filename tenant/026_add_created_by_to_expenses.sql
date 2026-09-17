-- Migration 026: Add created_by column to expenses
ALTER TABLE expenses ADD COLUMN created_by VARCHAR(36) NULL AFTER notes;

-- Backfill existing expenses with user_id from audit_log if available
UPDATE expenses e
JOIN audit_log a ON a.entity_type = 'expense' AND a.entity_id = e.id AND a.action = 'create'
SET e.created_by = a.user_id
WHERE e.created_by IS NULL AND a.user_id IS NOT NULL;
