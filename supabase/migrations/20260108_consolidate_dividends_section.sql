-- Migration: Consolidate dividends sections into one that supports both tools
--
-- With the new URL routing (e.g., /sections/1-annual-nominal-dividends-per-share-spreadsheet),
-- we only need ONE section that supports both spreadsheet AND python.
-- The URL suffix (-spreadsheet or -python) auto-selects the tool.

-- Step 1: Find and update the main section to support both tools
UPDATE sections
SET
  title = '1. Annual nominal dividends per share',
  supports_spreadsheet = true,
  supports_python = true,
  -- Add Python starter code if not present
  python_starter_code_en = COALESCE(python_starter_code_en, E'import pandas as pd\nimport io\n\n# Dataset: 100 Fortune 500 companies and their 2020 monthly dividends\ncsv_data = """fortune_ranking,company,january,february,march,april,may,june,july,august,september,october,november,december\n1,Walmart,,,0.18,,0.18,,,0.18,,,,0.18\n2,Amazon,,,,,,,,,,,,\n3,Apple,,0.77,,,0.82,,,0.82,,,0.21,\n4,CVS Health,,0.50,,,0.50,,,0.50,,,0.50,\n5,UnitedHealth Group,,,1.08,,,1.25,,,1.25,,,1.25\n6,ExxonMobil,,0.87,,,0.87,,,0.87,,,0.87,\n7,Berkshire Hathaway,,,,,,,,,,,,\n8,McKesson Corporation,,,,0.41,,,0.42,,,0.42,,\n9,Alphabet (Class A),,,,,,,,,,,,\n10,AmerisourceBergen,,,0.42,,,0.42,,,0.42,,0.44,"""\n\ndf = pd.read_csv(io.StringIO(csv_data))\n\n# Step 1: Display the dataset\nprint("Dataset Preview:")\nprint(df.head())\nprint(f"\\nTotal companies: {len(df)}")\n\n# Step 2: Get list of monthly dividend columns\nmonth_columns = [''january'', ''february'', ''march'', ''april'', ''may'', ''june'',\n                 ''july'', ''august'', ''september'', ''october'', ''november'', ''december'']\nprint(f"\\nMonthly columns: {month_columns}")\n\n# TODO: Step 3 - Calculate annual dividends\n# df[''annual_nominal_dividends_per_share''] = df[month_columns].fillna(0).sum(axis=1)\n\n# TODO: Step 4 - Round to 2 decimal places\n# df[''annual_nominal_dividends_per_share''] = df[''annual_nominal_dividends_per_share''].round(2)\n\n# TODO: Step 5 - Display results\n# print("\\nAnnual Dividends Per Share:")\n# print(df[[''fortune_ranking'', ''company'', ''annual_nominal_dividends_per_share'']])\n'),
  python_validation_config = COALESCE(python_validation_config, '{
    "validation_type": "simple",
    "steps": [
      {"step": 1, "type": "variable_exists", "name": "df", "expected_type": "DataFrame", "message_en": "Create a DataFrame called df with the dividend data"},
      {"step": 2, "type": "column_exists", "dataframe": "df", "column": "annual_nominal_dividends_per_share", "message_en": "Create a column called annual_nominal_dividends_per_share in the DataFrame"}
    ]
  }'::jsonb),
  updated_at = now()
WHERE title ILIKE '%annual%nominal%dividends%'
  AND title NOT ILIKE '%(Python)%'
LIMIT 1;

-- Step 2: Delete any duplicate Python-only section (if it exists)
DELETE FROM sections
WHERE title ILIKE '%annual%nominal%dividends%python%'
  OR title ILIKE '%annual%nominal%dividends%(Python)%';

-- Step 3: Delete any duplicate Spreadsheet-only section (keep only one)
-- This keeps the first one and deletes any duplicates
DELETE FROM sections
WHERE id IN (
  SELECT id FROM sections
  WHERE title ILIKE '%annual%nominal%dividends%'
  ORDER BY created_at ASC
  OFFSET 1
);

-- Step 4: Verify we have exactly one section
SELECT
  id,
  title,
  supports_spreadsheet,
  supports_python,
  xp_reward,
  display_order
FROM sections
WHERE title ILIKE '%annual%nominal%dividends%'
ORDER BY display_order;
