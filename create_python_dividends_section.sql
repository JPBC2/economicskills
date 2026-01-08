-- Complete setup script for Python Dividends Exercise
-- Run this in Supabase SQL Editor

-- Step 1: Update existing section title
UPDATE sections
SET title = '1. Annual nominal dividends per share (Spreadsheet)'
WHERE title = '1. Annual nominal dividends per share'
   OR title ILIKE '1.%Annual%nominal%dividends%per%share'
   AND title NOT ILIKE '%Spreadsheet%'
   AND title NOT ILIKE '%Python%';

-- Step 2: Create Python version of the same exercise
-- This uses the same exercise_id as the spreadsheet version
INSERT INTO sections (
  exercise_id,
  title,
  explanation,
  instructions,
  hint,
  display_order,
  xp_reward,
  supports_spreadsheet,
  supports_python,
  python_starter_code_en,
  python_validation_config,
  created_at,
  updated_at
)
SELECT
  exercise_id,
  '1. Annual nominal dividends per share (Python)',
  'Calculate the annual dividends per share by summing the monthly dividend payments for 100 Fortune 500 companies.',
  E'## Task Overview\n\nYou have a dataset with 100 companies and their monthly dividend payments for 2020. Your goal is to calculate the total annual dividends per share for each company.\n\n## Steps\n\n1. **Load the data** - The CSV contains monthly dividend data\n2. **Display the dataset** - Print the first few rows with `print(df.head())`\n3. **Calculate annual totals** - Sum all 12 monthly columns for each company\n4. **Display results** - Show the company names and their annual totals\n\n## Expected Output\n\nYour DataFrame should have a new column called `annual_nominal_dividends_per_share` with the sum of all monthly dividends.',
  'Handle missing values with fillna(0) before summing. Use .sum(axis=1) to sum across columns.',
  2,
  10,
  false,
  true,
  E'import pandas as pd\nimport io\n\n# Dataset: 100 Fortune 500 companies and their 2020 monthly dividends\n# OPTION 1: Inline data (first 10 companies for testing)\ncsv_data = """fortune_ranking,company,january,february,march,april,may,june,july,august,september,october,november,december\n1,Walmart,,,0.18,,0.18,,,0.18,,,,0.18\n2,Amazon,,,,,,,,,,,,\n3,Apple,,0.77,,,0.82,,,0.82,,,0.21,\n4,CVS Health,,0.50,,,0.50,,,0.50,,,0.50,\n5,UnitedHealth Group,,,1.08,,,1.25,,,1.25,,,1.25\n6,ExxonMobil,,0.87,,,0.87,,,0.87,,,0.87,\n7,Berkshire Hathaway,,,,,,,,,,,,\n8,McKesson Corporation,,,,0.41,,,0.42,,,0.42,,\n9,Alphabet (Class A),,,,,,,,,,,,\n10,AmerisourceBergen,,,0.42,,,0.42,,,0.42,,0.44,"""\n\ndf = pd.read_csv(io.StringIO(csv_data))\n\n# OPTION 2: Load full dataset from URL (uncomment when CSV is uploaded)\n# url = "YOUR_SUPABASE_STORAGE_URL"\n# df = pd.read_csv(url)\n\n# Step 1: Display the dataset\nprint("Dataset Preview:")\nprint(df.head())\nprint(f"\\nTotal companies: {len(df)}")\n\n# Step 2: Get list of monthly dividend columns\nmonth_columns = [\'january\', \'february\', \'march\', \'april\', \'may\', \'june\',\n                 \'july\', \'august\', \'september\', \'october\', \'november\', \'december\']\nprint(f"Monthly columns: {month_columns}")\n\n# TODO: Step 3 - Calculate annual dividends\n# Replace the NaN values with 0 and sum across the monthly columns\n# df[\'annual_nominal_dividends_per_share\'] = df[month_columns].fillna(0).sum(axis=1)\n\n# TODO: Step 4 - Round to 2 decimal places\n# df[\'annual_nominal_dividends_per_share\'] = df[\'annual_nominal_dividends_per_share\'].round(2)\n\n# TODO: Step 5 - Display results\n# print("\\nAnnual Dividends Per Share:")\n# print(df[[\'fortune_ranking\', \'company\', \'annual_nominal_dividends_per_share\']])\n',
  jsonb_build_object(
    'validation_type', 'simple',
    'steps', jsonb_build_array(
      jsonb_build_object(
        'step', 1,
        'type', 'variable_exists',
        'name', 'df',
        'expected_type', 'DataFrame',
        'message_en', 'Create a DataFrame called df with the dividend data'
      ),
      jsonb_build_object(
        'step', 2,
        'type', 'variable_value',
        'name', 'len(df)',
        'expected', 10,
        'tolerance', 0,
        'message_en', 'Your DataFrame should have at least 10 companies (use the full dataset for 100)'
      )
    )
  ),
  now(),
  now()
FROM sections
WHERE (title = '1. Annual nominal dividends per share'
   OR title ILIKE '1.%Annual%nominal%dividends%per%share%Spreadsheet%')
LIMIT 1;

-- Step 3: Verify both sections exist
SELECT
  id,
  title,
  display_order,
  xp_reward,
  supports_spreadsheet,
  supports_python,
  CASE
    WHEN python_starter_code_en IS NOT NULL THEN 'Has Python code'
    ELSE 'No Python code'
  END as python_status
FROM sections
WHERE title ILIKE '%annual%nominal%dividends%per%share%'
ORDER BY display_order;
