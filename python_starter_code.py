import pandas as pd
import io

# OPTION 1: Load from URL (recommended - has all 100 companies)
# Uncomment the line below and replace with your Supabase Storage URL
# url = "https://your-supabase-project.supabase.co/storage/v1/object/public/datasets/2020_periodic_dividends_per_share.csv"
# df = pd.read_csv(url)

# OPTION 2: Use inline data (for testing - only includes first 10 companies)
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
print("Dataset preview:")
print(df.head())
print(f"\nTotal companies: {len(df)}")

# Step 2: Identify monthly dividend columns
month_columns = ['january', 'february', 'march', 'april', 'may', 'june',
                 'july', 'august', 'september', 'october', 'november', 'december']
print(f"\nMonthly columns: {month_columns}")

# Step 3: Calculate annual dividends per share
# Sum all monthly dividends for each company (treating NaN as 0)
df['annual_nominal_dividends_per_share'] = df[month_columns].fillna(0).sum(axis=1)

# Round to 2 decimal places
df['annual_nominal_dividends_per_share'] = df['annual_nominal_dividends_per_share'].round(2)

# Step 4: Display results
print("\nAnnual Dividends Per Share:")
print(df[['fortune_ranking', 'company', 'annual_nominal_dividends_per_share']])

# Optional: Show summary statistics
print(f"\nSummary Statistics:")
print(f"Average annual dividend: ${df['annual_nominal_dividends_per_share'].mean():.2f}")
print(f"Highest dividend payer: {df.loc[df['annual_nominal_dividends_per_share'].idxmax(), 'company']} - ${df['annual_nominal_dividends_per_share'].max():.2f}")
