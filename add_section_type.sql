-- Add section_type column to sections table
ALTER TABLE sections ADD COLUMN IF NOT EXISTS section_type TEXT NOT NULL DEFAULT 'spreadsheet';

-- Add check constraint for valid values
ALTER TABLE sections DROP CONSTRAINT IF EXISTS sections_section_type_check;
ALTER TABLE sections ADD CONSTRAINT sections_section_type_check 
  CHECK (section_type IN ('python', 'spreadsheet'));

-- Migrate existing data: if supports_python is true, set type to 'python'
UPDATE sections SET section_type = 'python' WHERE supports_python = true;

-- Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';
