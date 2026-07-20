-- Adds product variants support (Size/Color etc. each with own price, stock, SKU).
-- Stored as a JSON string in a text column to match the local SQLite schema.
-- Run this in the Supabase SQL editor.

ALTER TABLE products
  ADD COLUMN IF NOT EXISTS variants text NOT NULL DEFAULT '[]';
