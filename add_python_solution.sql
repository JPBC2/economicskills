-- Fix the validation config to use 'column_exists' instead of 'variable_exists' for DataFrame columns
-- Run this in the Supabase SQL Editor

UPDATE sections 
SET python_validation_config = jsonb_build_object(
  'validation_type', 'simple',
  'steps', jsonb_build_array(
    jsonb_build_object(
      'step', 1,
      'type', 'variable_exists',
      'name', 'df',
      'message_en', 'Create a DataFrame called df with the dividend data'
    ),
    jsonb_build_object(
      'step', 2,
      'type', 'column_exists',
      'dataframe', 'df',
      'name', 'annual_nominal_dividends_per_share',
      'message_en', 'Create a column called annual_nominal_dividends_per_share in the DataFrame'
    )
  )
)
WHERE title ILIKE '%Annual nominal dividends%Python%';

-- Also update the python_solution_code with the correct solution
UPDATE sections 
SET python_solution_code = 'import pandas as pd
import io

# Dataset: 100 Fortune 500 companies and their 2020 monthly dividends
# OPTION 1: Inline data (first 10 companies for testing)
csv_data = """fortune_ranking,company,january,february,march,april,may,june,july,august,september,october,november,december
1,Walmart,,,0.18,,0.18,,,0.18,,,,0.18
2,Amazon,,,,,,,,,,,,
3,Apple,,0.77,,,0.82,,,0.82,,,0.21,
4,CVS Health,,0.50,,,0.50,,,0.50,,,0.50,
5,UnitedHealth Group,,,1.08,,,1.25,,,1.25,,,1.25
6,ExxonMobil,,0.87,,,0.87,,,0.87,,,0.87,
7,Berkshire Hathaway,,,,,,,,,,,,
8,McKesson Corporation,,,,0.41,,,0.42,,,0.42,,
9,Alphabet (Class A),,,,,,,,,,,,
10,AmerisourceBergen,,,0.42,,,0.42,,,0.42,,0.44,"""

df = pd.read_csv(io.StringIO(csv_data))

# Step 1: Display the dataset
print("Dataset Preview:")
print(df.head())
print(f"\nTotal companies: {len(df)}")

# Step 2: Get list of monthly dividend columns
month_columns = [''january'', ''february'', ''march'', ''april'', ''may'', ''june'',
                 ''july'', ''august'', ''september'', ''october'', ''november'', ''december'']
print(f"\nMonthly columns: {month_columns}")

# Step 3 - Calculate annual dividends
# Replace the NaN values with 0 and sum across the monthly columns
df[''annual_nominal_dividends_per_share''] = df[month_columns].fillna(0).sum(axis=1)

# Step 4 - Round to 2 decimal places
df[''annual_nominal_dividends_per_share''] = df[''annual_nominal_dividends_per_share''].round(2)

# Step 5 - Display results
print("\nAnnual Dividends Per Share:")
print(df[[''fortune_ranking'', ''company'', ''annual_nominal_dividends_per_share'']])'
WHERE title ILIKE '%Annual nominal dividends%Python%';

-- Verify the changes
SELECT 
  title, 
  python_validation_config,
  LEFT(python_solution_code, 100) as solution_preview
FROM sections 
WHERE title ILIKE '%Annual nominal dividends%Python%';
