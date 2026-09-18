-- =========================================================
-- ETL Control Table
-- Purpose:
-- Track every ETL execution for each target table
-- =========================================================

CREATE TABLE IF NOT EXISTS silver_layer.etl_control (
    run_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    pipeline_name VARCHAR(100) NOT NULL,

    target_table VARCHAR(100) NOT NULL,

    execution_start_dt TIMESTAMP NOT NULL,

    execution_end_dt TIMESTAMP,

    execution_status VARCHAR(20) NOT NULL,

    merge_record_count INTEGER DEFAULT 0
);