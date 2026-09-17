-- Master Migration 011: Company Connect Code & Bidirectional Connection Model
-- Gives each workspace a unique shareable Company Connect Code and adds initiated_by to memberships.

ALTER TABLE companies ADD COLUMN IF NOT EXISTS connect_code VARCHAR(50) NULL;
ALTER TABLE companies ADD UNIQUE INDEX IF NOT EXISTS uk_company_connect_code (connect_code);

-- Backfill connect_code with company_code for existing companies
UPDATE companies SET connect_code = company_code WHERE connect_code IS NULL;

-- Add initiated_by to global_portal_memberships ('workspace' or 'partner')
ALTER TABLE global_portal_memberships ADD COLUMN IF NOT EXISTS initiated_by VARCHAR(20) NOT NULL DEFAULT 'workspace';
ALTER TABLE global_portal_memberships ADD COLUMN IF NOT EXISTS notes TEXT NULL;
