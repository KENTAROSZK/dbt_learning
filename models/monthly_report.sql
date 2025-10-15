-- models/monthly_report.sql
-- 月次で売上をまとめたレポート

SELECT
    DATE_TRUNC('month', order_date) as month,
    product_name,
    SUM(total_quantity) as monthly_quantity,
    SUM(total_sales) as monthly_sales,
    AVG(total_sales) as avg_daily_sales
FROM {{ ref('sales_summary') }}
GROUP BY DATE_TRUNC('month', order_date), product_name
ORDER BY month, product_name