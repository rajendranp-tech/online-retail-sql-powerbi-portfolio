
-- Project: Online Retail Data Analysis
-- Analysis: Customer transaction value
-- Database: PostgreSQL

SELECT
    customer_id,
    SUM(quantity * unit_price) AS total_transaction_value,
    COUNT(DISTINCT invoice_no) AS total_invoices,
    MAX(invoice_date) AS last_purchase_date
FROM online_retail
WHERE customer_id IS NOT NULL
  AND invoice_date IS NOT NULL
GROUP BY customer_id
ORDER BY total_transaction_value DESC;
