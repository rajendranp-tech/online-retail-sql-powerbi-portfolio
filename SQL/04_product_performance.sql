-- Project: Online Retail Data Analysis
-- Analysis: Product performance by net transaction value
-- Database: PostgreSQL

SELECT
    stock_code,
    description,
    SUM(quantity) AS net_quantity,
    SUM(quantity * unit_price) AS net_transaction_value
FROM online_retail
WHERE invoice_date IS NOT NULL
GROUP BY stock_code, description
ORDER BY net_transaction_value DESC
LIMIT 20;
