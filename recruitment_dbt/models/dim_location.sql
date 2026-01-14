{{ config(materialized='table', schema='gold') }}
SELECT
ROW_NUMBER() OVER (ORDER BY loc_name) AS loc_id,  -- Surrogate key
loc_name
FROM (
SELECT DISTINCT
INITCAP(TRIM(location)) AS loc_name  -- Standardize: trim whitespace, title case to handle duplicates from case/space issues
FROM {{ ref('jobs_silver') }}
WHERE location IS NOT NULL
) AS standardized_locations