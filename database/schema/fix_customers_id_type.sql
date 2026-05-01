-- Fix customers.id column type from uuid to text
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/xawpxbhglzhaibmcpwho/sql

ALTER TABLE customers ALTER COLUMN id TYPE text;
