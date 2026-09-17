-- Master Migration 013: Add Currency to Companies
ALTER TABLE companies ADD COLUMN currency VARCHAR(10) NOT NULL DEFAULT 'INR';
