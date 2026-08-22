-- Assignment 6: Analytical SQL Development


-- 1. ROW_NUMBER
-- Give each transaction a unique number for each customer

SELECT
    customer_id,
    transaction_id,
    transaction_date,
    total_amount,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY total_amount DESC
    ) AS row_num
FROM silver_schema.fact_sales
ORDER BY customer_id, row_num;



-- 2. RANK
-- Rank transactions by total amount for each customer

SELECT
    customer_id,
    transaction_id,
    transaction_date,
    total_amount,
    RANK() OVER (
        PARTITION BY customer_id
        ORDER BY total_amount DESC
    ) AS sales_rank
FROM silver_schema.fact_sales
ORDER BY customer_id, sales_rank;



-- 3. DENSE_RANK
-- Rank transactions without skipping rank numbers

SELECT
    customer_id,
    transaction_id,
    transaction_date,
    total_amount,
    DENSE_RANK() OVER (
        PARTITION BY customer_id
        ORDER BY total_amount DESC
    ) AS dense_sales_rank
FROM silver_schema.fact_sales
ORDER BY customer_id, dense_sales_rank;



-- 4. LEAD
-- Get the next transaction amount for each customer

SELECT
    customer_id,
    transaction_id,
    transaction_date,
    total_amount,
    LEAD(total_amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date, transaction_id
    ) AS next_transaction_amount
FROM silver_schema.fact_sales
ORDER BY customer_id, transaction_date, transaction_id;



-- 5. LAG
-- Get the previous transaction amount for each customer

SELECT
    customer_id,
    transaction_id,
    transaction_date,
    total_amount,
    LAG(total_amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date, transaction_id
    ) AS previous_transaction_amount
FROM silver_schema.fact_sales
ORDER BY customer_id, transaction_date, transaction_id;



-- 6. Running Total
-- Calculate cumulative sales for each customer

SELECT
    customer_id,
    transaction_id,
    transaction_date,
    total_amount,
    SUM(total_amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date, transaction_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM silver_schema.fact_sales
ORDER BY customer_id, transaction_date, transaction_id;



-- 7. Customer Sales Ranking
-- Calculate total sales for each customer

WITH customer_sales AS (
    SELECT
        c.customer_id,
        c.customer_name,
        co.country_name,
        SUM(f.total_amount) AS total_sales
    FROM silver_schema.fact_sales f
    JOIN silver_schema.dim_customer c
        ON f.customer_id = c.customer_id
    JOIN silver_schema.dim_country co
        ON c.country_code = co.country_code
    GROUP BY
        c.customer_id,
        c.customer_name,
        co.country_name
)

-- Rank customers by total sales within each country

SELECT
    customer_id,
    customer_name,
    country_name,
    total_sales,
    RANK() OVER (
        PARTITION BY country_name
        ORDER BY total_sales DESC
    ) AS customer_rank_in_country
FROM customer_sales
ORDER BY country_name, customer_rank_in_country;