/*
File:    02_data_quality_audit.sql
Purpose: Read-only audit of raw data in schema portfolio
Note:    All data is synthetic.
*/

/*
Summary of findings:
- raw_customers: missing values up to 6.2 % (email), spelling variants in
  segment/industry/region, 220 placeholder emails, no true duplicates.
- raw_accounts: 223 accounts (1.1 %) reference non-existing customers.
- raw_transactions: 5.6 % unusable amounts, invalid/future dates,
  2,398 transactions (1.2 %) reference non-existing accounts.
*/

-- ============================================
-- 0. Structure check
-- ============================================

--Check which tables are part of the DB-Schema
SELECT
    table_schema,
    table_name	-- Name of table
FROM information_schema.tables
WHERE table_schema = 'portfolio'
ORDER BY table_name;

--Check Columns and data-types for all tables in DB-Schema.
SELECT
    table_name,
    ordinal_position,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'portfolio'
ORDER BY table_name, ordinal_position;

-- ============================================
-- 1. Missing values in raw_customers
-- ============================================

-- Missing in company names
SELECT
    COUNT(*)                                          						AS total_rows,
    COUNT(*) FILTER (WHERE company_name IS NULL)      						AS company_name_null,
    COUNT(*) FILTER (WHERE TRIM(company_name) = '')   						AS company_name_empty,
	COUNT(*) FILTER (WHERE TRIM(company_name)<>company_name) 				AS company_name_untrimmed,
	COUNT(*) FILTER (WHERE company_name IS NULL OR TRIM(company_name)='')	AS company_name_missing_total,
	ROUND(100.0*(COUNT(*) FILTER (WHERE company_name IS NULL OR TRIM(company_name)=''))/COUNT(*),1)	AS company_name_missing_percent
FROM portfolio.raw_customers;
-- 0 NULL, 0 empty (0 missing = 0.0 %), 279 with leading/trailing spaces

-- Missing in customer_segment
SELECT
	COUNT(*)																		AS total_rows,
	COUNT(*) FILTER(WHERE customer_segment IS NULL) 								AS customer_segment_null,
	COUNT(*) FILTER(WHERE TRIM(customer_segment) = '') 								AS customer_segment_empty,
	COUNT(*) FILTER (WHERE TRIM(customer_segment)<>customer_segment) 				AS customer_segment_untrimmed,
	COUNT(*) FILTER (WHERE customer_segment IS NULL OR TRIM(customer_segment)='') 	AS customer_segment_missing_total,
	ROUND(100.0*(COUNT(*) FILTER (WHERE customer_segment IS NULL OR TRIM(customer_segment)=''))/COUNT(*),1) 	AS customer_segment_missing_percent
FROM portfolio.raw_customers;
-- 265 NULL, 152 empty (417 missing = 4.2 %), 680 with leading/trailing spaces


-- Missing in industry
SELECT
	COUNT(*)														AS total_rows,
	COUNT(*) FILTER(WHERE industry IS NULL) 						AS industry_null,
	COUNT(*) FILTER(WHERE TRIM(industry) = '') 						AS industry_empty,
	COUNT(*) FILTER (WHERE TRIM(industry)<>industry) 				AS industry_untrimmed,
	COUNT(*) FILTER (WHERE industry IS NULL OR TRIM(industry)='') 	AS industry_missing_total,
	ROUND(100.0*(COUNT(*) FILTER (WHERE industry IS NULL OR TRIM(industry)=''))/COUNT(*),1) 	AS industry_missing_percent
FROM portfolio.raw_customers;
-- 241 NULL, 0 empty (241 missing = 2.4 %), 229 with leading/trailing spaces


-- Missing in region
SELECT
	COUNT(*)													AS total_rows,
	COUNT(*) FILTER(WHERE region IS NULL) 						AS region_null,
	COUNT(*) FILTER(WHERE TRIM(region) = '') 					AS region_empty,
	COUNT(*) FILTER (WHERE TRIM(region)<>region) 				AS region_untrimmed,
	COUNT(*) FILTER (WHERE region IS NULL OR TRIM(region)='') 	AS region_missing_total,
	ROUND(100.0*(COUNT(*) FILTER (WHERE region IS NULL OR TRIM(region)=''))/COUNT(*),1) 	AS region_missing_percent
FROM portfolio.raw_customers;
-- 182 NULL, 0 empty (182 missing = 1.8 %), 0 with leading/trailing spaces


-- Missing in email
SELECT
	COUNT(*)													AS total_rows,
	COUNT(*) FILTER(WHERE email IS NULL) 						AS email_null,
	COUNT(*) FILTER(WHERE TRIM(email) = '') 					AS email_empty,
	COUNT(*) FILTER (WHERE TRIM(email)<>email) 					AS email_untrimmed,
	COUNT(*) FILTER (WHERE email IS NULL OR TRIM(email)='') 	AS email_missing_total,
	ROUND(100.0 * (COUNT(*) FILTER (WHERE email IS NULL OR TRIM(email)=''))/COUNT(*),1) 	AS email_missing_percent
FROM portfolio.raw_customers;
-- 412 NULL, 208 empty (620 missing = 6.2 %), 0 with leading/trailing spaces


-- ============================================
-- 2. Duplicates in raw_customers
-- ============================================

-- Exact duplicates: same company_name appearing more than once
SELECT company_name, COUNT(*) AS name_count
FROM portfolio.raw_customers
GROUP BY company_name
HAVING COUNT(*) > 1
ORDER BY name_count DESC, company_name;
-- detects 47 names that appear twice. No name shows up more than 2 times.


-- Normalized duplicates: 
SELECT LOWER(TRIM(company_name)) as normalized_name, COUNT(*) AS name_count
FROM portfolio.raw_customers
GROUP BY LOWER(TRIM(company_name))
HAVING COUNT(*) > 1
ORDER BY name_count DESC, normalized_name;
-- also detects 47 names that show up twice. No names show up more than 2 times. --> no hidden duplicates.


-- Examination
SELECT customer_id, company_name, email, postal_code, created_at_raw 
FROM portfolio.raw_customers
WHERE LOWER(TRIM(company_name))='company 210 gmbh'
ORDER BY customer_id;
-- different email and different postal code meaning different customer. Duplicate name alone is not a duplicate customer.

-- Result: 47 company names appear twice (94 rows, ~0.9 % of customers),
-- no hidden duplicates after TRIM/LOWER.
-- Decision: Same name alone is NOT a duplicate (different email and postal
-- code). Rows are kept and only flagged as name collisions in staging.


-- customer_id should be unique
SELECT customer_id, COUNT(*) AS id_count
FROM portfolio.raw_customers
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY id_count DESC, customer_id;
-- 0 rows: customer_id is unique.


-- check duplicate emails
SELECT LOWER(TRIM(email)) AS normalized_email, COUNT(*) as email_count
FROM portfolio.raw_customers
WHERE TRIM(email) <>''
GROUP BY LOWER(TRIM(email))
HAVING COUNT(*) > 1
ORDER BY email_count DESC, LOWER(TRIM(email));
-- Result: 1 group with count > 1: 'not-an-email' (220 rows). It is an invalid
-- placeholder, not a real duplicate. All other emails are unique.
-- Decision: handle 'not-an-email' as invalid email in cleaning (set to NULL).


-- ============================================
-- 3. Spelling variants in raw_customers
-- ============================================

-- Distinct spellings in customer_segment
SELECT 
    '[' || customer_segment || ']' AS segment_visible,
    COUNT(*)                       AS n
FROM portfolio.raw_customers
GROUP BY customer_segment
ORDER BY customer_segment;
-- all three sme, should belong together in one group
-- [] and [null] should both be relabeled as "segment unknown"


-- Normalized spellings in customer_segment (LOWER/TRIM, NULLIF for empty)
SELECT LOWER(NULLIF(TRIM(customer_segment),'')) as customer_segment_trimmed, COUNT(*) as customer_segment_count
FROM portfolio.raw_customers
GROUP BY LOWER(NULLIF(TRIM(customer_segment),''))
ORDER BY customer_segment_count DESC, customer_segment_trimmed;
-- Result: 3 spellings of 'SME' (4,047 rows) merge into one after LOWER/TRIM.
-- 417 missing (265 NULL + 152 empty, 4.2 %) merge into one NULL group.
-- 4 categories remain.

-- Distinct spellings in industry
SELECT 
    '[' || industry || ']' AS industry_visible,
    COUNT(*)                       AS n
FROM portfolio.raw_customers
GROUP BY industry
ORDER BY industry;

-- Normalized spellings in industry (LOWER/TRIM, NULLIF for empty)
SELECT LOWER(NULLIF(TRIM(industry),'')) as industry_trimmed, COUNT(*) as industry_count
FROM portfolio.raw_customers
GROUP BY LOWER(NULLIF(TRIM(industry),''))
ORDER BY industry_count DESC, industry_trimmed;
-- Result: 3 spellings of 'IT Services' (2,219 rows) merge into one after LOWER/TRIM. 241 NULL (2.4 %), no empty strings. 7 categories remain.


-- Distinct spellings in region
SELECT 
    '[' || region || ']' AS region_visible,
    COUNT(*)                       AS n
FROM portfolio.raw_customers
GROUP BY region
ORDER BY region;
-- three distinct versions of "Leipzig", no leading or trailing empty spaces so lower is enough

-- Normalized spellings in region (LOWER/TRIM, NULLIF for empty values)
SELECT LOWER(NULLIF(TRIM(region),'')) as region_trimmed, COUNT(*) as region_count
FROM portfolio.raw_customers
GROUP BY LOWER(NULLIF(TRIM(region),''))
ORDER BY region_count DESC, region_trimmed;
-- Result: 3 spellings of 'Leipzig' (2,203 rows) merge into one after LOWER/TRIM. 182 NULL (1.8 %), no empty strings. 7 categories remain.


-- ============================================
-- 4. Invalid values in raw_transactions
-- ============================================

-- Amount categories in raw_transactions
-- since amount_raw is TEXT, there might be mistakes or "N/A" values. They can produce errors when transforming to numbers with CAST
SELECT
    COUNT(*)                                          	AS total_rows,
    COUNT(*) FILTER (WHERE amount_raw IS NULL)        	AS amount_null,
    COUNT(*) FILTER (WHERE TRIM(amount_raw) = '')    	AS amount_empty,
    COUNT(*) FILTER (
        WHERE TRIM(amount_raw) <> ''
          AND TRIM(amount_raw) !~ '^-?[0-9]+(\.[0-9]+)?$'
    )                                                 	AS amount_not_numeric,
	COUNT(*) FILTER (WHERE TRIM(amount_raw) LIKE '-%') 	AS amount_negative
FROM portfolio.raw_transactions;
-- Result: 200,000 rows: 5,073 NULL (2.5 %), 2,056 empty (1.0 %),
-- 3,998 non-numeric (2.0 %) -> 11,127 unusable amounts (5.6 %).
-- 2,001 negative amounts (1.0 %): valid numbers, but business meaning unclear
-- (refunds or errors?).
-- Decision: keep negatives in staging, flag them; decide in the analysis.


-- detect different versions of non-numeric values.
SELECT 
	amount_raw, 
	COUNT (*) AS n
FROM portfolio.raw_transactions
	WHERE TRIM(amount_raw) <> ''
    	AND TRIM(amount_raw) !~ '^-?[0-9]+(\.[0-9]+)?$'
GROUP BY amount_raw
ORDER BY n DESC;
-- Result: 2 non-numeric formats (3,998 rows): 'N/A' (1,977) and the German
-- format '1.250,50 EUR' (2,021, always the same value).
-- Note: In real data, one repeated value would be a red flag. Here it is most likely an artifact of the synthetic data generation.
-- Decision: 'N/A' -> NULL; German format needs parsing in cleaning.		  

-- detect different versions of date-values in transaction_date_raw
SELECT
	COUNT(*) AS	n, 
	COUNT(*) FILTER (WHERE transaction_date_raw IS NULL) AS date_null,
	COUNT(*) FILTER (WHERE TRIM(transaction_date_raw) <> ''
		AND TRIM(transaction_date_raw) !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') as date_wrong_format
FROM portfolio.raw_transactions;
-- Result: 200,000 rows. 5,126 NULL values (2.6%). 4,039 (2%) dates in wrong format.

SELECT transaction_date_raw,
	COUNT(*) as n
FROM portfolio.raw_transactions
WHERE TRIM(transaction_date_raw) <> ''
		AND TRIM(transaction_date_raw) !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
GROUP BY transaction_date_raw
ORDER BY n DESC;
-- Result: 5,126 NULL (2.6 %); 4,039 wrong format (2.0 %): 'not-a-date' (2,039)
-- and '31.02.2025' (2,000).
-- Note: '31.02.2025' is day.month.year AND an impossible date (no 31 February),
-- so reformatting alone would not make it convertible.
-- Decision: both -> NULL in cleaning.

-- Check for future dates
-- because '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' only tests for format, but not future or non-possible dates.
SELECT 
	COUNT(*) FILTER (
    WHERE CASE
              WHEN TRIM(transaction_date_raw) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
              THEN TRIM(transaction_date_raw)::DATE
          END > CURRENT_DATE) as future_dates
FROM portfolio.raw_transactions;

SELECT max(CASE
              WHEN TRIM(transaction_date_raw) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
              THEN TRIM(transaction_date_raw)::DATE 
		END) as max_date
FROM portfolio.raw_transactions;
-- Result: 5,827 dates after CURRENT_DATE (run on 2026-10-31); latest date 2028-12-31.
-- Note: ~2,000 are the deliberately planted value 2028-12-31, the rest is
-- regular data running past today. The count depends on the run date.
-- Decision: treat dates after the reference date as invalid (NULL) in cleaning.


-- ============================================
-- 5. Referential integrity
-- ============================================

-- Check for reference integrity
-- each account should belong to an existing customer and each transaction should belong to a specific account

-- Accounts that reference a non-existing customer
SELECT COUNT(*) AS orphan_accounts
FROM portfolio.raw_accounts AS a
LEFT JOIN portfolio.raw_customers AS c
ON a.customer_id_raw = c.customer_id
WHERE c.customer_id IS NULL;
-- Result: 223 of 20,000 accounts (1.1 %) reference a non-existing customer.

-- check count of invalid customer id
SELECT a.customer_id_raw AS invalid_customer_id, COUNT(*) AS n
FROM portfolio.raw_accounts AS a
LEFT JOIN portfolio.raw_customers AS c
    ON a.customer_id_raw = c.customer_id
WHERE c.customer_id IS NULL
GROUP BY a.customer_id_raw;
-- Result: two customer_ids from accounts have no match in the customer table.
-- ID 0: 157 accounts, ID 10001: 66 accounts (157 + 66 = 223).
-- Note: 0 looks like a placeholder; 10001 is one above the highest customer_id.
-- Decision: set invalid references to NULL in staging (flag, do not delete).


-- check if account IDs are unique before joining
SELECT a.account_id
FROM portfolio.raw_accounts AS a
GROUP BY a.account_id
HAVING COUNT(*) > 1;
-- 0 rows: all account IDs are unique. No duplication due to joins expected.

-- Transactions that reference a non-existing account
SELECT COUNT(*) AS orphan_transactions
FROM portfolio.raw_transactions AS t
LEFT JOIN portfolio.raw_accounts AS a
ON t.account_id_raw = a.account_id
WHERE a.account_id IS NULL;
-- Result: 2,398 of 200,000 transactions (1.2 %) reference a non-existing account.

-- check count of invalid account id
SELECT t.account_id_raw AS invalid_account_id, COUNT(*) AS n
FROM portfolio.raw_transactions AS t
LEFT JOIN portfolio.raw_accounts AS a
ON t.account_id_raw = a.account_id
WHERE a.account_id IS NULL
GROUP BY t.account_id_raw;
-- Result: two account_ids from transactions have no match in accounts.
-- ID 0: 1,626 transactions, ID 20001: 772 transactions (1,626 + 772 = 2,398).
-- Note: same pattern as for accounts (0 and highest ID + 1).
-- Decision: set invalid references to NULL in staging (flag, do not delete).


-- ============================================
-- 6. Data Quality in raw_accounts
-- ============================================

-- Distinct spellings in account_type
SELECT 
    '[' || account_type || ']' AS account_type_visible,
    COUNT(*)                       AS n
FROM portfolio.raw_accounts
GROUP BY account_type
ORDER BY account_type;

-- Normalized spellings in account_type (LOWER/TRIM, NULLIF for empty values)
SELECT LOWER(NULLIF(TRIM(account_type),'')) as account_type_trimmed, COUNT(*) as account_type_count
FROM portfolio.raw_accounts
GROUP BY LOWER(NULLIF(TRIM(account_type),''))
ORDER BY account_type_count DESC, account_type_trimmed;
-- Result: 3 spellings of 'Business Current' (lowercase, correct, trailing
-- space) with 500 / 8,916 / 595 rows merge into one (10,011 rows) after LOWER/TRIM.
-- 450 NULL (2.25 %), no empty strings. 4 categories remain.


-- Distinct spellings in account_status
SELECT 
    '[' || account_status || ']' AS account_status_visible,
    COUNT(*)                       AS n
FROM portfolio.raw_accounts
GROUP BY account_status
ORDER BY account_status;

-- Normalized spellings in account_status (LOWER/TRIM, NULLIF for empty values)
SELECT LOWER(NULLIF(TRIM(account_status),'')) as account_status_trimmed, COUNT(*) as account_status_count
FROM portfolio.raw_accounts
GROUP BY LOWER(NULLIF(TRIM(account_status),''))
ORDER BY account_status_count DESC, account_status_trimmed;
-- Result: 2 spellings of 'Active' ('active ' with 457 rows, 'Active' with
-- 12,959 rows) merge into one (13,416 rows) after LOWER/TRIM.
-- 500 NULL (2.5 %), no empty strings. 3 categories remain.


-- detect different versions of date-values in opened_at_raw
SELECT 	COUNT(*) AS total_raws,
		COUNT(*) FILTER (WHERE opened_at_raw IS NULL) AS opened_at_null,
		COUNT(*) FILTER (WHERE TRIM(opened_at_raw) <> ''
						AND TRIM(opened_at_raw) !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') as opened_at_wrong_format
FROM portfolio.raw_accounts;

--examine different versions of wrongly formatted date-values for opened_at_raw
SELECT opened_at_raw, COUNT(*) AS n
FROM portfolio.raw_accounts
WHERE TRIM(opened_at_raw) <> '' AND TRIM(opened_at_raw) !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
GROUP BY opened_at_raw;
-- Result: 603 NULL (3.0 %); 397 wrong format (2.0 %), all of them 'not recorded'.
-- Decision: set to NULL in cleaning.

-- Check for illogical opening dates, e.g. dates in the future
SELECT 	MAX(CASE
              WHEN TRIM(opened_at_raw) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
              THEN TRIM(opened_at_raw)::DATE 
			END) AS max_date,
		MIN(CASE
			  WHEN TRIM(opened_at_raw) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
              THEN TRIM(opened_at_raw)::DATE 
			END) AS min_date
FROM portfolio.raw_accounts;
-- Result: opened_at_raw ranges from 2019-05-08 to 2025-12-29.
-- No future dates and no impossible dates (the cast ran without errors).
-- Decision: no additional date cleaning needed beyond 'not recorded' -> NULL.

-- ============================================
-- 7. Spelling variations in raw_transactions
-- ============================================

-- Distinct spellings in currency_raw
SELECT 
    '[' || currency_raw || ']' AS currency_raw_visible,
    COUNT(*)                       AS n
FROM portfolio.raw_transactions
GROUP BY currency_raw
ORDER BY currency_raw;

-- Normalized spellings in currency_raw (LOWER/TRIM, NULLIF for empty values)
SELECT LOWER(NULLIF(TRIM(currency_raw),'')) as currency_raw_trimmed, COUNT(*) as currency_raw_count
FROM portfolio.raw_transactions
GROUP BY LOWER(NULLIF(TRIM(currency_raw),''))
ORDER BY currency_raw_count DESC, currency_raw_trimmed;
-- Result: 3 spellings of 'EUR' ('eur' with 4,991 rows, 'EUR' with
-- 184,979 rows and 'EUR ' with 4,987 rows) merge into one (eur with 194,957 rows) after LOWER/TRIM.
-- 5,043 NULL (2.5 %), no empty strings. 1 category remains.
-- Note: only one currency (EUR) in the data, so amounts can be summed without conversion.
-- Decision: standardize to 'EUR' (upper case) in staging; NULL stays NULL.

-- Distinct spellings in status_raw
SELECT 
    '[' || status_raw || ']' AS status_raw_visible,
    COUNT(*)                       AS n
FROM portfolio.raw_transactions
GROUP BY status_raw
ORDER BY status_raw;

-- Normalized spellings in status_raw (LOWER/TRIM, NULLIF for empty values)
SELECT LOWER(NULLIF(TRIM(status_raw),'')) as status_raw_trimmed, COUNT(*) as status_raw_count
FROM portfolio.raw_transactions
GROUP BY LOWER(NULLIF(TRIM(status_raw),''))
ORDER BY status_raw_count DESC, status_raw_trimmed;
-- Result: 2 spellings of 'Completed' ('Completed' with 145,902 rows and 'completed ' with
-- 4,939 rows) merge into one ('completed' with 150,841 rows) after LOWER/TRIM.
-- 5,146 NULL (2.6 %), no empty strings. 3 categories remain.
