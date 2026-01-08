-- Setup Python Dividends Exercise
-- This script:
-- 1. Renames the existing section to add "_spreadsheet"
-- 2. Creates a new Python version of the same exercise

-- Step 1: Update the existing section to add "_spreadsheet" suffix
UPDATE sections
SET title = '1. Annual nominal dividends per share (Spreadsheet)'
WHERE title ILIKE '%1%annual%nominal%dividends%per%share%'
AND supports_python IS FALSE;

-- Step 2: Get the exercise_id for this section
-- (We'll need to replace this with the actual UUID from your database)
-- For now, let's create the Python section

-- Insert new Python section
-- NOTE: Replace 'EXERCISE_ID_HERE' with the actual exercise_id from the spreadsheet section
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
  python_solution_code,
  python_validation_config
)
SELECT
  exercise_id,
  '1. Annual nominal dividends per share (Python)',
  'Calculate the annual dividends per share by summing the monthly dividend payments for each company.',
  E'## Instructions\n\n1. **Load the data** - You can either:\n   - Use the inline dataset provided in the starter code, OR\n   - Uncomment the pd.read_csv() line to load from a URL\n\n2. **Display the dataset** - Show the first few rows using `print(df.head())` or `print(df)`\n\n3. **Calculate annual dividends** - Sum all monthly dividend columns for each company and store in a new column called `annual_nominal_dividends_per_share`\n\n4. **Display results** - Print the company names with their annual dividend totals',
  'Remember to handle missing values (NaN) when summing. Use fillna(0) before summing.',
  2,
  10,
  false,
  true,
  E'import pandas as pd\nimport io\n\n# OPTION 1: Load from inline CSV data (works offline)\ncsv_data = """fortune_ranking,company,january_2020_dividends_per_share_in_usd,february_2020_dividends_per_share_in_usd,march_2020_dividends_per_share_in_usd,april_2020_dividends_per_share_in_usd,may_2020_dividends_per_share_in_usd,june_2020_dividends_per_share_in_usd,july_2020_dividends_per_share_in_usd,august_2020_dividends_per_share_in_usd,september_2020_dividends_per_share_in_usd,october_2020_dividends_per_share_in_usd,november_2020_dividends_per_share_in_usd,december_2020_dividends_per_share_in_usd\n1,Walmart,,,0.18,,0.18,,,0.18,,,,0.18\n2,Amazon,,,,,,,,,,,,\n3,Apple,,0.77,,,0.82,,,0.82,,,0.21,"""\n\ndf = pd.read_csv(io.StringIO(csv_data))\n\n# OPTION 2: Load from URL (uncomment to use)\n# url = "YOUR_SUPABASE_STORAGE_URL_HERE"\n# df = pd.read_csv(url)\n\n# TODO: Step 1 - Display the first few rows of the dataset\n# print(df.head())\n\n# TODO: Step 2 - Get list of all monthly dividend columns\n# month_columns = [col for col in df.columns if "_2020_dividends_per_share_in_usd" in col]\n\n# TODO: Step 3 - Calculate annual dividends (sum of all months, treating NaN as 0)\n# df[\'annual_nominal_dividends_per_share\'] = df[month_columns].fillna(0).sum(axis=1)\n\n# TODO: Step 4 - Round to 2 decimal places\n# df[\'annual_nominal_dividends_per_share\'] = df[\'annual_nominal_dividends_per_share\'].round(2)\n\n# TODO: Step 5 - Display results\n# print("\\nAnnual Dividends Per Share:")\n# print(df[[\'fortune_ranking\', \'company\', \'annual_nominal_dividends_per_share\']])\n',
  E'import pandas as pd\nimport io\n\ncsv_data = """fortune_ranking,company,january_2020_dividends_per_share_in_usd,february_2020_dividends_per_share_in_usd,march_2020_dividends_per_share_in_usd,april_2020_dividends_per_share_in_usd,may_2020_dividends_per_share_in_usd,june_2020_dividends_per_share_in_usd,july_2020_dividends_per_share_in_usd,august_2020_dividends_per_share_in_usd,september_2020_dividends_per_share_in_usd,october_2020_dividends_per_share_in_usd,november_2020_dividends_per_share_in_usd,december_2020_dividends_per_share_in_usd\n1,Walmart,,,0.18,,0.18,,,0.18,,,,0.18\n2,Amazon,,,,,,,,,,,,"""\n\ndf = pd.read_csv(io.StringIO(csv_data))\nmonth_columns = [col for col in df.columns if "_2020_dividends_per_share_in_usd" in col]\ndf[\'annual_nominal_dividends_per_share\'] = df[month_columns].fillna(0).sum(axis=1)\ndf[\'annual_nominal_dividends_per_share\'] = df[\'annual_nominal_dividends_per_share\'].round(2)\nprint("Annual Dividends Per Share:")\nprint(df[[\'fortune_ranking\', \'company\', \'annual_nominal_dividends_per_share\']])',
  jsonb_build_object(
    'validation_type', 'simple',
    'steps', jsonb_build_array(
      jsonb_build_object(
        'step', 1,
        'type', 'variable_exists',
        'name', 'df',
        'expected_type', 'DataFrame',
        'message_en', 'Load the CSV data into a DataFrame called df'
      ),
      jsonb_build_object(
        'step', 2,
        'type', 'variable_exists',
        'name', 'annual_nominal_dividends_per_share',
        'message_en', 'Create a column called annual_nominal_dividends_per_share in the DataFrame'
      ),
      jsonb_build_object(
        'step', 3,
        'type', 'custom_check',
        'check_code', E'# Check all 100 companies have correct annual totals\nexpected = {1: 0.72, 2: 0.0, 3: 2.62, 4: 2.0, 5: 4.83, 6: 3.48, 7: 0.0, 8: 1.25, 9: 0.0, 10: 1.7, 11: 12.75, 12: 0.04, 13: 2.08, 14: 2.09, 15: 1.93, 16: 5.16, 17: 6.0, 18: 1.86, 19: 2.32, 20: 3.8, 21: 0.68, 22: 0.15, 23: 2.49, 24: 3.6, 25: 0.38, 26: 0.0, 27: 0.0, 28: 0.9, 29: 3.6, 30: 3.92, 31: 0.0, 32: 2.68, 33: 4.04, 34: 2.3, 35: 0.72, 36: 3.98, 37: 1.44, 38: 3.25, 39: 2.44, 40: 1.22, 41: 1.52, 42: 2.04, 43: 3.96, 44: 1.32, 45: 3.12, 46: 0.04, 47: 6.51, 48: 0.1, 49: 1.82, 50: 4.4, 51: 0.88, 52: 9.8, 53: 5.0, 54: 2.18, 55: 0.72, 56: 2.06, 57: 1.4, 58: 0.43, 59: 4.72, 60: 2.8, 61: 0.0, 62: 2.12, 63: 1.28, 64: 2.15, 65: 0.0, 66: 1.8, 67: 2.44, 68: 4.12, 69: 1.43, 70: 0.23, 71: 1.69, 72: 2.65, 73: 1.71, 74: 1.8, 75: 1.28, 76: 3.04, 77: 1.72, 78: 1.44, 79: 0.0, 80: 0.96, 81: 0.85, 82: 1.64, 83: 4.32, 84: 0.0, 85: 1.6, 86: 1.52, 87: 5.67, 88: 5.88, 89: 3.37, 90: 0.0, 91: 1.4, 92: 2.57, 93: 0.0, 94: 1.0, 95: 0.4, 96: 4.71, 97: 0.4, 98: 0.0, 99: 0.4, 100: 0.1}\nerrors = []\nfor rank, exp_value in expected.items():\n    actual = df[df[\'fortune_ranking\'] == rank][\'annual_nominal_dividends_per_share\'].iloc[0]\n    if abs(actual - exp_value) > 0.01:\n        company = df[df[\'fortune_ranking\'] == rank][\'company\'].iloc[0]\n        errors.append(f"{company}: expected ${exp_value}, got ${actual}")\npassed = len(errors) == 0',
        'message_en', 'Check that all 100 companies have correct annual dividend totals'
      )
    )
  )
FROM sections
WHERE title ILIKE '%1%annual%nominal%dividends%per%share%'
AND supports_python IS FALSE
LIMIT 1;

-- Verification query - run this after to check both sections exist
SELECT id, title, supports_spreadsheet, supports_python
FROM sections
WHERE title ILIKE '%annual%nominal%dividends%';
