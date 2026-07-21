-- Run this in your Supabase SQL Editor to add UPI ID support
-- Dashboard → SQL Editor → New query → paste & run

ALTER TABLE user_settings
  ADD COLUMN IF NOT EXISTS store_upi_id TEXT DEFAULT '';
