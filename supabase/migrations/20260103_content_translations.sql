-- Migration: Add content translations table
-- Run this in Supabase SQL Editor

-- Create content translations table
CREATE TABLE IF NOT EXISTS public.content_translations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type TEXT NOT NULL,
  entity_id UUID NOT NULL,
  language TEXT NOT NULL,
  field TEXT NOT NULL,
  value TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  
  -- Enforce valid languages
  CONSTRAINT valid_language CHECK (language IN ('en', 'es', 'fr', 'zh', 'ru', 'pt')),
  
  -- Enforce valid entity types
  CONSTRAINT valid_entity_type CHECK (entity_type IN ('course', 'unit', 'lesson', 'exercise', 'section')),
  
  -- Unique translation per entity/language/field
  CONSTRAINT unique_translation UNIQUE (entity_type, entity_id, language, field)
);

-- Add comments
COMMENT ON TABLE public.content_translations IS 'Stores multilingual translations for course content';
COMMENT ON COLUMN public.content_translations.entity_type IS 'Type of entity: course, unit, lesson, exercise, section';
COMMENT ON COLUMN public.content_translations.entity_id IS 'UUID of the entity being translated';
COMMENT ON COLUMN public.content_translations.language IS 'Language code: en, es, fr, zh, ru, pt';
COMMENT ON COLUMN public.content_translations.field IS 'Field being translated: title, description, instructions, explanation_text';
COMMENT ON COLUMN public.content_translations.value IS 'Translated content';

-- Create indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_translations_entity 
  ON public.content_translations(entity_type, entity_id);
  
CREATE INDEX IF NOT EXISTS idx_translations_language 
  ON public.content_translations(language);

CREATE INDEX IF NOT EXISTS idx_translations_lookup 
  ON public.content_translations(entity_type, entity_id, language);

-- Enable Row Level Security
ALTER TABLE public.content_translations ENABLE ROW LEVEL SECURITY;

-- Allow anyone authenticated to read translations
CREATE POLICY "Anyone can read translations"
  ON public.content_translations 
  FOR SELECT
  TO authenticated
  USING (true);

-- Allow public read for unauthenticated users (students browsing)
CREATE POLICY "Public can read translations"
  ON public.content_translations 
  FOR SELECT
  TO anon
  USING (true);

-- Allow authenticated users to write translations (admin check can be added later)
CREATE POLICY "Authenticated users can insert translations"
  ON public.content_translations 
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update translations"
  ON public.content_translations 
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Authenticated users can delete translations"
  ON public.content_translations 
  FOR DELETE
  TO authenticated
  USING (true);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_translation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_content_translations_timestamp
  BEFORE UPDATE ON public.content_translations
  FOR EACH ROW
  EXECUTE FUNCTION public.update_translation_timestamp();
