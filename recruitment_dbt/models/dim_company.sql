
{{ config(materialized='table', schema='gold') }}

SELECT
ROW_NUMBER() OVER (ORDER BY company_name) AS company_id,  -- Surrogate key
company_name
FROM (
SELECT DISTINCT
INITCAP(TRIM(company_name)) AS company_name  -- Standardize: trim whitespace, title case to handle duplicates from case/space issues
FROM {{ ref('jobs_silver') }}
WHERE company_name IS NOT NULL
) AS standardized_companies