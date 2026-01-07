-- Migration: Add Python exercise support
-- This allows sections to support Python code exercises alongside or instead of spreadsheets

-- Add exercise type flags to sections
ALTER TABLE public.sections
ADD COLUMN IF NOT EXISTS supports_spreadsheet BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS supports_python BOOLEAN DEFAULT false;

COMMENT ON COLUMN public.sections.supports_spreadsheet IS 'Whether this section can be completed with Google Sheets';
COMMENT ON COLUMN public.sections.supports_python IS 'Whether this section can be completed with Python code';

-- Add Python starter code columns for each language
ALTER TABLE public.sections
ADD COLUMN IF NOT EXISTS python_starter_code_en TEXT,
ADD COLUMN IF NOT EXISTS python_starter_code_es TEXT,
ADD COLUMN IF NOT EXISTS python_starter_code_zh TEXT,
ADD COLUMN IF NOT EXISTS python_starter_code_ru TEXT,
ADD COLUMN IF NOT EXISTS python_starter_code_fr TEXT,
ADD COLUMN IF NOT EXISTS python_starter_code_pt TEXT,
ADD COLUMN IF NOT EXISTS python_starter_code_it TEXT,
ADD COLUMN IF NOT EXISTS python_starter_code_ca TEXT,
ADD COLUMN IF NOT EXISTS python_starter_code_ro TEXT,
ADD COLUMN IF NOT EXISTS python_starter_code_de TEXT,
ADD COLUMN IF NOT EXISTS python_starter_code_nl TEXT;

-- Add Python solution code (admin reference only, not exposed to students)
ALTER TABLE public.sections
ADD COLUMN IF NOT EXISTS python_solution_code TEXT;

-- Add Python validation configuration (JSONB for flexible validation rules)
ALTER TABLE public.sections
ADD COLUMN IF NOT EXISTS python_validation_config JSONB;

COMMENT ON COLUMN public.sections.python_starter_code_en IS 'English Python starter code shown to students';
COMMENT ON COLUMN public.sections.python_starter_code_es IS 'Spanish Python starter code shown to students';
COMMENT ON COLUMN public.sections.python_starter_code_zh IS 'Chinese Python starter code shown to students';
COMMENT ON COLUMN public.sections.python_starter_code_ru IS 'Russian Python starter code shown to students';
COMMENT ON COLUMN public.sections.python_starter_code_fr IS 'French Python starter code shown to students';
COMMENT ON COLUMN public.sections.python_starter_code_pt IS 'Portuguese Python starter code shown to students';
COMMENT ON COLUMN public.sections.python_starter_code_it IS 'Italian Python starter code shown to students';
COMMENT ON COLUMN public.sections.python_starter_code_ca IS 'Catalan Python starter code shown to students';
COMMENT ON COLUMN public.sections.python_starter_code_ro IS 'Romanian Python starter code shown to students';
COMMENT ON COLUMN public.sections.python_starter_code_de IS 'German Python starter code shown to students';
COMMENT ON COLUMN public.sections.python_starter_code_nl IS 'Dutch Python starter code shown to students';
COMMENT ON COLUMN public.sections.python_solution_code IS 'Python solution code (admin reference only)';
COMMENT ON COLUMN public.sections.python_validation_config IS 'JSON validation configuration for Python exercises';

-- Add tracking for which tool was used to complete the section
ALTER TABLE public.user_progress
ADD COLUMN IF NOT EXISTS completed_with TEXT CHECK (completed_with IN ('spreadsheet', 'python', 'both'));

COMMENT ON COLUMN public.user_progress.completed_with IS 'Which tool the user used to complete: spreadsheet, python, or both';

-- Add hint_used column if it doesn't exist (may have been added in hints migration)
ALTER TABLE public.user_progress
ADD COLUMN IF NOT EXISTS hint_used BOOLEAN DEFAULT false;

-- Example python_validation_config structure:
-- {
--   "validation_type": "simple",  // 'simple' or 'pythonwhat'
--   "steps": [
--     {
--       "step": 1,
--       "type": "variable_value",
--       "name": "mean_price",
--       "expected": 42.5,
--       "tolerance": 0.01,
--       "message_en": "Calculate the mean using df['price'].mean()",
--       "message_es": "Calcula la media usando df['price'].mean()"
--     },
--     {
--       "step": 2,
--       "type": "variable_type",
--       "name": "df",
--       "expected_type": "DataFrame",
--       "message_en": "Load the data into a pandas DataFrame"
--     },
--     {
--       "step": 3,
--       "type": "output_contains",
--       "pattern": "Mean.*\\d+\\.\\d+",
--       "message_en": "Print the mean value with a label"
--     }
--   ]
-- }

-- Or for pythonwhat:
-- {
--   "validation_type": "pythonwhat",
--   "sct_code": "Ex().check_object('mean').has_equal_value()"
-- }
