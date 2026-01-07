-- Migration: Add slug column to lessons table
-- Run this in Supabase SQL Editor

-- 1. Add slug column (initially nullable to populate it)
ALTER TABLE public.lessons 
ADD COLUMN IF NOT EXISTS slug TEXT;

-- 2. Create function to generate slugs
CREATE OR REPLACE FUNCTION public.generate_slug(title TEXT) 
RETURNS TEXT AS $$
BEGIN
  -- Lowercase, replace spaces with underscores, remove special chars
  RETURN regexp_replace(
    regexp_replace(
      lower(title), 
      '[^a-z0-9\s_-]', '', 'g'
    ), 
    '\s+', '_', 'g'
  );
END;
$$ LANGUAGE plpgsql;

-- 3. Populate slugs for existing lessons
UPDATE public.lessons 
SET slug = public.generate_slug(title)
WHERE slug IS NULL;

-- 4. Add unique constraint and NOT NULL
ALTER TABLE public.lessons 
ALTER COLUMN slug SET NOT NULL;

ALTER TABLE public.lessons 
ADD CONSTRAINT lessons_slug_key UNIQUE (slug);

-- 5. Add comment
COMMENT ON COLUMN public.lessons.slug IS 'URL-friendly identifier for the lesson';
