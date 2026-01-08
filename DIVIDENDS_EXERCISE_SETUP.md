# Dividends Exercise Setup Guide

## Step 1: Upload CSV to Supabase Storage

1. Go to Supabase Dashboard → Storage
2. Create a bucket called `datasets` (if it doesn't exist)
3. Make it public
4. Upload `assets/data/2020_periodic_dividends_per_share.csv`
5. Copy the public URL (will be something like):
   ```
   https://[your-project].supabase.co/storage/v1/object/public/datasets/2020_periodic_dividends_per_share.csv
   ```

## Step 2: Find the Exercise ID

Run this query to find the exercise ID for the existing section:

```sql
SELECT s.id as section_id, s.exercise_id, s.title, e.title as exercise_title
FROM sections s
JOIN exercises e ON s.exercise_id = e.id
WHERE s.title ILIKE '%annual%nominal%dividends%per%share%';
```

Copy the `exercise_id` value.

## Step 3: Run the Setup SQL

Replace `EXERCISE_ID_HERE` and `CSV_URL_HERE` in the SQL below and run it:

```sql
-- Step 1: Rename existing section to add "Spreadsheet" suffix
UPDATE sections
SET title = '1. Annual nominal dividends per share (Spreadsheet)'
WHERE title ILIKE '%1%annual%nominal%dividends%per%share%'
  AND title NOT ILIKE '%spreadsheet%'
  AND title NOT ILIKE '%python%';

-- Step 2: Insert Python version
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
  created_at,
  updated_at
) VALUES (
  'EXERCISE_ID_HERE'::uuid,  -- Replace with actual exercise_id
  '1. Annual nominal dividends per share (Python)',
  'Calculate the annual dividends per share by summing the monthly dividend payments for each company.',
  E'## Instructions\n\n1. **Load the data** - The CSV file contains 100 Fortune 500 companies and their monthly dividend payments for 2020\n\n2. **Display the dataset** - Show the first few rows to understand the data structure\n\n3. **Calculate annual dividends** - Sum all monthly dividend columns for each company\n\n4. **Display results** - Show the company names with their annual dividend totals',
  'Remember to handle missing values (NaN) when summing. Use fillna(0) or skipna=True.',
  2,
  10,
  false,
  true,
  E'import pandas as pd\nimport io\n\n# Load the full dataset with all 100 companies\nurl = "CSV_URL_HERE"  # Replace with your Supabase Storage URL\ndf = pd.read_csv(url)\n\n# Step 1: Display the dataset\nprint("Dataset preview:")\nprint(df.head())\nprint(f"\\nTotal companies: {len(df)}")\n\n# Step 2: Identify monthly dividend columns\nmonth_columns = [col for col in df.columns if \'_2020_dividends_per_share_in_usd\' in col]\nprint(f"\\nMonthly columns: {month_columns[:3]}... ({len(month_columns)} total)")\n\n# TODO: Step 3 - Calculate annual dividends\n# Sum all monthly dividends for each company (treat NaN as 0)\n# df[\'annual_nominal_dividends_per_share\'] = df[month_columns].fillna(0).sum(axis=1)\n\n# TODO: Step 4 - Round to 2 decimal places\n# df[\'annual_nominal_dividends_per_share\'] = df[\'annual_nominal_dividends_per_share\'].round(2)\n\n# TODO: Step 5 - Display results\n# print("\\nAnnual Dividends Per Share:")\n# print(df[[\'fortune_ranking\', \'company\', \'annual_nominal_dividends_per_share\']])\n',
  now(),
  now()
);
```

## Step 4: Add Validation Config

After creating the section, get its ID and add validation:

```sql
-- Get the new Python section ID
SELECT id, title FROM sections WHERE title ILIKE '%python%' AND title ILIKE '%dividends%';

-- Update with validation config (replace SECTION_ID_HERE)
UPDATE sections
SET python_validation_config = '{
  "validation_type": "simple",
  "steps": [
    {
      "step": 1,
      "type": "variable_exists",
      "name": "df",
      "expected_type": "DataFrame",
      "message_en": "Load the CSV data into a DataFrame called df"
    },
    {
      "step": 2,
      "type": "variable_exists",
      "name": "annual_nominal_dividends_per_share",
      "message_en": "The DataFrame should have a column called annual_nominal_dividends_per_share"
    },
    {
      "step": 3,
      "type": "dataframe_column_check",
      "column": "annual_nominal_dividends_per_share",
      "expected_values": {
        "1": 0.72,
        "11": 12.75,
        "52": 9.80
      },
      "tolerance": 0.01,
      "message_en": "Some annual dividend calculations are incorrect. Check your summing logic."
    }
  ]
}'::jsonb
WHERE id = 'SECTION_ID_HERE'::uuid;
```

## Expected Results

After running, you should have:
- **Section 1**: "1. Annual nominal dividends per share (Spreadsheet)" - Google Sheets version
- **Section 2**: "1. Annual nominal dividends per share (Python)" - Python version

Both should appear in the same exercise and students can complete either or both.

## Testing

1. Navigate to: `http://localhost:3000/#/sections/[python-section-id]`
2. You should see the Python code editor
3. Uncomment the TODO lines
4. Click "Run" to see output
5. Click "Submit" to validate and earn XP

## Validation Logic

The validation checks:
1. DataFrame exists
2. annual_nominal_dividends_per_share column exists
3. Sample values are correct (checks 3 companies as spot-check)

For full validation of all 100 companies, you can extend step 3 to include all expected values from `expected_annual_dividends.json`.
