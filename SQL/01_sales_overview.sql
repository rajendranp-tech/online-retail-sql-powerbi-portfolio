
-- Project: Online Retail Data Analysis
-- Analysis: Overall transaction value
-- Database: PostgreSQL
-- Note: Includes negative quantities and cancellation-related records.

SELECT
    SUM(quantity * unit_price) AS total_transaction_value
FROM online_retail
WHERE invoice_date IS NOT NULL;
