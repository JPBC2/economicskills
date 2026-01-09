-- Add R language support columns to sections table
-- Run this in Supabase SQL Editor

-- Add R support flag
ALTER TABLE sections ADD COLUMN IF NOT EXISTS supports_r BOOLEAN DEFAULT false;

-- Add R-specific content fields
ALTER TABLE sections ADD COLUMN IF NOT EXISTS instructions_r TEXT;
ALTER TABLE sections ADD COLUMN IF NOT EXISTS hint_r TEXT;
ALTER TABLE sections ADD COLUMN IF NOT EXISTS xp_reward_r INTEGER DEFAULT 10;

-- Add R code fields
ALTER TABLE sections ADD COLUMN IF NOT EXISTS r_starter_code_en TEXT;
ALTER TABLE sections ADD COLUMN IF NOT EXISTS r_starter_code_es TEXT;
ALTER TABLE sections ADD COLUMN IF NOT EXISTS r_starter_code_zh TEXT;
ALTER TABLE sections ADD COLUMN IF NOT EXISTS r_starter_code_ru TEXT;
ALTER TABLE sections ADD COLUMN IF NOT EXISTS r_starter_code_fr TEXT;
ALTER TABLE sections ADD COLUMN IF NOT EXISTS r_starter_code_pt TEXT;
ALTER TABLE sections ADD COLUMN IF NOT EXISTS r_starter_code_it TEXT;
ALTER TABLE sections ADD COLUMN IF NOT EXISTS r_starter_code_ca TEXT;
ALTER TABLE sections ADD COLUMN IF NOT EXISTS r_starter_code_ro TEXT;
ALTER TABLE sections ADD COLUMN IF NOT EXISTS r_starter_code_de TEXT;
ALTER TABLE sections ADD COLUMN IF NOT EXISTS r_starter_code_nl TEXT;

ALTER TABLE sections ADD COLUMN IF NOT EXISTS r_solution_code TEXT;
ALTER TABLE sections ADD COLUMN IF NOT EXISTS r_validation_config JSONB;

-- Update section_type constraint to include 'r' and 'all'
ALTER TABLE sections DROP CONSTRAINT IF EXISTS sections_section_type_check;
ALTER TABLE sections ADD CONSTRAINT sections_section_type_check 
  CHECK (section_type IN ('spreadsheet', 'python', 'r', 'both', 'all'));

-- Verify columns were added
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'sections' 
  AND column_name LIKE '%r%'
ORDER BY column_name;
