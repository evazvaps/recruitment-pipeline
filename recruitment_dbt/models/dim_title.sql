{{ config(materialized='table', schema='gold') }}

SELECT 
  ROW_NUMBER() OVER (ORDER BY title_name) AS title_id,  -- Surrogate key
  title_name
FROM (
  SELECT DISTINCT
    INITCAP(TRIM(title)) AS title_name  -- Standardize: trim whitespace, title case to handle duplicates from case/space issues
  FROM {{ ref('jobs_silver') }}
  WHERE title IS NOT NULL
) AS standardized_titles