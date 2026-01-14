text# Recruitment Data Pipeline

End-to-end pipeline for Greenhouse job analytics using Python, RDS Postgres, DBT.

src folder: Contains Python scripts (e.g., ingest_api.py, load_to_bronze.py, process_historical.py).

 Setup
=======
1. Install Python 3.14, create venv, pip install requirements.txt.
2. Configure AWS RDS (recruitment_db), update scripts with creds.
3. Copy offerzen_jobs_history_raw.csv to folder.
4. Run run_pipeline.bat manually or schedule in Task Scheduler.

 Run
=======
- Manual: run_pipeline.bat
- Schedule: Windows Task Scheduler (daily).

Architecture
===============
- Ingest: API/CSV to CSVs
- Process: Clean quality issues
- Load: To Bronze in RDS
- Transform: DBT for Silver/Gold (Star Schema)
