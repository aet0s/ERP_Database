-- 014_add_number_system_column.sql
-- Add configurable numbering & decimal system for workspace (indian / international)

ALTER TABLE companies ADD COLUMN number_system VARCHAR(32) DEFAULT 'indian';
UPDATE companies SET number_system = 'indian' WHERE number_system IS NULL;
