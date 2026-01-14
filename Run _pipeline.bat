@echo off
call venv\Scripts\activate
python src\ingest_api.py
python src\process_historical.py
python src\load_to_bronze.py
cd recruitment_dbt
dbt run
cd ..
deactivate