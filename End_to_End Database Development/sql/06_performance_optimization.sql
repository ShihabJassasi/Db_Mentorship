-- =========================================================
-- Performance Optimization
-- Index for order purchase timestamp
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_fact_orders_purchase_timestamp
ON silver_layer.fact_orders (order_purchase_timestamp);