import requests
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
        'job_id': job.get('id'),
        'internal_job_id': job.get('internal_job_id'),
        'absolute_url': job.get('absolute_url'),
        'title': job.get('title'),
        'department': job['departments'][0]['name'] if job.get('departments') else None,
        'location': job.get('location', {}).get('name'),
        'company_name': job.get('company_name', 'OfferZen'),  # From API or fallback
        'open_date': job.get('first_published'),  # Updated field name
        'close_date': None  # API doesn't have for open jobs
    } for job in jobs])

    # Convert dates to datetime (if present)
    df['open_date'] = pd.to_datetime(df['open_date'], errors='coerce')

    # Add ingestion timestamp
    df['ingested_at'] = datetime.now()

    # Save as CSV for now (later to DB)
    df.to_csv('current_jobs_raw.csv', index=False)
    print(f"Fetched {len(df)} jobs.")
except Exception as e:
    print(f"Error: {e}")
    # Add logging/email alert here in production