-- Migration 038: Standardize vendor and customer connection_status
ALTER TABLE vendors MODIFY COLUMN connection_status VARCHAR(50) NOT NULL DEFAULT 'not_connected';
ALTER TABLE customers MODIFY COLUMN connection_status VARCHAR(50) NOT NULL DEFAULT 'not_connected';

-- Synchronize existing parties:
-- 1. Parties with a registered/logged-in portal user -> 'connected'
UPDATE vendors SET connection_status = 'connected' WHERE id IN (
  SELECT vendor_id FROM vendor_portal_users WHERE last_login_at IS NOT NULL OR password_hash IS NOT NULL
);
UPDATE customers SET connection_status = 'connected' WHERE id IN (
  SELECT customer_id FROM customer_portal_users WHERE last_login_at IS NOT NULL OR password_hash IS NOT NULL
);

-- 2. Parties with an invite token sent but not logged in -> 'invited'
UPDATE vendors SET connection_status = 'invited' WHERE connection_status != 'connected' AND id IN (
  SELECT vendor_id FROM vendor_portal_users WHERE invite_token IS NOT NULL
);
UPDATE customers SET connection_status = 'invited' WHERE connection_status != 'connected' AND id IN (
  SELECT customer_id FROM customer_portal_users WHERE invite_token IS NOT NULL
);

-- 3. Any parties that were set to legacy 'active' without portal user -> 'not_connected'
UPDATE vendors SET connection_status = 'not_connected' WHERE connection_status = 'active';
UPDATE customers SET connection_status = 'not_connected' WHERE connection_status = 'active';
