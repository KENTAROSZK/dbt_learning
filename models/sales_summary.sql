-- models/sales_summary.sql
-- 日次で商品ごとの売上を集計

SELECT
    order_date,
    product_name,
    SUM(quantity) as total_quantity,
    SUM(quantity * price) as total_sales,
    COUNT(order_id) as order_count
FROM {{ ref('raw_orders') }}
GROUP BY order_date, product_name
ORDER BY order_date, product_name