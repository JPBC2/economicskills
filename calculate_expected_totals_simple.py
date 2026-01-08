import csv
import json

# Read CSV and calculate totals
totals = {}

with open('assets/data/2020_periodic_dividends_per_share.csv', 'r') as f:
    reader = csv.DictReader(f)

    for row in reader:
        ranking = int(row['fortune_ranking'])
        company = row['company']

        # Sum all monthly dividends
        total = 0.0
        months = ['january', 'february', 'march', 'april', 'may', 'june',
                  'july', 'august', 'september', 'october', 'november', 'december']
        for month in months:
            value = row.get(month, '')
            if value:
                try:
                    total += float(value)
                except ValueError:
                    pass

        totals[ranking] = round(total, 2)
        print(f"{ranking}. {company}: ${total:.2f}")

# Save as JSON
with open('expected_annual_dividends.json', 'w') as f:
    json.dump(totals, f, indent=2)

print(f"\n\nCalculated {len(totals)} companies")
print("Saved to expected_annual_dividends.json")
