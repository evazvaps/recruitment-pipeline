import pandas as pd
from datetime import datetime

# Load CSV
df = pd.read_csv('offerzen_jobs_history_raw.csv')

# Handle data quality (from PDF: issues like inconsistencies)
# Example cleaning:
df['open_date'] = pd.to_datetime(df['open_date'], errors='coerce')  # Fix dates
df['close_date'] = pd.to_datetime(df['close_date'], errors='coerce')
df = df.drop_duplicates(subset=['job_id'])  # Remove dupes
df = df.dropna(subset=['title', 'department', 'location'])  # Drop invalid rows
df['department'] = df['department'].str.strip().str.title()  # Standardize
df['location'] = df['location'].str.strip().str.title()

# Add ingested_at
df['ingested_at'] = datetime.now()

# Save cleaned (for Bronze later)
df.to_csv('historical_jobs_cleaned.csv', index=False)
print(f"Processed {len(df)} records.")