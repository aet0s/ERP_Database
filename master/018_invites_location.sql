-- Master Migration 018: Add location_id to company_invites
ALTER TABLE company_invites ADD COLUMN IF NOT EXISTS location_id VARCHAR(36) NULL;
