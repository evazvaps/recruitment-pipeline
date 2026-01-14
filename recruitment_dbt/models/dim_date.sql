{{ config(materialized='table', schema='gold') }}

WITH date_range AS (
  SELECT generate_series(
    (SELECT MIN(open_date)::DATE FROM {{ ref('jobs_silver') }}),
    (SELECT MAX(COALESCE(close_date, CURRENT_DATE))::DATE FROM {{ ref('jobs_silver') }}),
    '1 day'::INTERVAL
  ) AS date_full
)

SELECT
  TO_CHAR(date_full, 'YYYYMMDD')::INT AS date_id,  -- Surrogate key (e.g., 20251210)
  date_full,
  EXTRACT(YEAR FROM date_full) AS calendar_year,
  EXTRACT(QUARTER FROM date_full) AS calendar_quarter,
  EXTRACT(MONTH FROM date_full) AS calendar_month,
  TO_CHAR(date_full, 'Month') AS month_name,
  EXTRACT(WEEK FROM date_full) AS calendar_week,
  EXTRACT(DAY FROM date_full) AS calendar_day,
  TO_CHAR(date_full, 'Day') AS day_name,
  EXTRACT(DOY FROM date_full) AS day_of_year,
  CASE EXTRACT(DOW FROM date_full)
    WHEN 0 THEN TRUE  -- Sunday
    WHEN 6 THEN TRUE  -- Saturday
    ELSE FALSE
  END AS is_weekend,
  CASE EXTRACT(DOW FROM date_full)
    WHEN 0 THEN FALSE
    WHEN 6 THEN FALSE
    ELSE TRUE
  END AS is_weekday,
  -- Fiscal (assumes calendar year; adjust if fiscal starts e.g., July)
  EXTRACT(YEAR FROM date_full) AS fiscal_year,
  CASE
    WHEN EXTRACT(MONTH FROM date_full) <= 3 THEN 1
    WHEN EXTRACT(MONTH FROM date_full) <= 6 THEN 2
    WHEN EXTRACT(MONTH FROM date_full) <= 9 THEN 3
    ELSE 4
  END AS fiscal_quarter
FROM date_range
ORDER BY date_id