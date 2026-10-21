-- Project: Online Retail Data Analysis
-- Analysis: Country-level performance
-- Database: PostgreSQL

SELECT
    country,
    COUNT(DISTINCT invoice_no) AS total_invoices,
    COUNT(DISTINCT customer_id) AS total_customers,
    SUM(quantity * unit_price) AS net_transaction_value
FROM online_retail
WHERE invoice_date IS NOT NULL
GROUP BY country
ORDER BY net_transaction_value DESC;
