import pandas as pd

# Load the CSV
df = pd.read_csv('assets/data/2020_periodic_dividends_per_share.csv')

# Get all month columns
month_columns = [col for col in df.columns if '_2020_dividends_per_share_in_usd' in col]

# Calculate annual total (sum of all months, treating NaN as 0)
df['annual_nominal_dividends_per_share'] = df[month_columns].fillna(0).sum(axis=1)

# Round to 2 decimal places
df['annual_nominal_dividends_per_share'] = df['annual_nominal_dividends_per_share'].round(2)

# Display results
print("Annual Dividends Per Share:")
print(df[['fortune_ranking', 'company', 'annual_nominal_dividends_per_share']])

# Create validation dictionary for Supabase
validation_dict = df.set_index('fortune_ranking')['annual_nominal_dividends_per_share'].to_dict()
print("\n\nValidation dictionary (for database):")
print(validation_dict)

# Save as JSON for easy copy-paste
import json
with open('expected_annual_dividends.json', 'w') as f:
    json.dump(validation_dict, f, indent=2)

print("\n\nSaved to expected_annual_dividends.json")
