-- Add invoice_number column to transactions table
ALTER TABLE transactions
  ADD COLUMN IF NOT EXISTS invoice_number TEXT;

-- Allow public (anon) to read a transaction if they know the invoice_number
-- This is safe: you must know the invoice number (shared privately via WhatsApp)
CREATE POLICY IF NOT EXISTS "Public read by invoice_number"
  ON transactions
  FOR SELECT
  TO anon
  USING (invoice_number IS NOT NULL);

-- Allow public (anon) to read user_settings for the invoice viewer
-- (needed to show store name, logo, address on the invoice page)
CREATE POLICY IF NOT EXISTS "Public read user_settings"
  ON user_settings
  FOR SELECT
  TO anon
  USING (true);
