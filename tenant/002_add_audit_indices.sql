-- Migration 002: Add performance indices on audit log and inventory ledger
CREATE INDEX idx_inventory_ledger_item_type_id ON inventory_ledger (item_type, item_id);
CREATE INDEX idx_audit_log_user_id ON audit_log (user_id);
