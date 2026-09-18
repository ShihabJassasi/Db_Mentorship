-- =========================================================
-- Silver Layer Schema
-- =========================================================

CREATE SCHEMA IF NOT EXISTS silver_layer;


-- =========================================================
-- Customer Dimension
-- Stores cleaned customer information
-- =========================================================

CREATE TABLE IF NOT EXISTS silver_layer.dim_customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50) NOT NULL,
    customer_zip_code_prefix INTEGER,
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);


-- =========================================================
-- Product Dimension
-- Stores cleaned product information
-- =========================================================

CREATE TABLE IF NOT EXISTS silver_layer.dim_products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER
);


-- =========================================================
-- Orders Fact Table
-- Stores order transactions and links orders to customers
-- =========================================================

CREATE TABLE IF NOT EXISTS silver_layer.fact_orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    order_status VARCHAR(30) NOT NULL,
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,

    -- Link each order to a customer
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES silver_layer.dim_customers(customer_id)
);


-- =========================================================
-- Order Items Fact Table
-- Stores individual items within each order
-- =========================================================

CREATE TABLE IF NOT EXISTS silver_layer.fact_order_items (
    order_id VARCHAR(50) NOT NULL,
    order_item_id INTEGER NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    seller_id VARCHAR(50),
    shipping_limit_date TIMESTAMP,
    price NUMERIC(12,2) NOT NULL,
    freight_value NUMERIC(12,2),

    -- Each item is unique within an order
    CONSTRAINT pk_order_items
        PRIMARY KEY (order_id, order_item_id),

    -- Link each item to its order
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES silver_layer.fact_orders(order_id),

    -- Link each item to its product
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES silver_layer.dim_products(product_id)
);