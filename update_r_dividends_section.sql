-- Update section '1. Annual nominal dividends per share' with R assignment content
-- Run this in Supabase SQL Editor

UPDATE sections
SET
  supports_r = true,
  instructions_r = '## Calculate Annual Dividends Per Share

Using the 2020 periodic dividends data, calculate the **annual (total) dividends per share** for each company.

### Steps:
1. Load the CSV file containing monthly dividend data
2. Create a new column called `annual_dividends` that contains the sum of all monthly dividends for each company
3. Handle missing values (NA) appropriately - they should be treated as $0

### Expected Output:
A data frame with columns: `fortune_ranking`, `company`, and `annual_dividends`

### Hint:
Use `rowSums()` to sum across columns, or use `rowwise()` with `sum()`. Remember to handle NA values with `na.rm = TRUE`.',

  hint_r = 'Use `mutate()` combined with `rowSums()` to sum across the monthly columns.

Example pattern:
```r
df <- df %>%
  mutate(annual_dividends = rowSums(select(., january:december), na.rm = TRUE))
```

Or use `rowwise()`:
```r
df <- df %>%
  rowwise() %>%
  mutate(annual_dividends = sum(c_across(january:december), na.rm = TRUE)) %>%
  ungroup()
```',

  xp_reward_r = 15,

  r_starter_code_en = '# Annual Dividends Per Share Calculator
# Calculate the total annual dividends for each Fortune 100 company

# Load required libraries
library(dplyr)
library(readr)

# Load the dividend data
dividends <- read_csv("2020_periodic_dividends_per_share.csv")

# View the first few rows to understand the data structure
head(dividends)

# TODO: Calculate annual_dividends by summing all monthly dividend columns
# Hint: Monthly columns are: january, february, march, april, may, june,
#       july, august, september, october, november, december
# Remember to handle NA values (missing dividends = $0)

annual_dividends <- dividends %>%
  # Your code here - add a column called annual_dividends
  
# View your results
print(annual_dividends %>% select(fortune_ranking, company, annual_dividends))
',

  r_solution_code = '# Annual Dividends Per Share Calculator
# Calculate the total annual dividends for each Fortune 100 company

# Load required libraries
library(dplyr)
library(readr)

# Load the dividend data
dividends <- read_csv("2020_periodic_dividends_per_share.csv")

# Calculate annual_dividends by summing all monthly dividend columns
annual_dividends <- dividends %>%
  mutate(annual_dividends = rowSums(
    select(., january:december), 
    na.rm = TRUE
  ))

# View the results
print(annual_dividends %>% select(fortune_ranking, company, annual_dividends))

# Alternative solution using rowwise():
# annual_dividends <- dividends %>%
#   rowwise() %>%
#   mutate(annual_dividends = sum(c_across(january:december), na.rm = TRUE)) %>%
#   ungroup()
',

  r_validation_config = '{
    "validation_type": "output_check",
    "steps": [
      {
        "step": 1,
        "type": "variable_exists",
        "name": "annual_dividends",
        "expected_type": "data.frame",
        "message_en": "Create a variable called annual_dividends"
      },
      {
        "step": 2,
        "type": "column_exists",
        "variable": "annual_dividends",
        "column": "annual_dividends",
        "message_en": "Add a column called annual_dividends to the data frame"
      },
      {
        "step": 3,
        "type": "row_value",
        "variable": "annual_dividends",
        "filter": {"column": "company", "value": "Walmart"},
        "check_column": "annual_dividends",
        "expected": 0.72,
        "tolerance": 0.01,
        "message_en": "Walmart should have annual dividends of $0.72 (4 x $0.18)"
      },
      {
        "step": 4,
        "type": "row_value",
        "variable": "annual_dividends",
        "filter": {"column": "company", "value": "Apple"},
        "check_column": "annual_dividends",
        "expected": 2.62,
        "tolerance": 0.01,
        "message_en": "Apple should have annual dividends of $2.62"
      },
      {
        "step": 5,
        "type": "row_value",
        "variable": "annual_dividends",
        "filter": {"column": "company", "value": "Costco"},
        "check_column": "annual_dividends",
        "expected": 12.75,
        "tolerance": 0.01,
        "message_en": "Costco should have annual dividends of $12.75 (includes $10 special dividend)"
      }
    ]
  }'::jsonb

WHERE title LIKE '%Annual nominal dividends per share%'
  AND title NOT LIKE '%(Spreadsheet)%'
  AND title NOT LIKE '%(Python)%';

-- Verify the update
SELECT id, title, supports_r, instructions_r, xp_reward_r
FROM sections
WHERE title LIKE '%Annual nominal dividends per share%';
