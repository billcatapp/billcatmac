-- Run this in your Supabase SQL Editor to add product description support
-- Dashboard → SQL Editor → New query → paste & run

ALTER TABLE products
  ADD COLUMN IF NOT EXISTS description TEXT NOT NULL DEFAULT '';
