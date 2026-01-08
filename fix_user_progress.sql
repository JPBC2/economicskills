-- Fix missing columns in user_progress table
-- Run ALL of these in Supabase SQL Editor

-- Add is_completed column if missing
ALTER TABLE user_progress ADD COLUMN IF NOT EXISTS is_completed BOOLEAN DEFAULT false;

-- Add xp_earned column if missing
ALTER TABLE user_progress ADD COLUMN IF NOT EXISTS xp_earned INTEGER DEFAULT 0;

-- Add attempt_count column if missing
ALTER TABLE user_progress ADD COLUMN IF NOT EXISTS attempt_count INTEGER DEFAULT 0;

-- Verify all columns exist
SELECT column_name, data_type, column_default
FROM information_schema.columns 
WHERE table_name = 'user_progress'
ORDER BY ordinal_position;

-- Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';
