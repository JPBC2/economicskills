-- Fix section_type check constraint to allow 'both'
-- Run this in Supabase SQL Editor

-- Step 1: Drop the old constraint
ALTER TABLE sections DROP CONSTRAINT IF EXISTS sections_section_type_check;

-- Step 2: Add updated constraint that allows 'both'
ALTER TABLE sections ADD CONSTRAINT sections_section_type_check 
  CHECK (section_type IN ('python', 'spreadsheet', 'both'));

-- Step 3: Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- Step 4: Verify the constraint was updated
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conname = 'sections_section_type_check';
