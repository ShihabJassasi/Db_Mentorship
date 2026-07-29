CREATE SCHEMA raw_schema;

SELECT schema_name
FROM information_schema.schemata
WHERE schema_name = 'raw_schema';

---#creat country table.....
CREATE TABLE raw_schema.country (
    country_code VARCHAR(2) PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL,
    region VARCHAR(50) NOT NULL
);

---#creat customers table.....
CREATE TABLE raw_schema.customer (
    customer_id VARCHAR(10) PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    country_code VARCHAR(2) NOT NULL,
    customer_type VARCHAR(20) NOT NULL,

    CONSTRAINT fk_customer_country
        FOREIGN KEY (country_code)
        REFERENCES raw_schema.country(country_code)
);

---#creat product table.....
CREATE TABLE raw_schema.product (
    product_id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    standard_price DECIMAL(10,2) NOT NULL
);


---#creat sales_transactions table.....
CREATE TABLE raw_schema.sales_transactions (
    transaction_id INT PRIMARY KEY,
    transaction_date DATE NOT NULL,
    customer_id VARCHAR(10) NOT NULL,
    product_id VARCHAR(10) NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    payment_mode VARCHAR(20) NOT NULL,

    CONSTRAINT fk_sales_customer
        FOREIGN KEY (customer_id)
        REFERENCES raw_schema.customer(customer_id),

    CONSTRAINT fk_sales_product
        FOREIGN KEY (product_id)
        REFERENCES raw_schema.product(product_id)
);
--------------------------------------------------------------------------------------------------------
---#assignment_2
--creat fact table and dimensions
CREATE SCHEMA IF NOT EXISTS silver_schema;

---#1 fact tabl
---------------
--creat fact_sales

CREATE TABLE silver_schema.fact_sales (
    transaction_id INT,
    transaction_date DATE,
    customer_id VARCHAR(10),
    product_id VARCHAR(10),
    quantity INT,
    unit_price DECIMAL(10,2),
    total_amount DECIMAL(10,2),
    payment_mode VARCHAR(20)
);

---#2 dimension table
---------------------
-- creat dimension country table 

CREATE TABLE silver_schema.dim_country (
    country_code VARCHAR(2),
    country_name VARCHAR(100),
    region VARCHAR(50)
);

-- creat dimension customer table 

CREATE TABLE silver_schema.dim_customer (
    customer_id VARCHAR(10),
    customer_name VARCHAR(100),
    country_code VARCHAR(2),
    customer_type VARCHAR(20)
);

-- creat dimension product table 

CREATE TABLE silver_schema.dim_product (
    product_id VARCHAR(10),
    product_name VARCHAR(100),
    category VARCHAR(50),
    standard_price DECIMAL(10,2)
);

----#3 table relationships
--------------------------
-- Primary Keys
ALTER TABLE silver_schema.dim_country
ADD CONSTRAINT pk_dim_country
PRIMARY KEY (country_code);

ALTER TABLE silver_schema.dim_customer
ADD CONSTRAINT pk_dim_customer
PRIMARY KEY (customer_id);

ALTER TABLE silver_schema.dim_product
ADD CONSTRAINT pk_dim_product
PRIMARY KEY (product_id);

ALTER TABLE silver_schema.fact_sales
ADD CONSTRAINT pk_fact_sales
PRIMARY KEY (transaction_id);


-- Foreign Keys
ALTER TABLE silver_schema.dim_customer
ADD CONSTRAINT fk_dim_customer_country
FOREIGN KEY (country_code)
REFERENCES silver_schema.dim_country(country_code);

ALTER TABLE silver_schema.fact_sales
ADD CONSTRAINT fk_fact_customer
FOREIGN KEY (customer_id)
REFERENCES silver_schema.dim_customer(customer_id);

ALTER TABLE silver_schema.fact_sales
ADD CONSTRAINT fk_fact_product
FOREIGN KEY (product_id)
REFERENCES silver_schema.dim_product(product_id);

--#4 Customer validation
------------------------
ALTER TABLE silver_schema.dim_customer
ADD CONSTRAINT chk_customer_type
CHECK (customer_type IN ('RETAIL', 'CORPORATE'));


-- Product validation
ALTER TABLE silver_schema.dim_product
ADD CONSTRAINT chk_standard_price
CHECK (standard_price >= 0);


-- Sales validation
ALTER TABLE silver_schema.fact_sales
ADD CONSTRAINT chk_quantity
CHECK (quantity > 0);

ALTER TABLE silver_schema.fact_sales
ADD CONSTRAINT chk_unit_price
CHECK (unit_price >= 0);

ALTER TABLE silver_schema.fact_sales
ADD CONSTRAINT chk_total_amount
CHECK (total_amount >= 0);

ALTER TABLE silver_schema.fact_sales
ADD CONSTRAINT chk_total_calculation
CHECK (total_amount = quantity * unit_price);

ALTER TABLE silver_schema.fact_sales
ADD CONSTRAINT chk_payment_mode
CHECK (payment_mode IN ('CASH', 'CARD', 'ONLINE'));


---#5 insert the data from raw to silver 
----------------------------------------
---insert country data
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

SELECT *
FROM silver_schema.dim_country;

---insert customer data
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

SELECT *
FROM silver_schema.dim_customer;

---insert products data
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

SELECT *
FROM silver_schema.dim_product ;

---insert data for the sales fact table
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

SELECT DISTINCT payment_mode
FROM raw_schema.sales_transactions
ORDER BY payment_mode;

select*
from silver_schema.fact_sales

