-- Master migration 016: Add pan column to global_portal_users
ALTER TABLE global_portal_users ADD COLUMN IF NOT EXISTS pan VARCHAR(50) NULL;
