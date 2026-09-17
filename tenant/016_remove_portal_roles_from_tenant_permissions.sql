-- Tenant Migration 016: Remove Portal Roles from Tenant Permissions & Add Connection Status
-- 1. Purges vendor and customer from tenant-level permissions (now platform-controlled).
DELETE FROM role_permissions WHERE role IN ('vendor', 'customer');

-- 2. Add connection_status to vendors and customers
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS connection_status VARCHAR(50) NOT NULL DEFAULT 'active';
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS global_user_id VARCHAR(36) NULL;

ALTER TABLE customers ADD COLUMN IF NOT EXISTS connection_status VARCHAR(50) NOT NULL DEFAULT 'active';
ALTER TABLE customers ADD COLUMN IF NOT EXISTS global_user_id VARCHAR(36) NULL;

CREATE INDEX IF NOT EXISTS idx_vendors_conn_status ON vendors(connection_status);
CREATE INDEX IF NOT EXISTS idx_customers_conn_status ON customers(connection_status);
