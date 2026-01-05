-- Migration: Add tables and functions for Edge Functions
-- Run this in Supabase SQL Editor

-- User spreadsheets table (links users to their copied spreadsheets)
CREATE TABLE IF NOT EXISTS public.user_spreadsheets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  section_id UUID NOT NULL REFERENCES public.sections(id) ON DELETE CASCADE,
  spreadsheet_id TEXT NOT NULL,
  spreadsheet_url TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  
  CONSTRAINT unique_user_section UNIQUE (user_id, section_id)
);

COMMENT ON TABLE public.user_spreadsheets IS 'Links users to their copied spreadsheets for each section';

-- User progress table
CREATE TABLE IF NOT EXISTS public.user_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  section_id UUID NOT NULL REFERENCES public.sections(id) ON DELETE CASCADE,
  is_completed BOOLEAN DEFAULT false,
  attempt_count INTEGER DEFAULT 0,
  xp_earned INTEGER DEFAULT 0,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  
  CONSTRAINT unique_user_section_progress UNIQUE (user_id, section_id)
);

COMMENT ON TABLE public.user_progress IS 'Tracks user progress through sections';

-- XP transactions table
CREATE TABLE IF NOT EXISTS public.xp_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('earned', 'spent')),
  source_type TEXT NOT NULL,
  source_id UUID,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

COMMENT ON TABLE public.xp_transactions IS 'Records all XP earning and spending transactions';

-- Validation rules table
CREATE TABLE IF NOT EXISTS public.validation_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  section_id UUID NOT NULL REFERENCES public.sections(id) ON DELETE CASCADE,
  rule_type TEXT NOT NULL,
  rule_config JSONB NOT NULL,
  display_order INTEGER DEFAULT 1,
  error_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

COMMENT ON TABLE public.validation_rules IS 'Validation rules for section exercises';

-- Add xp_reward column to sections if not exists
ALTER TABLE public.sections 
ADD COLUMN IF NOT EXISTS xp_reward INTEGER DEFAULT 10;

ALTER TABLE public.sections 
ADD COLUMN IF NOT EXISTS template_spreadsheet_id TEXT;

-- Function to add XP to user
CREATE OR REPLACE FUNCTION public.add_user_xp(
  p_user_id UUID,
  p_xp_amount INTEGER
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.user_xp (user_id, total_xp_earned, total_xp_spent)
  VALUES (p_user_id, p_xp_amount, 0)
  ON CONFLICT (user_id)
  DO UPDATE SET 
    total_xp_earned = user_xp.total_xp_earned + p_xp_amount,
    updated_at = now();
END;
$$;

-- RLS Policies

-- user_spreadsheets
ALTER TABLE public.user_spreadsheets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own spreadsheets"
  ON public.user_spreadsheets FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Service role can manage spreadsheets"
  ON public.user_spreadsheets FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- user_progress
ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own progress"
  ON public.user_progress FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Service role can manage progress"
  ON public.user_progress FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- xp_transactions
ALTER TABLE public.xp_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own transactions"
  ON public.xp_transactions FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Service role can manage transactions"
  ON public.xp_transactions FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- validation_rules
ALTER TABLE public.validation_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read validation rules"
  ON public.validation_rules FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Service role can manage rules"
  ON public.validation_rules FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_spreadsheets_user ON public.user_spreadsheets(user_id);
CREATE INDEX IF NOT EXISTS idx_user_spreadsheets_section ON public.user_spreadsheets(section_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_user ON public.user_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_section ON public.user_progress(section_id);
CREATE INDEX IF NOT EXISTS idx_xp_transactions_user ON public.xp_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_validation_rules_section ON public.validation_rules(section_id);
