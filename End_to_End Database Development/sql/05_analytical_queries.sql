-- =========================================================
-- Analytical Queries
-- Olist E-Commerce Dataset
-- =========================================================


-- =========================================================
-- 1. Monthly Sales Analysis
-- Calculates total orders, items, sales, and average price
-- for each month.
-- =========================================================

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS sales_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(oi.order_item_id) AS total_items,
    ROUND(SUM(oi.price), 2) AS total_sales,
    ROUND(AVG(oi.price), 2) AS average_item_price
FROM silver_layer.fact_orders o
JOIN silver_layer.fact_order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY
    sales_month;



-- =========================================================
-- 2. Product Sales Ranking using Window Functions
-- Demonstrates ROW_NUMBER, RANK, and DENSE_RANK
-- =========================================================

SELECT
    product_id,
    total_sales,

    ROW_NUMBER() OVER (
        ORDER BY total_sales DESC
    ) AS row_number_rank,

    RANK() OVER (
        ORDER BY total_sales DESC
    ) AS sales_rank,

    DENSE_RANK() OVER (
        ORDER BY total_sales DESC
    ) AS dense_rank

FROM (
    SELECT
        product_id,
        ROUND(SUM(price), 2) AS total_sales
    FROM silver_layer.fact_order_items
    GROUP BY product_id
) product_sales

ORDER BY total_sales DESC
LIMIT 20;



-- =========================================================
-- 3. Monthly Sales Trend using LAG and LEAD
-- Compares each month's sales with previous and next month
-- =========================================================

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp) AS sales_month,
        ROUND(SUM(oi.price), 2) AS total_sales
    FROM silver_layer.fact_orders o
    JOIN silver_layer.fact_order_items oi
        ON o.order_id = oi.order_id
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
)

SELECT
    sales_month,
    total_sales,

    LAG(total_sales) OVER (
        ORDER BY sales_month
    ) AS previous_month_sales,

    LEAD(total_sales) OVER (
        ORDER BY sales_month
    ) AS next_month_sales

FROM monthly_sales
ORDER BY sales_month;

-- =========================================================
-- 4. Products with Above-Average Sales using Subquery
-- Identifies products whose total sales are higher
-- than the average total sales across all products
-- =========================================================

SELECT
    product_id,
    total_sales
FROM (
    SELECT
        product_id,
        ROUND(SUM(price), 2) AS total_sales
    FROM silver_layer.fact_order_items
    GROUP BY product_id
) AS product_sales

WHERE total_sales > (
    SELECT AVG(product_total)
    FROM (
        SELECT
            SUM(price) AS product_total
        FROM silver_layer.fact_order_items
        GROUP BY product_id
    ) AS average_sales
)

ORDER BY total_sales DESC;