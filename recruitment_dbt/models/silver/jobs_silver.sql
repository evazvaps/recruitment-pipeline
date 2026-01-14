{{ config(materialized='table', schema='silver') }}

SELECT
  job_id,
  internal_job_id,
  absolute_url,
  title,
  department,
  location,
  company_name,
  open_date,
  close_date,
  ingested_at,
  DATE_PART('day', COALESCE(close_date, CURRENT_DATE) - COALESCE(open_date, '1900-01-01'::DATE)) AS time_to_fill_days,  -- Fixed syntax for Postgres
  CASE WHEN open_date IS NULL THEN TRUE ELSE FALSE END AS is_open_date_missing  -- Flag for quality tracking
FROM {{ source('bronze', 'jobs_raw') }}
WHERE job_id IS NOT NULL  -- Keep basic validation on job_id; remove open_date filter if needed