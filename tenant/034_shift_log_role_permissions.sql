-- 034_shift_log_role_permissions.sql
-- Seed default permissions for shift_log module across standard roles

INSERT INTO role_permissions (id, role, module, can_view, can_create, can_edit, can_delete, can_approve, can_export)
VALUES
  ('owner_shift_log', 'owner', 'shift_log', 1, 1, 1, 1, 1, 1),
  ('manager_shift_log', 'manager', 'shift_log', 1, 1, 1, 1, 1, 1),
  ('production_manager_shift_log', 'production_manager', 'shift_log', 1, 1, 1, 1, 1, 1),
  ('staff_shift_log', 'staff', 'shift_log', 1, 1, 0, 0, 0, 0),
  ('accounts_shift_log', 'accounts', 'shift_log', 1, 0, 0, 0, 0, 1),
  ('sales_manager_shift_log', 'sales_manager', 'shift_log', 0, 0, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE
  can_view = VALUES(can_view),
  can_create = VALUES(can_create),
  can_edit = VALUES(can_edit),
  can_delete = VALUES(can_delete),
  can_approve = VALUES(can_approve),
  can_export = VALUES(can_export);
