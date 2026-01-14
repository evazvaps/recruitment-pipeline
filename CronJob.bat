
setlocal enabledelayedexpansion

set PROJECT_DIR=C:\Users\evazv\recruitment-pipeline
set LOG_FILE=%PROJECT_DIR%\pipeline_log.txt

echo Starting pipeline run at %DATE% %TIME% >> %LOG_FILE%

cd /d %PROJECT_DIR%

call venv\Scripts\activate
if errorlevel 1 (
    echo ERROR: Failed to activate venv >> %LOG_FILE%
    exit /b 1
)

python ingest_api.py >> %LOG_FILE% 2>&1
if errorlevel 1 (
    echo ERROR: Ingest API failed >> %LOG_FILE%
)

python process_historical.py >> %LOG_FILE% 2>&1
if errorlevel 1 (
    echo ERROR: Process historical failed >> %LOG_FILE%
)

python load_to_bronze.py >> %LOG_FILE% 2>&1
if errorlevel 1 (
    echo ERROR: Load to Bronze failed >> %LOG_FILE%
)

cd recruitment_dbt
dbt run >> %PROJECT_DIR%\%LOG_FILE% 2>&1
if errorlevel 1 (
    echo ERROR: DBT run failed >> %LOG_FILE%
)

cd ..
deactivate

echo Pipeline run complete at %DATE% %TIME% >> %LOG_FILE%