-- =========================================================
-- ETL Error Log
-- Stores errors generated during ETL execution
-- =========================================================

CREATE TABLE IF NOT EXISTS silver_layer.etl_error_log (
    error_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    procedure_name VARCHAR(100) NOT NULL,
    error_message TEXT NOT NULL,
    error_sqlstate VARCHAR(10),
    error_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- =========================================================
-- Full Load Procedure
-- Loads and transforms data from Raw Layer to Silver Layer
-- Records execution details for each target table
-- in the ETL Control Table
-- =========================================================

CREATE OR REPLACE PROCEDURE silver_layer.load_silver_layer()
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_record_count INTEGER;

BEGIN

    -- =====================================================
    -- 1. Load Customer Dimension
    -- =====================================================

    v_start_time := CURRENT_TIMESTAMP;

    INSERT INTO silver_layer.dim_customers (
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state
    )
    SELECT
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        TRIM(customer_city),
        UPPER(TRIM(customer_state))
    FROM raw_layer.customers;

    GET DIAGNOSTICS v_record_count = ROW_COUNT;

    INSERT INTO silver_layer.etl_control (
        pipeline_name,
        target_table,
        execution_start_dt,
        execution_end_dt,
        execution_status,
        merge_record_count,
        insert_record_count,
        update_record_count,
        error_message
    )
    VALUES (
        'FULL_LOAD',
        'dim_customers',
        v_start_time,
        CURRENT_TIMESTAMP,
        'SUCCESS',
        v_record_count,
        v_record_count,
        0,
        NULL
    );


    -- =====================================================
    -- 2. Load Product Dimension
    -- =====================================================

    v_start_time := CURRENT_TIMESTAMP;

    INSERT INTO silver_layer.dim_products (
        product_id,
        product_category_name,
        product_name_length,
        product_description_length,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm
    )
    SELECT
        product_id,
        TRIM(product_category_name),
        product_name_lenght,
        product_description_lenght,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm
    FROM raw_layer.products;

    GET DIAGNOSTICS v_record_count = ROW_COUNT;

    INSERT INTO silver_layer.etl_control (
        pipeline_name,
        target_table,
        execution_start_dt,
        execution_end_dt,
        execution_status,
        merge_record_count,
        insert_record_count,
        update_record_count,
        error_message
    )
    VALUES (
        'FULL_LOAD',
        'dim_products',
        v_start_time,
        CURRENT_TIMESTAMP,
        'SUCCESS',
        v_record_count,
        v_record_count,
        0,
        NULL
    );


    -- =====================================================
    -- 3. Load Orders Fact
    -- =====================================================

    v_start_time := CURRENT_TIMESTAMP;

    INSERT INTO silver_layer.fact_orders (
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date
    )
    SELECT
        order_id,
        customer_id,
        TRIM(order_status),
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date
    FROM raw_layer.orders;

    GET DIAGNOSTICS v_record_count = ROW_COUNT;

    INSERT INTO silver_layer.etl_control (
        pipeline_name,
        target_table,
        execution_start_dt,
        execution_end_dt,
        execution_status,
        merge_record_count,
        insert_record_count,
        update_record_count,
        error_message
    )
    VALUES (
        'FULL_LOAD',
        'fact_orders',
        v_start_time,
        CURRENT_TIMESTAMP,
        'SUCCESS',
        v_record_count,
        v_record_count,
        0,
        NULL
    );


    -- =====================================================
    -- 4. Load Order Items Fact
    -- =====================================================

    v_start_time := CURRENT_TIMESTAMP;

    INSERT INTO silver_layer.fact_order_items (
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date,
        price,
        freight_value
    )
    SELECT
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date,
        price,
        freight_value
    FROM raw_layer.order_items;

    GET DIAGNOSTICS v_record_count = ROW_COUNT;

    INSERT INTO silver_layer.etl_control (
        pipeline_name,
        target_table,
        execution_start_dt,
        execution_end_dt,
        execution_status,
        merge_record_count,
        insert_record_count,
        update_record_count,
        error_message
    )
    VALUES (
        'FULL_LOAD',
        'fact_order_items',
        v_start_time,
        CURRENT_TIMESTAMP,
        'SUCCESS',
        v_record_count,
        v_record_count,
        0,
        NULL
    );


-- =========================================================
-- Exception Handling
-- =========================================================

EXCEPTION
    WHEN OTHERS THEN

        -- Log technical error
        INSERT INTO silver_layer.etl_error_log (
            procedure_name,
            error_message,
            error_sqlstate
        )
        VALUES (
            'load_silver_layer',
            SQLERRM,
            SQLSTATE
        );

        -- Log failed execution in control table
        INSERT INTO silver_layer.etl_control (
            pipeline_name,
            target_table,
            execution_start_dt,
            execution_end_dt,
            execution_status,
            merge_record_count,
            insert_record_count,
            update_record_count,
            error_message
        )
        VALUES (
            'FULL_LOAD',
            'load_silver_layer',
            COALESCE(v_start_time, CURRENT_TIMESTAMP),
            CURRENT_TIMESTAMP,
            'FAILED',
            0,
            0,
            0,
            SQLERRM
        );

END;
$$;