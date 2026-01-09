-- Migration: Add per-tool progress tracking
-- Each assignment (Spreadsheet, Python, R) is tracked independently

-- Add per-tool completion columns
ALTER TABLE user_progress ADD COLUMN IF NOT EXISTS completed_spreadsheet BOOLEAN DEFAULT FALSE;
ALTER TABLE user_progress ADD COLUMN IF NOT EXISTS completed_python BOOLEAN DEFAULT FALSE;
ALTER TABLE user_progress ADD COLUMN IF NOT EXISTS completed_r BOOLEAN DEFAULT FALSE;

-- Add per-tool hint usage columns
ALTER TABLE user_progress ADD COLUMN IF NOT EXISTS hint_used_spreadsheet BOOLEAN DEFAULT FALSE;
ALTER TABLE user_progress ADD COLUMN IF NOT EXISTS hint_used_python BOOLEAN DEFAULT FALSE;
ALTER TABLE user_progress ADD COLUMN IF NOT EXISTS hint_used_r BOOLEAN DEFAULT FALSE;

-- Add per-tool answer usage columns
ALTER TABLE user_progress ADD COLUMN IF NOT EXISTS answer_used_spreadsheet BOOLEAN DEFAULT FALSE;
ALTER TABLE user_progress ADD COLUMN IF NOT EXISTS answer_used_python BOOLEAN DEFAULT FALSE;
ALTER TABLE user_progress ADD COLUMN IF NOT EXISTS answer_used_r BOOLEAN DEFAULT FALSE;

-- Add per-tool XP earned columns
ALTER TABLE user_progress ADD COLUMN IF NOT EXISTS xp_earned_spreadsheet INTEGER DEFAULT 0;
ALTER TABLE user_progress ADD COLUMN IF NOT EXISTS xp_earned_python INTEGER DEFAULT 0;
ALTER TABLE user_progress ADD COLUMN IF NOT EXISTS xp_earned_r INTEGER DEFAULT 0;

-- Migrate existing data: set tool-specific columns based on completed_with
UPDATE user_progress
SET
  completed_spreadsheet = CASE WHEN completed_with IN ('spreadsheet', 'both') THEN TRUE ELSE FALSE END,
  completed_python = CASE WHEN completed_with IN ('python', 'both') THEN TRUE ELSE FALSE END,
  xp_earned_spreadsheet = CASE WHEN completed_with IN ('spreadsheet', 'both') THEN xp_earned ELSE 0 END,
  xp_earned_python = CASE WHEN completed_with IN ('python', 'both') THEN xp_earned ELSE 0 END
WHERE is_completed = TRUE;

-- Update is_completed to be TRUE if any tool is completed
-- (This maintains backward compatibility)
CREATE OR REPLACE FUNCTION update_is_completed()
RETURNS TRIGGER AS $$
BEGIN
  NEW.is_completed := NEW.completed_spreadsheet OR NEW.completed_python OR NEW.completed_r;

  -- Update completed_with based on which tools are completed
  IF NEW.completed_spreadsheet AND NEW.completed_python AND NEW.completed_r THEN
    NEW.completed_with := 'all';
  ELSIF (NEW.completed_spreadsheet AND NEW.completed_python) OR
        (NEW.completed_spreadsheet AND NEW.completed_r) OR
        (NEW.completed_python AND NEW.completed_r) THEN
    NEW.completed_with := 'both';
  ELSIF NEW.completed_spreadsheet THEN
    NEW.completed_with := 'spreadsheet';
  ELSIF NEW.completed_python THEN
    NEW.completed_with := 'python';
  ELSIF NEW.completed_r THEN
    NEW.completed_with := 'r';
  ELSE
    NEW.completed_with := NULL;
  END IF;

  -- Update total xp_earned
  NEW.xp_earned := COALESCE(NEW.xp_earned_spreadsheet, 0) +
                   COALESCE(NEW.xp_earned_python, 0) +
                   COALESCE(NEW.xp_earned_r, 0);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-update is_completed and xp_earned
DROP TRIGGER IF EXISTS trigger_update_is_completed ON user_progress;
CREATE TRIGGER trigger_update_is_completed
  BEFORE INSERT OR UPDATE ON user_progress
  FOR EACH ROW
  EXECUTE FUNCTION update_is_completed();

-- Add comments for documentation
COMMENT ON COLUMN user_progress.completed_spreadsheet IS 'Whether the Spreadsheet assignment was completed';
COMMENT ON COLUMN user_progress.completed_python IS 'Whether the Python assignment was completed';
COMMENT ON COLUMN user_progress.completed_r IS 'Whether the R assignment was completed';
COMMENT ON COLUMN user_progress.hint_used_spreadsheet IS 'Whether hint was used for Spreadsheet (30% XP penalty)';
COMMENT ON COLUMN user_progress.hint_used_python IS 'Whether hint was used for Python (30% XP penalty)';
COMMENT ON COLUMN user_progress.hint_used_r IS 'Whether hint was used for R (30% XP penalty)';
COMMENT ON COLUMN user_progress.answer_used_spreadsheet IS 'Whether answer was shown for Spreadsheet (50% XP penalty)';
COMMENT ON COLUMN user_progress.answer_used_python IS 'Whether answer was shown for Python (50% XP penalty)';
COMMENT ON COLUMN user_progress.answer_used_r IS 'Whether answer was shown for R (50% XP penalty)';
COMMENT ON COLUMN user_progress.xp_earned_spreadsheet IS 'XP earned from Spreadsheet assignment';
COMMENT ON COLUMN user_progress.xp_earned_python IS 'XP earned from Python assignment';
COMMENT ON COLUMN user_progress.xp_earned_r IS 'XP earned from R assignment';
