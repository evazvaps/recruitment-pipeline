  
   
{{ config(materialized='table', schema='gold') }}

WITH pre_fact AS (
  SELECT
    job_id,
    internal_job_id,
    title,
    department,
    location,
    INITCAP(TRIM(company_name)) AS company_name,
    open_date,
    close_date,
    TO_CHAR(open_date, 'YYYYMMDD')::INT AS open_date_id,
    CASE WHEN close_date IS NOT NULL THEN TO_CHAR(close_date, 'YYYYMMDD')::INT ELSE NULL END AS close_date_id,
    CASE WHEN close_date IS NOT NULL THEN 'Closed' ELSE 'Open' END AS job_status,
    DATE_PART('day', COALESCE(close_date, CURRENT_DATE) - COALESCE(open_date, '1900-01-01'::DATE)) AS time_to_fill_days,
    CASE WHEN close_date IS NOT NULL THEN DATE_PART('day', close_date - open_date) ELSE NULL END AS duration_days
  FROM {{ ref('jobs_silver') }}
  WHERE job_id IS NOT NULL  -- Removed open_date filter to include all records
),

fact AS (
  SELECT
    p.job_id,
    p.internal_job_id,
    t.title_id,
    d.dept_id,
    l.loc_id,
    c.company_id,
    p.open_date_id,
    p.close_date_id,
    p.job_status,
    p.time_to_fill_days,
    p.duration_days
  FROM pre_fact p
  LEFT JOIN {{ ref('dim_title') }} t ON INITCAP(TRIM(p.title)) = t.title_name
  LEFT JOIN {{ ref('dim_department') }} d ON p.department = d.dept_name
  LEFT JOIN {{ ref('dim_location') }} l ON p.location = l.loc_name
  LEFT JOIN {{ ref('dim_company') }} c ON p.company_name = c.company_name
  LEFT JOIN {{ ref('dim_date') }} dd_open ON p.open_date_id = dd_open.date_id
  LEFT JOIN {{ ref('dim_date') }} dd_close ON p.close_date_id = dd_close.date_id
)

SELECT * FROM fact