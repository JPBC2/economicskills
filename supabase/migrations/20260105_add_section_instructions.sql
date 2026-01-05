-- Add instructions column to sections table
-- This allows editors to add step-by-step instructions for students

ALTER TABLE sections ADD COLUMN instructions TEXT;

-- Comment for documentation
COMMENT ON COLUMN sections.instructions IS 'Step-by-step instructions for students to follow when completing this section';
