-- Migration: Add language-specific template and solution spreadsheet columns
-- This allows each section to have different spreadsheet templates for each language

-- Add template spreadsheet columns for each language
ALTER TABLE public.sections
ADD COLUMN IF NOT EXISTS template_spreadsheet_en TEXT,
ADD COLUMN IF NOT EXISTS template_spreadsheet_es TEXT,
ADD COLUMN IF NOT EXISTS template_spreadsheet_zh TEXT,
ADD COLUMN IF NOT EXISTS template_spreadsheet_ru TEXT,
ADD COLUMN IF NOT EXISTS template_spreadsheet_fr TEXT,
ADD COLUMN IF NOT EXISTS template_spreadsheet_pt TEXT,
ADD COLUMN IF NOT EXISTS template_spreadsheet_it TEXT,
ADD COLUMN IF NOT EXISTS template_spreadsheet_ca TEXT,
ADD COLUMN IF NOT EXISTS template_spreadsheet_ro TEXT,
ADD COLUMN IF NOT EXISTS template_spreadsheet_de TEXT,
ADD COLUMN IF NOT EXISTS template_spreadsheet_nl TEXT;

-- Add solution spreadsheet columns for each language
ALTER TABLE public.sections
ADD COLUMN IF NOT EXISTS solution_spreadsheet_en TEXT,
ADD COLUMN IF NOT EXISTS solution_spreadsheet_es TEXT,
ADD COLUMN IF NOT EXISTS solution_spreadsheet_zh TEXT,
ADD COLUMN IF NOT EXISTS solution_spreadsheet_ru TEXT,
ADD COLUMN IF NOT EXISTS solution_spreadsheet_fr TEXT,
ADD COLUMN IF NOT EXISTS solution_spreadsheet_pt TEXT,
ADD COLUMN IF NOT EXISTS solution_spreadsheet_it TEXT,
ADD COLUMN IF NOT EXISTS solution_spreadsheet_ca TEXT,
ADD COLUMN IF NOT EXISTS solution_spreadsheet_ro TEXT,
ADD COLUMN IF NOT EXISTS solution_spreadsheet_de TEXT,
ADD COLUMN IF NOT EXISTS solution_spreadsheet_nl TEXT;

-- Migrate existing template_spreadsheet_id to English column
UPDATE public.sections 
SET template_spreadsheet_en = template_spreadsheet_id
WHERE template_spreadsheet_id IS NOT NULL AND template_spreadsheet_en IS NULL;

-- Add comments for documentation
COMMENT ON COLUMN public.sections.template_spreadsheet_en IS 'English template spreadsheet ID';
COMMENT ON COLUMN public.sections.template_spreadsheet_es IS 'Spanish template spreadsheet ID';
COMMENT ON COLUMN public.sections.template_spreadsheet_zh IS 'Chinese template spreadsheet ID';
COMMENT ON COLUMN public.sections.template_spreadsheet_ru IS 'Russian template spreadsheet ID';
COMMENT ON COLUMN public.sections.template_spreadsheet_fr IS 'French template spreadsheet ID';
COMMENT ON COLUMN public.sections.template_spreadsheet_pt IS 'Portuguese template spreadsheet ID';
COMMENT ON COLUMN public.sections.template_spreadsheet_it IS 'Italian template spreadsheet ID';
COMMENT ON COLUMN public.sections.template_spreadsheet_ca IS 'Catalan template spreadsheet ID';
COMMENT ON COLUMN public.sections.template_spreadsheet_ro IS 'Romanian template spreadsheet ID';
COMMENT ON COLUMN public.sections.template_spreadsheet_de IS 'German template spreadsheet ID';
COMMENT ON COLUMN public.sections.template_spreadsheet_nl IS 'Dutch template spreadsheet ID';

COMMENT ON COLUMN public.sections.solution_spreadsheet_en IS 'English solution spreadsheet ID';
COMMENT ON COLUMN public.sections.solution_spreadsheet_es IS 'Spanish solution spreadsheet ID';
COMMENT ON COLUMN public.sections.solution_spreadsheet_zh IS 'Chinese solution spreadsheet ID';
COMMENT ON COLUMN public.sections.solution_spreadsheet_ru IS 'Russian solution spreadsheet ID';
COMMENT ON COLUMN public.sections.solution_spreadsheet_fr IS 'French solution spreadsheet ID';
COMMENT ON COLUMN public.sections.solution_spreadsheet_pt IS 'Portuguese solution spreadsheet ID';
COMMENT ON COLUMN public.sections.solution_spreadsheet_it IS 'Italian solution spreadsheet ID';
COMMENT ON COLUMN public.sections.solution_spreadsheet_ca IS 'Catalan solution spreadsheet ID';
COMMENT ON COLUMN public.sections.solution_spreadsheet_ro IS 'Romanian solution spreadsheet ID';
COMMENT ON COLUMN public.sections.solution_spreadsheet_de IS 'German solution spreadsheet ID';
COMMENT ON COLUMN public.sections.solution_spreadsheet_nl IS 'Dutch solution spreadsheet ID';
