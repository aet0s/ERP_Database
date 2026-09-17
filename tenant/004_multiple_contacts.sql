-- Migration 004: Support Multiple Contacts & JSON Contacts Array for Vendors & Customers
ALTER TABLE vendors ADD COLUMN contacts JSON;
ALTER TABLE customers ADD COLUMN contacts JSON;
