-- Add explanation column to sections table
ALTER TABLE sections ADD COLUMN IF NOT EXISTS explanation TEXT;
