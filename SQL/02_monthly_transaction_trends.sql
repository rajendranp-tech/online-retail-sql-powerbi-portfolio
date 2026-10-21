
-- Project: Online Retail Data Analysis
-- Analysis: Monthly net transaction trends
-- Database: PostgreSQL

SELECT
    DATE_TRUNC('month', invoice_date) AS sales_month,
    SUM(quantity * unit_price) AS monthly_transaction_value
FROM online_retail
WHERE invoice_date IS NOT NULL
GROUP BY DATE_TRUNC('month', invoice_date)
ORDER BY sales_month ASC;
