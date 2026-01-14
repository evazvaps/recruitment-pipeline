Solution Overview
====================
Architecture: 
	Python for ingestion/processing, 
	RDS Postgres warehouse, 
	DBT for Medallion (Bronze raw, Silver cleaned, Gold modeled with Star Schema: fact_jobs + dims for dept/location/date/title/company).

Decisions: 
	Local Task Scheduler for orchestration (simple, no cost; AWS Step Functions alternative for scale). 
	Handled quality with dedup/standardization in Python/DBT.

Trade-offs:
	 Local dev for speed; cloud for production reliability. No other tech stack changes (justified as recommended fits well).
	Error Handling: Try/except in Python, DBT tests, bat logging.
	Metrics: Avg time-to-fill, trends by dept/location (queries in pgAdmin).

===----------------------------------------------------------------------------------------------------------------------------------

	STEPS
	=======
Create schemas: In pgAdmin  run:
	SQLCREATE SCHEMA bronze;
	CREATE SCHEMA silver;
	CREATE SCHEMA gold;
-------------------------------------------------------------------------------------------------------------------------------------------
	Data Ingestion & Processing
	============================

Create ingest_api.py 
======================
Code:Python import requests
import pandas as pd
from datetime import datetime

# API URL from PDF
url = "https://api.greenhouse.io/v1/boards/offerzen/jobs?content=true"

try:
    response = requests.get(url)
    response.raise_for_status()  # Error if not 200
    data = response.json()
    jobs = data.get('jobs', [])  # Extract jobs list

    # Flatten to DataFrame (match CSV columns)
    df = pd.DataFrame([{
        'job_id': job['id'],
        'internal_job_id': job.get('internal_job_id'),
        'absolute_url': job['absolute_url'],
        'title': job['title'],
        'department': job['departments'][0]['name'] if job.get('departments') else None,
        'location': job['location']['name'],
        'company_name': 'OfferZen',  # Assuming from PDF
        'open_date': job['opened_at'],
        'close_date': None  # API might not have close_date; add logic if needed
    } for job in jobs])

    # Add ingestion timestamp
    df['ingested_at'] = datetime.now()

    # Save as CSV for now (later to DB)
    df.to_csv('current_jobs_raw.csv', index=False)
    print(f"Fetched {len(df)} jobs.")
except Exception as e:
    print(f"Error: {e}")
    # Add logging/email alert here in production

Run: python ingest_api.py.



Process Historical CSV:
========================
Place offerzen_jobs_history_raw.csv in project folder.
Create process_historical.py:Pythonimport pandas as pd
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
Run: python process_historical.py.
Why: Cleans issues (e.g., bad dates, dupes). Merge with current if needed (e.g., append unique jobs).


Load to Bronze Layer (Raw Data in DB):
Create load_to_bronze.py:Pythonimport pandas as pd
import psycopg2
from sqlalchemy import create_engine  # pip install sqlalchemy

# DB connection (replace with your RDS details)
engine = create_engine('postgresql+psycopg2://admin:<password>@<rds-endpoint>:5432/recruitment_db')

# Load current
df_current = pd.read_csv('current_jobs_raw.csv')
df_current.to_sql('jobs_raw', engine, schema='bronze', if_exists='append', index=False)

# Load historical
df_hist = pd.read_csv('historical_jobs_cleaned.csv')
df_hist.to_sql('jobs_raw', engine, schema='bronze', if_exists='append', index=False)

print("Loaded to Bronze.")
Run: python load_to_bronze.py.
Why: Bronze = raw/ingested data. Use SQLAlchemy for easy loading. Dedupe on job_id if appending daily.


Set Up AWS RDS PostgreSQL (Data Warehouse):
===========================================
AWS Console → RDS → Create database.
Engine: PostgreSQL (free tier: db.t3.micro).
DB name: recruitment_db.
Username: admin, Password: something secure.
Connect locally: Use pgAdmin (download from pgadmin.org) or terminal: psql -h <rds-endpoint> -U admin -d recruitment_db (endpoint from AWS console).

Create schemas: In pgAdmin or psql, run:SQLCREATE ;
==================================================================
SCHEMA bronze
CREATE SCHEMA silver;
CREATE SCHEMA gold;\


Run: python ingest_api.py
===========================
Why: Ingests current data. Handles errors (e.g., API down). API returns JSON; we map to CSV-like structure.

Process Historical CSV
===========================
Run: python process_historical.py.
Why: Cleans issues (e.g., bad dates, dupes). Merge with current if needed (e.g., append unique jobs).

Load to Bronze Layer (Raw Data in DB):
=====================================
Run: python load_to_bronze.py.
Why: Bronze = raw/ingested data. Use SQLAlchemy for easy loading. Dedupe on job_id if appending daily.

Data Architecture & Modeling with DBT
======================================
In project: dbt init recruitment_dbt
dit dbt_project.yml: Set project name.
Edit profiles.yml (~/.dbt/profiles.yml
recruitment_dbt:
  target: dev
  outputs:
    dev:
      type: postgres
      host: <rds-endpoint>
      user: admin
      password: <password>
      port: 5432
      dbname: recruitment_db
      schema: puplic  # Default; override per model
	 
	  Why: DBT handles transformations/tests.

	  Design Star Schema:
	  =======================
	  Fact table: fact_jobs (job_id, open_date_id, close_date_id, dept_id, loc_id, metrics like time_to_fill).
Dimensions: dim_department, dim_location, dim_date.
Why: Enables analytics (joins for queries).

Fact table: fact_jobs (job_id, open_date_id, close_date_id, dept_id, loc_id, metrics like time_to_fill).
Dimensions: dim_department, dim_location, dim_date.
Why: Enables analytics (joins for queries).

DBT Models
==============
In dbt/models/silver: Create jobs_silver.sql (clean/transform from bronze)
n dbt/models/gold: fact_jobs.sql:


Pipeline Orchestration
========================
Task Scheduler (Windows) to run a script daily
Job name: Run _pipeline