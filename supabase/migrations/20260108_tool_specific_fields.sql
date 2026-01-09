-- Migration: Add tool-specific Instructions, Hint, and XP Reward fields
-- This allows sections with both Spreadsheet AND Python to have distinct content for each tool

-- Add spreadsheet-specific fields
ALTER TABLE sections ADD COLUMN IF NOT EXISTS instructions_spreadsheet TEXT;
ALTER TABLE sections ADD COLUMN IF NOT EXISTS hint_spreadsheet TEXT;
ALTER TABLE sections ADD COLUMN IF NOT EXISTS xp_reward_spreadsheet INTEGER DEFAULT 10;

-- Add python-specific fields
ALTER TABLE sections ADD COLUMN IF NOT EXISTS instructions_python TEXT;
ALTER TABLE sections ADD COLUMN IF NOT EXISTS hint_python TEXT;
ALTER TABLE sections ADD COLUMN IF NOT EXISTS xp_reward_python INTEGER DEFAULT 10;

-- Migrate existing data: copy current values to tool-specific columns based on what the section supports
UPDATE sections
SET
  instructions_spreadsheet = CASE WHEN supports_spreadsheet THEN instructions ELSE NULL END,
  hint_spreadsheet = CASE WHEN supports_spreadsheet THEN hint ELSE NULL END,
  xp_reward_spreadsheet = CASE WHEN supports_spreadsheet THEN xp_reward ELSE 10 END,
  instructions_python = CASE WHEN supports_python THEN instructions ELSE NULL END,
  hint_python = CASE WHEN supports_python THEN hint ELSE NULL END,
  xp_reward_python = CASE WHEN supports_python THEN xp_reward ELSE 10 END
WHERE instructions IS NOT NULL OR hint IS NOT NULL;

-- Add comments for documentation
COMMENT ON COLUMN sections.instructions_spreadsheet IS 'Tool-specific instructions for spreadsheet exercises';
COMMENT ON COLUMN sections.hint_spreadsheet IS 'Tool-specific hint for spreadsheet exercises (30% XP penalty)';
COMMENT ON COLUMN sections.xp_reward_spreadsheet IS 'XP reward for completing via spreadsheet';
COMMENT ON COLUMN sections.instructions_python IS 'Tool-specific instructions for Python exercises';
COMMENT ON COLUMN sections.hint_python IS 'Tool-specific hint for Python exercises (30% XP penalty)';
COMMENT ON COLUMN sections.xp_reward_python IS 'XP reward for completing via Python';

-- Verify the migration
SELECT
  column_name,
  data_type,
  column_default
FROM information_schema.columns
WHERE table_name = 'sections'
  AND column_name IN (
    'instructions_spreadsheet', 'hint_spreadsheet', 'xp_reward_spreadsheet',
    'instructions_python', 'hint_python', 'xp_reward_python'
  )
ORDER BY column_name;
