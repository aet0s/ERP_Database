-- Master Migration 012: Add Address & Bank Account Details to Companies
ALTER TABLE companies ADD COLUMN address TEXT NULL;
ALTER TABLE companies ADD COLUMN city VARCHAR(100) NULL;
ALTER TABLE companies ADD COLUMN pincode VARCHAR(20) NULL;
ALTER TABLE companies ADD COLUMN bank_name VARCHAR(255) NULL;
ALTER TABLE companies ADD COLUMN bank_account_name VARCHAR(255) NULL;
ALTER TABLE companies ADD COLUMN bank_account_number VARCHAR(100) NULL;
ALTER TABLE companies ADD COLUMN bank_ifsc VARCHAR(50) NULL;
ALTER TABLE companies ADD COLUMN bank_branch VARCHAR(255) NULL;
