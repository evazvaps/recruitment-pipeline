import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.types import String, DateTime, Float  # Added Float for internal_job_id if needed

# DB connection (replace with your RDS details)
engine = create_engine('postgresql+psycopg2://OfferZen:OfferZen123@offerzendb.cez6u4g6kc42.us-east-1.rds.amazonaws.com:5432/postgres')

# Load current
df_current = pd.read_csv('current_jobs_raw.csv')

# Convert dates explicitly (in case CSV has strings)
df_current['open_date'] = pd.to_datetime(df_current['open_date'], errors='coerce')

# Load historical (cleaned)
df_hist = pd.read_csv('historical_jobs_cleaned.csv')

# Convert dates
df_hist['open_date'] = pd.to_datetime(df_hist['open_date'], errors='coerce')
df_hist['close_date'] = pd.to_datetime(df_hist['close_date'], errors='coerce')

# Combine and dedupe
df_combined = pd.concat([df_current, df_hist]).drop_duplicates(subset=['job_id'])

# Explicit types
dtype_map = {
    'job_id': String(),
    'internal_job_id': Float(),  # From data, it's numeric with .0
    'absolute_url': String(),
    'title': String(),
    'department': String(),
    'location': String(),
    'company_name': String(),
    'open_date': DateTime(),
    'close_date': DateTime(),
    'ingested_at': DateTime()
}

# Load (replace to recreate table with correct types; change to 'append' for future runs)
df_combined.to_sql('jobs_raw', engine, schema='bronze', if_exists='replace', index=False, dtype=dtype_map)

print("Loaded to Bronze.")