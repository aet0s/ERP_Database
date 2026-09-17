-- Alter procurements total_amount and amount_due from generated columns to standard columns
-- to allow accurate calculations including discounts, taxes, and round-offs.

ALTER TABLE procurements MODIFY COLUMN total_amount DECIMAL(15,4) NOT NULL DEFAULT 0.0000;
ALTER TABLE procurements MODIFY COLUMN amount_due DECIMAL(15,4) NOT NULL DEFAULT 0.0000;

UPDATE procurements 
SET 
  total_amount = GREATEST(0, COALESCE(subtotal, 0) + COALESCE(tax_amount, 0) - COALESCE(discount_amount, 0)),
  amount_due = GREATEST(0, (COALESCE(subtotal, 0) + COALESCE(tax_amount, 0) - COALESCE(discount_amount, 0)) - COALESCE(amount_paid, 0))
WHERE subtotal > 0 OR tax_amount > 0 OR discount_amount > 0;
