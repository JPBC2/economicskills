-- Migration: Add missing columns to lessons and units tables
-- Run this in Supabase SQL Editor

-- Add missing columns to lessons table
ALTER TABLE public.lessons 
ADD COLUMN IF NOT EXISTS explanation_text TEXT,
ADD COLUMN IF NOT EXISTS youtube_video_url TEXT,
ADD COLUMN IF NOT EXISTS source_references TEXT,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Add is_active to units table
ALTER TABLE public.units 
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Copy description to explanation_text for existing records (optional)
UPDATE public.lessons SET explanation_text = description WHERE explanation_text IS NULL AND description IS NOT NULL;

-- Add comments
COMMENT ON COLUMN public.lessons.explanation_text IS 'Detailed explanation text for the lesson';
COMMENT ON COLUMN public.lessons.youtube_video_url IS 'Optional YouTube video URL for the lesson';
COMMENT ON COLUMN public.lessons.source_references IS 'Academic or source references for the lesson content';
COMMENT ON COLUMN public.lessons.is_active IS 'Whether the lesson is visible to students';
COMMENT ON COLUMN public.units.is_active IS 'Whether the unit is visible to students';
