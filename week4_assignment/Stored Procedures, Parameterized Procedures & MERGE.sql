-- =========================================================
-- Assignment 4: ETL Procedure Development
-- =========================================================


-- =========================================================
-- 1. Full Load Procedure
-- Purpose:
-- Truncate all Silver Layer tables and reload them completely
-- from the Raw Layer.
-- =========================================================

CREATE OR REPLACE PROCEDURE silver_schema.full_load_silver()
LANGUAGE plpgsql
AS '
BEGIN

    -- Remove all existing data from Silver tables
    -- before performing a full reload.
    TRUNCATE TABLE
        silver_schema.fact_sales,
        silver_schema.dim_customer,
        silver_schema.dim_product,
        silver_schema.dim_country;

    -- Load country dimension data from Raw Layer.
    INSERT INTO silver_schema.dim_country (
        country_code,
        country_name,
        region
    )
    SELECT
        country_code,
        country_name,
        region
    FROM raw_schema.country;

    -- Load customer dimension data from Raw Layer.
    INSERT INTO silver_schema.dim_customer (
        customer_id,
        customer_name,
        country_code,
        customer_type
    )
    SELECT
        customer_id,
        customer_name,
        country_code,
        customer_type
    FROM raw_schema.customer;

    -- Load product dimension data from Raw Layer.
    INSERT INTO silver_schema.dim_product (
        product_id,
        product_name,
        category,
        standard_price
    )
    SELECT
        product_id,
        product_name,
        category,
        standard_price
    FROM raw_schema.product;

    -- Load sales transactions into the fact table.
    INSERT INTO silver_schema.fact_sales (
        transaction_id,
        transaction_date,
        customer_id,
        product_id,
        quantity,
        unit_price,
        total_amount,
        payment_mode
    )
    SELECT
        transaction_id,
        transaction_date,
        customer_id,
        product_id,
        quantity,
        unit_price,
        total_amount,
        payment_mode
    FROM raw_schema.sales_transactions;

END;
';


-- Execute the full load procedure.
CALL silver_schema.full_load_silver();


-- Validate that all Silver tables were loaded successfully.
SELECT
    (SELECT COUNT(*) FROM silver_schema.dim_country) AS countries,
    (SELECT COUNT(*) FROM silver_schema.dim_customer) AS customers,
    (SELECT COUNT(*) FROM silver_schema.dim_product) AS products,
    (SELECT COUNT(*) FROM silver_schema.fact_sales) AS sales;



-- =========================================================
-- 2. Incremental Load Procedure
-- Purpose:
-- Load only new sales transactions that do not already exist
-- in the Silver fact table.
-- =========================================================

CREATE OR REPLACE PROCEDURE silver_schema.incremental_load_fact_sales()
LANGUAGE plpgsql
AS '
BEGIN

    -- Insert only transactions that are not already
    -- available in the Silver fact table.
    INSERT INTO silver_schema.fact_sales (
        transaction_id,
        transaction_date,
        customer_id,
        product_id,
        quantity,
        unit_price,
        total_amount,
        payment_mode
    )
    SELECT
        r.transaction_id,
        r.transaction_date,
        r.customer_id,
        r.product_id,
        r.quantity,
        r.unit_price,
        r.total_amount,
        r.payment_mode
    FROM raw_schema.sales_transactions r

    -- Check whether the transaction already exists in Silver.
    WHERE NOT EXISTS (
        SELECT 1
        FROM silver_schema.fact_sales s
        WHERE s.transaction_id = r.transaction_id
    );

END;
';


-- Check the highest transaction ID currently available in Raw.
SELECT MAX(transaction_id) AS max_transaction_id
FROM raw_schema.sales_transactions;


-- Insert a new test transaction into Raw Layer
-- to test incremental loading.
INSERT INTO raw_schema.sales_transactions (
    transaction_id,
    transaction_date,
    customer_id,
    product_id,
    quantity,
    unit_price,
    total_amount,
    payment_mode
)
VALUES (
    5001,
    '2024-12-31',
    'C0001',
    'P001',
    2,
    100.00,
    200.00,
    'CARD'
);


-- Validate that the customer used in the test transaction exists.
SELECT customer_id
FROM raw_schema.customer
WHERE customer_id = 'C0001';


-- Validate that the product used in the test transaction exists.
SELECT product_id
FROM raw_schema.product
WHERE product_id = 'P001';


-- Check the number of transactions in Raw Layer.
SELECT COUNT(*) AS raw_sales
FROM raw_schema.sales_transactions;


-- Check the number of transactions in Silver Layer
-- before incremental loading.
SELECT COUNT(*) AS silver_sales
FROM silver_schema.fact_sales;


-- Execute the incremental load procedure.
-- Only new transactions should be inserted.
CALL silver_schema.incremental_load_fact_sales();


-- Validate that the new transaction was added to Silver.
SELECT COUNT(*) AS silver_sales
FROM silver_schema.fact_sales;



-- =========================================================
-- 3. MERGE Procedure
-- Purpose:
-- Synchronize sales data between Raw and Silver.
--
-- If the transaction already exists -> UPDATE it.
-- If the transaction does not exist -> INSERT it.
-- =========================================================

CREATE OR REPLACE PROCEDURE silver_schema.merge_fact_sales()
LANGUAGE plpgsql
AS '
BEGIN

    MERGE INTO silver_schema.fact_sales AS s
    USING raw_schema.sales_transactions AS r
        ON s.transaction_id = r.transaction_id

    -- Update the Silver record when the same transaction
    -- already exists.
    WHEN MATCHED THEN
        UPDATE SET
            transaction_date = r.transaction_date,
            customer_id      = r.customer_id,
            product_id       = r.product_id,
            quantity         = r.quantity,
            unit_price       = r.unit_price,
            total_amount     = r.total_amount,
            payment_mode     = r.payment_mode

    -- Insert a new record when the transaction
    -- does not exist in Silver.
    WHEN NOT MATCHED THEN
        INSERT (
            transaction_id,
            transaction_date,
            customer_id,
            product_id,
            quantity,
            unit_price,
            total_amount,
            payment_mode
        )
        VALUES (
            r.transaction_id,
            r.transaction_date,
            r.customer_id,
            r.product_id,
            r.quantity,
            r.unit_price,
            r.total_amount,
            r.payment_mode
        );

END;
';


-- =========================================================
-- Test 1: MERGE UPDATE
-- =========================================================

-- Change an existing Raw transaction to test
-- the WHEN MATCHED -> UPDATE operation.
UPDATE raw_schema.sales_transactions
SET
    unit_price = 150.00,
    total_amount = 300.00
WHERE transaction_id = 5001;


-- Execute the MERGE procedure.
CALL silver_schema.merge_fact_sales();


-- Verify that transaction 5001 was updated in Silver.
SELECT
    transaction_id,
    quantity,
    unit_price,
    total_amount
FROM silver_schema.fact_sales
WHERE transaction_id = 5001;



-- =========================================================
-- Test 2: MERGE INSERT
-- =========================================================

-- Add another new transaction to Raw Layer
-- to test the WHEN NOT MATCHED -> INSERT operation.
INSERT INTO raw_schema.sales_transactions (
    transaction_id,
    transaction_date,
    customer_id,
    product_id,
    quantity,
    unit_price,
    total_amount,
    payment_mode
)
VALUES (
    5002,
    '2024-12-31',
    'C0001',
    'P001',
    3,
    200.00,
    600.00,
    'CARD'
);


-- Execute the MERGE procedure again.
CALL silver_schema.merge_fact_sales();


-- Verify that transaction 5002 was inserted into Silver.
SELECT
    transaction_id,
    quantity,
    unit_price,
    total_amount
FROM silver_schema.fact_sales
WHERE transaction_id = 5002;