-- =========================================================
-- Incremental Load Procedure
-- Performs INSERT and UPDATE operations using MERGE
-- Uses a parameterized pipeline name
-- Records execution details in ETL Control Table
-- =========================================================

CREATE OR REPLACE PROCEDURE silver_layer.incremental_load(
    p_pipeline_name VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_time   TIMESTAMP;
    v_insert_count INTEGER;
    v_update_count INTEGER;
    v_merge_count  INTEGER;

BEGIN

    -- =====================================================
    -- 1. Customer Dimension
    -- =====================================================

    v_start_time := CURRENT_TIMESTAMP;

    -- Count new records
    SELECT COUNT(*)
    INTO v_insert_count
    FROM raw_layer.customers r
    LEFT JOIN silver_layer.dim_customers s
        ON s.customer_id = r.customer_id
    WHERE s.customer_id IS NULL;

    -- Count changed existing records
    SELECT COUNT(*)
    INTO v_update_count
    FROM raw_layer.customers r
    JOIN silver_layer.dim_customers s
        ON s.customer_id = r.customer_id
    WHERE
        s.customer_unique_id IS DISTINCT FROM r.customer_unique_id
        OR s.customer_zip_code_prefix IS DISTINCT FROM r.customer_zip_code_prefix
        OR s.customer_city IS DISTINCT FROM TRIM(r.customer_city)
        OR s.customer_state IS DISTINCT FROM UPPER(TRIM(r.customer_state));

    MERGE INTO silver_layer.dim_customers AS s
    USING (
        SELECT
            customer_id,
            customer_unique_id,
            customer_zip_code_prefix,
            TRIM(customer_city) AS customer_city,
            UPPER(TRIM(customer_state)) AS customer_state
        FROM raw_layer.customers
    ) AS r
    ON s.customer_id = r.customer_id

    WHEN MATCHED AND (
        s.customer_unique_id IS DISTINCT FROM r.customer_unique_id
        OR s.customer_zip_code_prefix IS DISTINCT FROM r.customer_zip_code_prefix
        OR s.customer_city IS DISTINCT FROM r.customer_city
        OR s.customer_state IS DISTINCT FROM r.customer_state
    )
    THEN UPDATE SET
        customer_unique_id = r.customer_unique_id,
        customer_zip_code_prefix = r.customer_zip_code_prefix,
        customer_city = r.customer_city,
        customer_state = r.customer_state

    WHEN NOT MATCHED THEN
        INSERT (
            customer_id,
            customer_unique_id,
            customer_zip_code_prefix,
            customer_city,
            customer_state
        )
        VALUES (
            r.customer_id,
            r.customer_unique_id,
            r.customer_zip_code_prefix,
            r.customer_city,
            r.customer_state
        );

    v_merge_count := v_insert_count + v_update_count;

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
        p_pipeline_name,
        'dim_customers',
        v_start_time,
        CURRENT_TIMESTAMP,
        'SUCCESS',
        v_merge_count,
        v_insert_count,
        v_update_count,
        NULL
    );


    -- =====================================================
    -- 2. Product Dimension
    -- =====================================================

    v_start_time := CURRENT_TIMESTAMP;

    SELECT COUNT(*)
    INTO v_insert_count
    FROM raw_layer.products r
    LEFT JOIN silver_layer.dim_products s
        ON s.product_id = r.product_id
    WHERE s.product_id IS NULL;

    SELECT COUNT(*)
    INTO v_update_count
    FROM raw_layer.products r
    JOIN silver_layer.dim_products s
        ON s.product_id = r.product_id
    WHERE
        s.product_category_name IS DISTINCT FROM TRIM(r.product_category_name)
        OR s.product_name_length IS DISTINCT FROM r.product_name_lenght
        OR s.product_description_length IS DISTINCT FROM r.product_description_lenght
        OR s.product_photos_qty IS DISTINCT FROM r.product_photos_qty
        OR s.product_weight_g IS DISTINCT FROM r.product_weight_g
        OR s.product_length_cm IS DISTINCT FROM r.product_length_cm
        OR s.product_height_cm IS DISTINCT FROM r.product_height_cm
        OR s.product_width_cm IS DISTINCT FROM r.product_width_cm;

    MERGE INTO silver_layer.dim_products AS s
    USING (
        SELECT
            product_id,
            TRIM(product_category_name) AS product_category_name,
            product_name_lenght AS product_name_length,
            product_description_lenght AS product_description_length,
            product_photos_qty,
            product_weight_g,
            product_length_cm,
            product_height_cm,
            product_width_cm
        FROM raw_layer.products
    ) AS r
    ON s.product_id = r.product_id

    WHEN MATCHED AND (
        s.product_category_name IS DISTINCT FROM r.product_category_name
        OR s.product_name_length IS DISTINCT FROM r.product_name_length
        OR s.product_description_length IS DISTINCT FROM r.product_description_length
        OR s.product_photos_qty IS DISTINCT FROM r.product_photos_qty
        OR s.product_weight_g IS DISTINCT FROM r.product_weight_g
        OR s.product_length_cm IS DISTINCT FROM r.product_length_cm
        OR s.product_height_cm IS DISTINCT FROM r.product_height_cm
        OR s.product_width_cm IS DISTINCT FROM r.product_width_cm
    )
    THEN UPDATE SET
        product_category_name = r.product_category_name,
        product_name_length = r.product_name_length,
        product_description_length = r.product_description_length,
        product_photos_qty = r.product_photos_qty,
        product_weight_g = r.product_weight_g,
        product_length_cm = r.product_length_cm,
        product_height_cm = r.product_height_cm,
        product_width_cm = r.product_width_cm

    WHEN NOT MATCHED THEN
        INSERT (
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
        VALUES (
            r.product_id,
            r.product_category_name,
            r.product_name_length,
            r.product_description_length,
            r.product_photos_qty,
            r.product_weight_g,
            r.product_length_cm,
            r.product_height_cm,
            r.product_width_cm
        );

    v_merge_count := v_insert_count + v_update_count;

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
        p_pipeline_name,
        'dim_products',
        v_start_time,
        CURRENT_TIMESTAMP,
        'SUCCESS',
        v_merge_count,
        v_insert_count,
        v_update_count,
        NULL
    );


    -- =====================================================
    -- 3. Orders Fact
    -- =====================================================

    v_start_time := CURRENT_TIMESTAMP;

    SELECT COUNT(*)
    INTO v_insert_count
    FROM raw_layer.orders r
    LEFT JOIN silver_layer.fact_orders s
        ON s.order_id = r.order_id
    WHERE s.order_id IS NULL;

    SELECT COUNT(*)
    INTO v_update_count
    FROM raw_layer.orders r
    JOIN silver_layer.fact_orders s
        ON s.order_id = r.order_id
    WHERE
        s.customer_id IS DISTINCT FROM r.customer_id
        OR s.order_status IS DISTINCT FROM TRIM(r.order_status)
        OR s.order_purchase_timestamp IS DISTINCT FROM r.order_purchase_timestamp
        OR s.order_approved_at IS DISTINCT FROM r.order_approved_at
        OR s.order_delivered_carrier_date IS DISTINCT FROM r.order_delivered_carrier_date
        OR s.order_delivered_customer_date IS DISTINCT FROM r.order_delivered_customer_date
        OR s.order_estimated_delivery_date IS DISTINCT FROM r.order_estimated_delivery_date;

    MERGE INTO silver_layer.fact_orders AS s
    USING (
        SELECT
            order_id,
            customer_id,
            TRIM(order_status) AS order_status,
            order_purchase_timestamp,
            order_approved_at,
            order_delivered_carrier_date,
            order_delivered_customer_date,
            order_estimated_delivery_date
        FROM raw_layer.orders
    ) AS r
    ON s.order_id = r.order_id

    WHEN MATCHED AND (
        s.customer_id IS DISTINCT FROM r.customer_id
        OR s.order_status IS DISTINCT FROM r.order_status
        OR s.order_purchase_timestamp IS DISTINCT FROM r.order_purchase_timestamp
        OR s.order_approved_at IS DISTINCT FROM r.order_approved_at
        OR s.order_delivered_carrier_date IS DISTINCT FROM r.order_delivered_carrier_date
        OR s.order_delivered_customer_date IS DISTINCT FROM r.order_delivered_customer_date
        OR s.order_estimated_delivery_date IS DISTINCT FROM r.order_estimated_delivery_date
    )
    THEN UPDATE SET
        customer_id = r.customer_id,
        order_status = r.order_status,
        order_purchase_timestamp = r.order_purchase_timestamp,
        order_approved_at = r.order_approved_at,
        order_delivered_carrier_date = r.order_delivered_carrier_date,
        order_delivered_customer_date = r.order_delivered_customer_date,
        order_estimated_delivery_date = r.order_estimated_delivery_date

    WHEN NOT MATCHED THEN
        INSERT (
            order_id,
            customer_id,
            order_status,
            order_purchase_timestamp,
            order_approved_at,
            order_delivered_carrier_date,
            order_delivered_customer_date,
            order_estimated_delivery_date
        )
        VALUES (
            r.order_id,
            r.customer_id,
            r.order_status,
            r.order_purchase_timestamp,
            r.order_approved_at,
            r.order_delivered_carrier_date,
            r.order_delivered_customer_date,
            r.order_estimated_delivery_date
        );

    v_merge_count := v_insert_count + v_update_count;

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
        p_pipeline_name,
        'fact_orders',
        v_start_time,
        CURRENT_TIMESTAMP,
        'SUCCESS',
        v_merge_count,
        v_insert_count,
        v_update_count,
        NULL
    );


    -- =====================================================
    -- 4. Order Items Fact
    -- =====================================================

    v_start_time := CURRENT_TIMESTAMP;

    SELECT COUNT(*)
    INTO v_insert_count
    FROM raw_layer.order_items r
    LEFT JOIN silver_layer.fact_order_items s
        ON s.order_id = r.order_id
       AND s.order_item_id = r.order_item_id
    WHERE s.order_id IS NULL;

    SELECT COUNT(*)
    INTO v_update_count
    FROM raw_layer.order_items r
    JOIN silver_layer.fact_order_items s
        ON s.order_id = r.order_id
       AND s.order_item_id = r.order_item_id
    WHERE
        s.product_id IS DISTINCT FROM r.product_id
        OR s.seller_id IS DISTINCT FROM r.seller_id
        OR s.shipping_limit_date IS DISTINCT FROM r.shipping_limit_date
        OR s.price IS DISTINCT FROM r.price
        OR s.freight_value IS DISTINCT FROM r.freight_value;

    MERGE INTO silver_layer.fact_order_items AS s
    USING (
        SELECT
            order_id,
            order_item_id,
            product_id,
            seller_id,
            shipping_limit_date,
            price,
            freight_value
        FROM raw_layer.order_items
    ) AS r
    ON s.order_id = r.order_id
       AND s.order_item_id = r.order_item_id

    WHEN MATCHED AND (
        s.product_id IS DISTINCT FROM r.product_id
        OR s.seller_id IS DISTINCT FROM r.seller_id
        OR s.shipping_limit_date IS DISTINCT FROM r.shipping_limit_date
        OR s.price IS DISTINCT FROM r.price
        OR s.freight_value IS DISTINCT FROM r.freight_value
    )
    THEN UPDATE SET
        product_id = r.product_id,
        seller_id = r.seller_id,
        shipping_limit_date = r.shipping_limit_date,
        price = r.price,
        freight_value = r.freight_value

    WHEN NOT MATCHED THEN
        INSERT (
            order_id,
            order_item_id,
            product_id,
            seller_id,
            shipping_limit_date,
            price,
            freight_value
        )
        VALUES (
            r.order_id,
            r.order_item_id,
            r.product_id,
            r.seller_id,
            r.shipping_limit_date,
            r.price,
            r.freight_value
        );

    v_merge_count := v_insert_count + v_update_count;

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
        p_pipeline_name,
        'fact_order_items',
        v_start_time,
        CURRENT_TIMESTAMP,
        'SUCCESS',
        v_merge_count,
        v_insert_count,
        v_update_count,
        NULL
    );


-- =========================================================
-- Exception Handling
-- =========================================================

EXCEPTION
    WHEN OTHERS THEN

        INSERT INTO silver_layer.etl_error_log (
            procedure_name,
            error_message,
            error_sqlstate
        )
        VALUES (
            'incremental_load',
            SQLERRM,
            SQLSTATE
        );

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
            p_pipeline_name,
            'incremental_load',
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