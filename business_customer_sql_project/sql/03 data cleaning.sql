/*
File:    03_cleaning_staging.sql
Purpose: Creates cleaned staging tables from the raw data. Raw tables are not modified.
Note:    All data is synthetic.
*/

-- ============================================
-- 1. staging.customers
-- ============================================
DROP TABLE IF EXISTS staging.customers;

-- SME and IT Services need their own rule: INITCAP would turn them into
-- 'Sme' and 'It Services'. Missing values become '<Column> unknown'.
CREATE TABLE staging.customers AS
SELECT
    customer_id, 
	TRIM(company_name) as company_name,
	CASE
		WHEN LOWER(TRIM(customer_segment)) = 'sme' THEN 'SME'
		WHEN customer_segment IS NULL OR TRIM(customer_segment)='' THEN 'Segment unknown'
		ELSE INITCAP(TRIM(customer_segment))
	END AS customer_segment,
	CASE
		WHEN LOWER(TRIM(industry)) = 'it services' THEN 'IT Services'
		WHEN industry IS NULL OR TRIM(industry)='' THEN 'Industry unknown'
		ELSE INITCAP(TRIM(industry))
	END AS industry,
	CASE
		WHEN LOWER(TRIM(region)) = 'leipzig' THEN 'Leipzig'
		WHEN region IS NULL OR TRIM(region)='' THEN 'Region unknown'
		ELSE INITCAP(TRIM(region))
	END AS region
FROM portfolio.raw_customers;

--Check row count
SELECT COUNT(*) FROM staging.customers;
SELECT COUNT(*) FROM portfolio.raw_customers;
-- 10,000 rows. No rows missing.

--Check company_name
SELECT COUNT(*) FROM staging.customers
WHERE TRIM(company_name) <> company_name;
-- 0 names with trailing spaces.

--Check customer_segment
SELECT COUNT(*) FROM staging.customers
WHERE TRIM(customer_segment) <> customer_segment;
SELECT COUNT(*), customer_segment FROM staging.customers
GROUP BY customer_segment;
-- 0 names with trailing spaces, SME 4,047; Segment unknown 417.

--Check industry
SELECT COUNT(*) FROM staging.customers
WHERE TRIM(industry) <> industry;
SELECT COUNT(*), industry FROM staging.customers
GROUP BY industry;
-- 0 industries with trailing spaces, IT Services 2,219; Industry unknown 241.

--Check region
SELECT COUNT(*) FROM staging.customers
WHERE TRIM(region) <> region;
SELECT COUNT(*), region FROM staging.customers
GROUP BY region;
-- 0 regions with trailing spaces, Leipzig 2,203; Region unknown 182.
