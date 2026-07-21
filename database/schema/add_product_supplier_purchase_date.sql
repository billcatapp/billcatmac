-- Supplier (dealer) and purchase date for products.
-- Run this once in the Supabase SQL editor.

ALTER TABLE public.products ADD COLUMN IF NOT EXISTS supplier text NOT NULL DEFAULT '';
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS purchase_date timestamptz;
