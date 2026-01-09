-- Migration: Add Assignment and Task tables
-- Run this in Supabase SQL Editor
-- Date: 2026-01-09

-- =============================================================================
-- STEP 1: Create new tables for Assignment/Task hierarchy
-- =============================================================================

-- Assignment: Tool-specific implementation within a Section (Spreadsheet, Python, R)
CREATE TABLE IF NOT EXISTS public.assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  section_id UUID REFERENCES public.sections(id) ON DELETE CASCADE NOT NULL,
  tool_type TEXT NOT NULL CHECK (tool_type IN ('spreadsheet', 'python', 'r')),
  display_order INTEGER NOT NULL DEFAULT 1,
  
  -- Content fields
  instructions TEXT,
  hint TEXT,
  xp_reward INTEGER DEFAULT 10,
  
  -- Spreadsheet-specific fields
  template_spreadsheet_id TEXT,
  solution_spreadsheet_id TEXT,
  validation_range TEXT,
  
  -- Code-specific fields (Python/R)
  starter_code TEXT,
  solution_code TEXT,
  validation_config JSONB,
  
  -- Language-specific content (JSON maps lang_code -> content)
  instructions_i18n JSONB DEFAULT '{}',
  hint_i18n JSONB DEFAULT '{}',
  starter_code_i18n JSONB DEFAULT '{}',
  template_spreadsheets_i18n JSONB DEFAULT '{}',
  solution_spreadsheets_i18n JSONB DEFAULT '{}',
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(section_id, tool_type)
);

-- Task: Sequential step within an Assignment with individual XP
CREATE TABLE IF NOT EXISTS public.tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  assignment_id UUID REFERENCES public.assignments(id) ON DELETE CASCADE NOT NULL,
  display_order INTEGER NOT NULL,
  title TEXT NOT NULL,
  instructions TEXT NOT NULL,
  hint TEXT,
  xp_reward INTEGER DEFAULT 5,
  validation_config JSONB NOT NULL,
  
  -- Language-specific content
  title_i18n JSONB DEFAULT '{}',
  instructions_i18n JSONB DEFAULT '{}',
  hint_i18n JSONB DEFAULT '{}',
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Track user progress per task
CREATE TABLE IF NOT EXISTS public.user_task_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  task_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE NOT NULL,
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  xp_earned INTEGER DEFAULT 0,
  attempt_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, task_id)
);

-- =============================================================================
-- STEP 2: Enable Row Level Security
-- =============================================================================

ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_task_progress ENABLE ROW LEVEL SECURITY;

-- Assignments: All authenticated users can view
CREATE POLICY "All users can view assignments"
  ON public.assignments FOR SELECT
  TO authenticated
  USING (TRUE);

-- Tasks: All authenticated users can view
CREATE POLICY "All users can view tasks"
  ON public.tasks FOR SELECT
  TO authenticated
  USING (TRUE);

-- User Task Progress: Users can only see their own progress
CREATE POLICY "Users can view own task progress"
  ON public.user_task_progress FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own task progress"
  ON public.user_task_progress FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own task progress"
  ON public.user_task_progress FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- =============================================================================
-- STEP 3: Migrate existing Section data to Assignments
-- This creates Assignments from existing Section tool-specific data
-- =============================================================================

-- Migrate Spreadsheet assignments from sections where supportsSpreadsheet = true
INSERT INTO public.assignments (
  section_id,
  tool_type,
  display_order,
  instructions,
  hint,
  xp_reward,
  template_spreadsheet_id,
  validation_config,
  starter_code,
  solution_code,
  instructions_i18n,
  hint_i18n,
  template_spreadsheets_i18n,
  solution_spreadsheets_i18n
)
SELECT 
  id AS section_id,
  'spreadsheet' AS tool_type,
  1 AS display_order,
  COALESCE(instructions_spreadsheet, instructions) AS instructions,
  COALESCE(hint_spreadsheet, hint) AS hint,
  COALESCE(NULLIF(xp_reward_spreadsheet, 0), xp_reward, 10) AS xp_reward,
  template_spreadsheet_id,
  NULL AS validation_config,
  NULL AS starter_code,
  NULL AS solution_code,
  jsonb_build_object(
    'en', COALESCE(instructions_spreadsheet, instructions)
  ) AS instructions_i18n,
  jsonb_build_object(
    'en', COALESCE(hint_spreadsheet, hint)
  ) AS hint_i18n,
  jsonb_build_object(
    'en', template_spreadsheet_en,
    'es', template_spreadsheet_es,
    'fr', template_spreadsheet_fr,
    'zh', template_spreadsheet_zh,
    'ru', template_spreadsheet_ru,
    'pt', template_spreadsheet_pt,
    'it', template_spreadsheet_it,
    'ca', template_spreadsheet_ca,
    'ro', template_spreadsheet_ro,
    'de', template_spreadsheet_de,
    'nl', template_spreadsheet_nl
  ) AS template_spreadsheets_i18n,
  jsonb_build_object(
    'en', solution_spreadsheet_en,
    'es', solution_spreadsheet_es
  ) AS solution_spreadsheets_i18n
FROM public.sections
WHERE supports_spreadsheet = TRUE
ON CONFLICT (section_id, tool_type) DO NOTHING;

-- Migrate Python assignments from sections where supportsPython = true
INSERT INTO public.assignments (
  section_id,
  tool_type,
  display_order,
  instructions,
  hint,
  xp_reward,
  starter_code,
  solution_code,
  validation_config,
  instructions_i18n,
  hint_i18n,
  starter_code_i18n
)
SELECT 
  id AS section_id,
  'python' AS tool_type,
  2 AS display_order,
  COALESCE(instructions_python, instructions) AS instructions,
  COALESCE(hint_python, hint) AS hint,
  COALESCE(NULLIF(xp_reward_python, 0), xp_reward, 10) AS xp_reward,
  python_starter_code_en AS starter_code,
  python_solution_code AS solution_code,
  python_validation_config AS validation_config,
  jsonb_build_object(
    'en', COALESCE(instructions_python, instructions)
  ) AS instructions_i18n,
  jsonb_build_object(
    'en', COALESCE(hint_python, hint)
  ) AS hint_i18n,
  jsonb_build_object(
    'en', python_starter_code_en,
    'es', python_starter_code_es
  ) AS starter_code_i18n
FROM public.sections
WHERE supports_python = TRUE
ON CONFLICT (section_id, tool_type) DO NOTHING;

-- =============================================================================
-- STEP 4: Create default Tasks for each Assignment (single task = all instructions)
-- =============================================================================

-- For each assignment, create a single default task that encompasses the whole assignment
INSERT INTO public.tasks (
  assignment_id,
  display_order,
  title,
  instructions,
  hint,
  xp_reward,
  validation_config,
  title_i18n,
  instructions_i18n,
  hint_i18n
)
SELECT 
  a.id AS assignment_id,
  1 AS display_order,
  COALESCE(s.title, 'Complete the exercise') AS title,
  COALESCE(a.instructions, 'Follow the instructions to complete this task.') AS instructions,
  a.hint,
  a.xp_reward,
  COALESCE(a.validation_config, '{}'::jsonb) AS validation_config,
  jsonb_build_object('en', COALESCE(s.title, 'Complete the exercise')) AS title_i18n,
  a.instructions_i18n,
  a.hint_i18n
FROM public.assignments a
JOIN public.sections s ON a.section_id = s.id
ON CONFLICT DO NOTHING;

-- =============================================================================
-- STEP 5: Refresh PostgREST schema cache
-- =============================================================================

NOTIFY pgrst, 'reload schema';

-- =============================================================================
-- VERIFICATION QUERIES (run separately to check migration)
-- =============================================================================

-- Check assignments created
-- SELECT tool_type, COUNT(*) FROM assignments GROUP BY tool_type;

-- Check tasks created
-- SELECT COUNT(*) FROM tasks;

-- Check a sample assignment with its task
-- SELECT a.id, a.tool_type, a.instructions, t.title, t.xp_reward
-- FROM assignments a
-- JOIN tasks t ON t.assignment_id = a.id
-- LIMIT 5;
