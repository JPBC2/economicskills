-- First, find the exact section ID for the Python dividends exercise
SELECT id, title, python_validation_config 
FROM sections 
WHERE supports_python = true 
AND title ILIKE '%dividends%'
ORDER BY title;

-- After running the above query, copy the ID and use it below
-- Replace 'YOUR_SECTION_ID_HERE' with the actual UUID from the query above

-- UPDATE the validation config to use column_exists
UPDATE sections 
SET python_validation_config = '{
  "validation_type": "simple",
  "steps": [
    {
      "step": 1,
      "type": "variable_exists",
      "name": "df",
      "message_en": "Create a DataFrame called df with the dividend data"
    },
    {
      "step": 2,
      "type": "column_exists",
      "dataframe": "df",
      "name": "annual_nominal_dividends_per_share",
      "message_en": "Create a column called annual_nominal_dividends_per_share in the DataFrame"
    }
  ]
}'::jsonb
WHERE supports_python = true 
AND title ILIKE '%dividends%';

-- Verify the update worked
SELECT id, title, python_validation_config 
FROM sections 
WHERE supports_python = true 
AND title ILIKE '%dividends%';
