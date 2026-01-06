-- Add hint column to sections table
ALTER TABLE sections ADD COLUMN IF NOT EXISTS hint TEXT;

-- Add hint_used column to user_progress table to track hint usage
ALTER TABLE user_progress ADD COLUMN IF NOT EXISTS hint_used BOOLEAN DEFAULT false;
