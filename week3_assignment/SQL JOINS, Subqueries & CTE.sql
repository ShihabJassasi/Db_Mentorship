---1) Multiple Table Joins

SELECT
    f.transaction_id,
    f.transaction_date,
    c.customer_name,
    co.country_name,
    co.region,
    p.product_name,
    p.category,
    f.quantity,
    f.unit_price,
    f.total_amount,
    f.payment_mode
FROM silver_schema.fact_sales f
JOIN silver_schema.dim_customer c
    ON f.customer_id = c.customer_id
JOIN silver_schema.dim_country co
    ON c.country_code = co.country_code
JOIN silver_schema.dim_product p
    ON f.product_id = p.product_id
ORDER BY f.transaction_date;

--# I used multiple table joins to combine sales transactions with customer
--country, and product information, so the transaction data becomes more 
--meaningful for business analysis.

--------------------------------------------------------------------------
--2) Nested Query
SELECT AVG(total_amount) AS average_sales_amount
FROM silver_schema.fact_sales;

SELECT
    transaction_id,
    transaction_date,
    customer_id,
    product_id,
    total_amount
FROM silver_schema.fact_sales
WHERE total_amount > (
    SELECT AVG(total_amount)
    FROM silver_schema.fact_sales
)
ORDER BY total_amount DESC;

--#The nested query calculates the average sales amount dynamically
--and the outer query uses that result to identify 
--transactions above the average.

-------------------------------------------------------------------------
---3) CTE-Based Transformation

WITH customer_sales AS (
    SELECT
        f.customer_id,
        COUNT(f.transaction_id) AS total_transactions,
        SUM(f.total_amount) AS total_sales
    FROM silver_schema.fact_sales f
    GROUP BY f.customer_id
)

SELECT
    cs.customer_id,
    c.customer_name,
    c.customer_type,
    co.country_name,
    co.region,
    cs.total_transactions,
    cs.total_sales
FROM customer_sales cs
JOIN silver_schema.dim_customer c
    ON cs.customer_id = c.customer_id
JOIN silver_schema.dim_country co
    ON c.country_code = co.country_code
ORDER BY cs.total_sales DESC;