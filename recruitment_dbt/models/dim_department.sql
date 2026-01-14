{{ config(materialized='table', schema='gold') }}
SELECT
ROW_NUMBER() OVER (ORDER BY dept_name) AS dept_id,  -- Surrogate key
dept_name
FROM (
SELECT DISTINCT
INITCAP(TRIM(department)) AS dept_name  -- Standardize: trim whitespace, title case to handle duplicates from case/space issues
FROM {{ ref('jobs_silver') }}
WHERE department IS NOT NULL
) AS standardized_departments