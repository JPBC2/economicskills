-- Migration: 003_create_xp_function.sql
-- EconomicSkills - XP Increment Function
-- Run this in Supabase SQL Editor

-- ============================================
-- FUNCTION: Increment User XP
-- Called from Flutter when a section is completed
-- ============================================
CREATE OR REPLACE FUNCTION increment_user_xp(user_id_param UUID, xp_amount INTEGER)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.user_xp
  SET 
    total_xp_earned = total_xp_earned + xp_amount,
    last_updated = NOW()
  WHERE user_id = user_id_param;
  
  -- If no row exists, create one
  IF NOT FOUND THEN
    INSERT INTO public.user_xp (user_id, total_xp_earned)
    VALUES (user_id_param, xp_amount);
  END IF;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION increment_user_xp TO authenticated;
