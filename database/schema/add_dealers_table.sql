-- Dealers (suppliers you buy stock from)
-- Run this once in the Supabase SQL editor.

CREATE TABLE IF NOT EXISTS public.dealers (
  id              text PRIMARY KEY,
  user_id         uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name            text NOT NULL,
  phone           text,
  company         text DEFAULT '',
  total_purchased numeric NOT NULL DEFAULT 0,
  balance_payable numeric NOT NULL DEFAULT 0,
  created_at      timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.dealers ENABLE ROW LEVEL SECURITY;

-- Each user can only see and manage their own dealers
DROP POLICY IF EXISTS "Users manage own dealers" ON public.dealers;
CREATE POLICY "Users manage own dealers" ON public.dealers
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
