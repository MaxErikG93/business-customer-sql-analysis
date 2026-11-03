-- 00_schema.sql
-- SQLite-compatible schema

DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS customer_products;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id TEXT PRIMARY KEY,
    company_name TEXT NOT NULL,
    industry TEXT NOT NULL,
    region TEXT NOT NULL,
    customer_segment TEXT NOT NULL,
    customer_since DATE NOT NULL
);

CREATE TABLE accounts (
    account_id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    account_type TEXT NOT NULL,
    currency TEXT NOT NULL,
    status TEXT NOT NULL,
    opening_balance REAL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE products (
    product_id TEXT PRIMARY KEY,
    product_name TEXT NOT NULL,
    product_category TEXT NOT NULL
);

CREATE TABLE customer_products (
    customer_product_id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    product_id TEXT NOT NULL,
    start_date DATE NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE transactions (
    transaction_id TEXT PRIMARY KEY,
    account_id TEXT NOT NULL,
    transaction_date DATE NOT NULL,
    transaction_type TEXT NOT NULL,
    direction TEXT NOT NULL,
    amount_eur REAL NOT NULL,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);
