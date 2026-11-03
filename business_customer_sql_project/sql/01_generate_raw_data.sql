/*
File:    01_generate_raw_data.sql
Purpose: generate a synthetic raw-data set of 10,000 customers, 20,000 accounts and 200,000 transactions. 
Note:    All data is synthetic. The raw-data includes mistakes and missing values.
*/


BEGIN;

-- Generate Schema. 
CREATE SCHEMA IF NOT EXISTS portfolio;

-- Replace only the raw data tables managed by this script.
DROP TABLE IF EXISTS portfolio.raw_transactions;
DROP TABLE IF EXISTS portfolio.raw_accounts;
DROP TABLE IF EXISTS portfolio.raw_customers;

-- ------------------------------------------------------------
-- 1. CUSTOMERS
-- Deliberately no technical constraints: Errors should be preserved
-- and identified later on their own.
-- ------------------------------------------------------------

CREATE TABLE portfolio.raw_customers (
    customer_id       INTEGER,
    company_name      TEXT,
    customer_segment  TEXT,
    industry          TEXT,
    region            TEXT,
    postal_code       TEXT,
    email             TEXT,
    created_at_raw    TEXT
);

-- Random initial value: reproducible data generation
SELECT setseed(0.4242);

WITH generated AS MATERIALIZED (
    SELECT
        gs,
        random() AS r_segment,
        random() AS r_industry,
        random() AS r_region,
        random() AS r_postcode,
        random() AS r_email,
        random() AS r_created,
        random() AS r_error
    FROM generate_series(1, 10000) AS gs
)
INSERT INTO portfolio.raw_customers
SELECT
    gs,

    -- Duplicate company names for different IDs
    CASE
        WHEN gs > 1 AND gs % 211 = 0
            THEN 'Company ' || (gs - 1) || ' GmbH'
        WHEN r_error < 0.025
            THEN ' Company ' || gs || ' GmbH '
        ELSE 'Company ' || gs || ' GmbH'
    END,

    CASE
        WHEN r_segment < 0.025 THEN NULL
        WHEN r_segment < 0.045 THEN ''
        WHEN r_segment < 0.12  THEN 'sme'
        WHEN r_segment < 0.19  THEN 'SME '
        WHEN r_segment < 0.45  THEN 'SME'
        WHEN r_segment < 0.72  THEN 'Enterprise'
        WHEN r_segment < 0.88  THEN 'Mid-Market'
        ELSE 'Small Business'
    END,

    CASE
        WHEN r_industry < 0.025 THEN NULL
        WHEN r_industry < 0.05  THEN 'IT services'
        WHEN r_industry < 0.075 THEN 'IT Services '
        WHEN r_industry < 0.25  THEN 'IT Services'
        WHEN r_industry < 0.43  THEN 'Manufacturing'
        WHEN r_industry < 0.58  THEN 'Healthcare'
        WHEN r_industry < 0.72  THEN 'Retail'
        WHEN r_industry < 0.84  THEN 'Professional Services'
        WHEN r_industry < 0.94  THEN 'Logistics'
        ELSE 'Energy'
    END,

    CASE
        WHEN r_region < 0.02 THEN NULL
        WHEN r_region < 0.05 THEN 'leipzig'
        WHEN r_region < 0.08 THEN 'LEIPZIG'
        WHEN r_region < 0.24 THEN 'Leipzig'
        WHEN r_region < 0.40 THEN 'Berlin'
        WHEN r_region < 0.53 THEN 'Hamburg'
        WHEN r_region < 0.66 THEN 'Munich'
        WHEN r_region < 0.78 THEN 'Cologne'
        WHEN r_region < 0.89 THEN 'Frankfurt'
        ELSE 'Dresden'
    END,

    CASE
        WHEN r_postcode < 0.025 THEN NULL
        WHEN r_postcode < 0.04  THEN 'XXXXX'
        WHEN r_postcode < 0.06  THEN '123'
        ELSE LPAD(
            (10000 + FLOOR(r_postcode * 89999)::INTEGER)::TEXT,
            5,
            '0'
        )
    END,

    CASE
        WHEN r_email < 0.04 THEN NULL
        WHEN r_email < 0.06 THEN 'not-an-email'
        WHEN r_email < 0.08 THEN ''
        ELSE 'contact' || gs || '@example.com'
    END,

    CASE
        WHEN r_created < 0.03 THEN NULL
        WHEN r_created < 0.05 THEN 'unknown'
        ELSE TO_CHAR(
            DATE '2020-01-01'
              + FLOOR(r_created * 2190)::INTEGER,
            'YYYY-MM-DD'
        )
    END
FROM generated;


-- ------------------------------------------------------------
-- 2. ACCOUNTS
-- Normally two accounts per customer.
-- Raw data without foreign keys, so that orphaned references
-- can also be stored and detected later.
-- ------------------------------------------------------------

CREATE TABLE portfolio.raw_accounts (
    account_id       INTEGER,
    customer_id_raw  INTEGER,
    account_type     TEXT,
    account_status   TEXT,
    opened_at_raw    TEXT
);

WITH generated AS MATERIALIZED (
    SELECT
        gs,
        random() AS r_customer,
        random() AS r_type,
        random() AS r_status,
        random() AS r_date,
        random() AS r_error
    FROM generate_series(1, 20000) AS gs
)
INSERT INTO portfolio.raw_accounts
SELECT
    gs,

    CASE
        WHEN r_error < 0.008 THEN 0
        WHEN r_error < 0.012 THEN 10001
        ELSE ((gs - 1) / 2) + 1
    END,

    CASE
        WHEN r_type < 0.025 THEN NULL
        WHEN r_type < 0.05  THEN 'business current'
        WHEN r_type < 0.08  THEN 'Business Current '
        WHEN r_type < 0.52  THEN 'Business Current'
        WHEN r_type < 0.73  THEN 'Savings'
        WHEN r_type < 0.90  THEN 'Investment'
        ELSE 'Credit'
    END,

    CASE
        WHEN r_status < 0.025 THEN NULL
        WHEN r_status < 0.05  THEN 'active '
        WHEN r_status < 0.70  THEN 'Active'
        WHEN r_status < 0.88  THEN 'Closed'
        ELSE 'Suspended'
    END,

    CASE
        WHEN r_date < 0.03 THEN NULL
        WHEN r_date < 0.05 THEN 'not recorded'
        ELSE TO_CHAR(
            DATE '2019-01-01'
              + FLOOR(r_date * 2555)::INTEGER,
            'YYYY-MM-DD'
        )
    END
FROM generated;


-- ------------------------------------------------------------
-- 3. TRANSACTIONS
-- amount_raw and transaction_date_raw are deliberately TEXT:
-- This way, even invalid formats are preserved unchanged.
-- ------------------------------------------------------------

CREATE TABLE portfolio.raw_transactions (
    transaction_id       INTEGER,
    account_id_raw       INTEGER,
    transaction_date_raw TEXT,
    amount_raw           TEXT,
    currency_raw         TEXT,
    status_raw           TEXT,
    source_system        TEXT
);

WITH generated AS MATERIALIZED (
    SELECT
        gs,
        random() AS r_account,
        random() AS r_date,
        random() AS r_amount,
        random() AS r_currency,
        random() AS r_status,
        random() AS r_source,
        random() AS r_error
    FROM generate_series(1, 200000) AS gs
),
prepared AS MATERIALIZED (
    SELECT
        gs,

        CASE
            WHEN r_account < 0.008 THEN 0
            WHEN r_account < 0.012 THEN 20001
            ELSE 1 + FLOOR(r_account * 20000)::INTEGER
        END AS account_id_raw,

        CASE
            WHEN r_date < 0.025 THEN NULL
            WHEN r_date < 0.035 THEN 'not-a-date'
            WHEN r_date < 0.045 THEN '31.02.2025'
            WHEN r_date < 0.055 THEN '2028-12-31'
            ELSE TO_CHAR(
                DATE '2022-01-01'
                  + FLOOR(r_date * 1800)::INTEGER,
                'YYYY-MM-DD'
            )
        END AS transaction_date_raw,

        CASE
            WHEN r_amount < 0.025 THEN NULL
            WHEN r_amount < 0.035 THEN 'N/A'
            WHEN r_amount < 0.045 THEN '1.250,50 EUR'
            WHEN r_amount < 0.055 THEN ''
            WHEN r_amount < 0.065 THEN
                (-1 * ROUND((r_amount * 100000)::NUMERIC, 2))::TEXT
            ELSE
                ROUND((r_amount * 100000)::NUMERIC, 2)::TEXT
        END AS amount_raw,

        CASE
            WHEN r_currency < 0.025 THEN NULL
            WHEN r_currency < 0.05  THEN 'eur'
            WHEN r_currency < 0.075 THEN 'EUR '
            ELSE 'EUR'
        END AS currency_raw,

        CASE
            WHEN r_status < 0.025 THEN NULL
            WHEN r_status < 0.05  THEN 'completed '
            WHEN r_status < 0.78  THEN 'Completed'
            WHEN r_status < 0.90  THEN 'Pending'
            ELSE 'Cancelled'
        END AS status_raw,

        CASE
            WHEN r_source < 0.34 THEN 'Core Banking'
            WHEN r_source < 0.67 THEN 'CRM Export'
            ELSE 'Legacy System'
        END AS source_system

    FROM generated
)
INSERT INTO portfolio.raw_transactions (
    transaction_id,
    account_id_raw,
    transaction_date_raw,
    amount_raw,
    currency_raw,
    status_raw,
    source_system
)
SELECT
    p.gs,

    -- Roughly 1 in 997 transactions copies the business values
    -- of the previous transaction: a duplicate with a new ID.
    CASE
        WHEN p.gs > 1 AND p.gs % 997 = 0
            THEN prev.account_id_raw
        ELSE p.account_id_raw
    END,

    CASE
        WHEN p.gs > 1 AND p.gs % 997 = 0
            THEN prev.transaction_date_raw
        ELSE p.transaction_date_raw
    END,

    CASE
        WHEN p.gs > 1 AND p.gs % 997 = 0
            THEN prev.amount_raw
        ELSE p.amount_raw
    END,

    CASE
        WHEN p.gs > 1 AND p.gs % 997 = 0
            THEN prev.currency_raw
        ELSE p.currency_raw
    END,

    CASE
        WHEN p.gs > 1 AND p.gs % 997 = 0
            THEN prev.status_raw
        ELSE p.status_raw
    END,

    CASE
        WHEN p.gs > 1 AND p.gs % 997 = 0
            THEN prev.source_system
        ELSE p.source_system
    END

FROM prepared p
LEFT JOIN prepared prev
    ON prev.gs = p.gs - 1;

COMMIT;


-- ------------------------------------------------------------
-- 4. CHECK QUERY: IS ALL DATA PRESENT?
-- ------------------------------------------------------------

SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM portfolio.raw_customers

UNION ALL

SELECT 'accounts', COUNT(*)
FROM portfolio.raw_accounts

UNION ALL

SELECT 'transactions', COUNT(*)
FROM portfolio.raw_transactions;
