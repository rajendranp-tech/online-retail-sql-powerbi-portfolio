--Final SQL Assessment
--Question 1 of 20 — Core SQL
--A retail manager wants to identify the 10 products with the highest total transaction value
--in the Online Retail dataset.
--Write a PostgreSQL query that returns:
--stock_code
--description
--total_transaction_value
--ANS
SELECT stock_code,
       description,
	   SUM(quantity * unit_price) AS total_transaction_value
FROM online_retail
GROUP BY stock_code,
         description
ORDER BY total_transaction_value DESC
LIMIT 10; 
--Question 2 of 20 — Core SQL (5 marks)
--The retail manager now wants to identify customers whose total net transaction value exceeds £10,000.
--Write a PostgreSQL query returning:
-- customer_id
-- total_transaction_value
--Requirements:
--1. Exclude rows where customer_id is NULL.
--2. Calculate each customer's total using quantity * unit_price.
--3. Return only customers whose total is greater than 10000.
--4. Sort the results from highest to lowest total transaction value.
SELECT customer_id,
       SUM(quantity * unit_price) AS total_net_transaction_value
FROM online_retail
WHERE customer_id IS NOT NULL
GROUP BY customer_id
HAVING SUM(quantity * unit_price) > 10000
ORDER BY total_net_transaction_value DESC;
--Question 3 of 20 — Monthly Business Analysis (5 marks)
--The retail manager now wants to understand how transaction value changes over time.
--Write a PostgreSQL query that returns:
--sales_month
-- monthly_transaction_value
--Requirements:
--1. Use DATE_TRUNC() to group transactions by month.
--2. Calculate monthly transaction value using SUM(quantity * unit_price).
--3. Exclude rows where invoice_date IS NULL.
--4. Sort from the earliest month to the latest month.
SELECT DATE_TRUNC('month', invoice_date) AS sales_month,
       SUM(quantity * unit_price) AS monthly_transaction_value
FROM online_retail
WHERE invoice_date IS NOT NULL
GROUP BY DATE_TRUNC('month', invoice_date)
ORDER BY sales_month ASC;
--Question 4 of 20 — Advanced SQL: Month-over-Month Change (5 marks)
--Now the manager wants to compare each month's transaction value with the previous month's value.
--Your query must return:
-- sales_month
-- monthly_transaction_value
-- previous_month_value
-- month_over_month_change
--Requirements:
--1. Calculate monthly transaction values.
--2. Use LAG() to retrieve the previous month's value.
--3. Calculate the change by subtracting the previous value from the current value.
--4. Sort chronologically from earliest to latest.
--5. Use a CTE or another suitable approach to calculate the monthly totals before applying LAG().
WITH monthly_stats AS(
     SELECT DATE_TRUNC('month', invoice_date) AS sales_month,
            SUM(quantity * unit_price) AS monthly_transaction_value
FROM online_retail
WHERE invoice_date IS NOT NULL
GROUP BY DATE_TRUNC('month', invoice_date)
),
previous_month_stats AS(
    SELECT sales_month,
	       monthly_transaction_value,
	       LAG(monthly_transaction_value)
	       OVER(ORDER BY sales_month) AS previous_month_value
	FROM monthly_stats
)
SELECT sales_month,
       monthly_transaction_value,
	   previous_month_value,
	   monthly_transaction_value - previous_month_value
	   AS month_over_month_change
FROM previous_month_stats
ORDER BY sales_month ASC; 
--Question 5 of 20 — Customer Ranking (5 marks)
--The retail manager wants to identify the top 3 customers by total net transaction value.
--Write a PostgreSQL query returning:
-- customer_id
-- total_transaction_value
-- customer_rank
--Requirements:
--1. Exclude rows where customer_id IS NULL.
--2. Calculate each customer's total using SUM(quantity * unit_price).
--3. Rank customers from highest to lowest total using DENSE_RANK().
--4. Return only the top 3 ranks.
--5. Display the highest-value customer first.
WITH customer_stats AS(
SELECT customer_id,
       SUM(quantity * unit_price) AS total_transaction_value
FROM online_retail
WHERE customer_id IS NOT NULL
GROUP BY customer_id
),
ranking_stats AS(
SELECT customer_id,
       total_transaction_value,
	   DENSE_RANK()OVER(ORDER BY total_transaction_value
						DESC) AS customer_rank
FROM customer_stats
)
SELECT customer_id,
       total_transaction_value,
	   customer_rank
FROM ranking_stats
ORDER BY total_transaction_value DESC
LIMIT 3;
--Question 6 of 20 — Customers Above Their Country's Average (5 marks)
--Write a PostgreSQL query that returns:
-- country
-- customer_id
-- total_transaction_value
-- country_average_transaction_value
--Requirements:
--1. Exclude rows where customer_id IS NULL.
--2. Calculate each customer's total transaction value within each country 
--using SUM(quantity * unit_price).
--3. Calculate the average customer total for each country.
--4. Return only customers whose total is greater than their country's average.
--5. Sort by country ascending, then total_transaction_value descending.
WITH customer_stats AS(
SELECT country,
       customer_id,
	   SUM(quantity * unit_price) AS total_transaction_value
FROM online_retail
WHERE customer_id IS NOT NULL
GROUP BY country,
         customer_id
),
country_stats AS(
SELECT country,
       customer_id,
	   total_transaction_value,
	   ROUND(AVG(total_transaction_value)
	   OVER(PARTITION BY country
	   ),2) AS country_average_transaction_value
FROM customer_stats
)
SELECT country,
       customer_id,
	   total_transaction_value,
	   country_average_transaction_value
FROM country_stats
WHERE total_transaction_value > country_average_transaction_value
ORDER BY country ASC,
total_transaction_value DESC;
--Question 7 of 20 — Customer Contribution to Country Value
--The retail manager now wants to know what percentage of each 
--country's total transaction value comes from each customer.
--Return:
-- country
-- customer_id
-- customer_transaction_value
-- country_transaction_value
-- customer_percentage_of_country_value
--Requirements:
--1. Exclude rows where customer_id IS NULL.
--2. Calculate each customer's total transaction value within their country.
--3. Calculate the total transaction value for each country.
--4. Calculate each customer's percentage of their country's total value, rounded to two decimal places.
--5. Sort by country, then customer percentage descending.
WITH customer_stats AS(
SELECT country,
       customer_id,
	   SUM(quantity * unit_price) AS total_transaction_value
FROM online_retail
WHERE customer_id IS NOT NULL
GROUP BY country,
         customer_id
),
country_stats AS(
SELECT country,
       customer_id,
	   total_transaction_value,
	   SUM(total_transaction_value)
	   OVER(PARTITION BY country
	   ) AS country_transaction_value
FROM customer_stats
)
SELECT country,
       customer_id,
	   total_transaction_value,
	   country_transaction_value,
	   ROUND((total_transaction_value*100.0)
	   /NULLIF(country_transaction_value,0),2)
			  AS customer_percentage_of_country_value
FROM country_stats
ORDER BY country ASC,
customer_percentage_of_country_value DESC;
--Question 8 of 20 — Customer Purchase Frequency
--A retail manager wants to identify customers who made purchases across at least 10 distinct invoices.
--Write a PostgreSQL query returning:
-- customer_id
-- distinct_invoice_count
-- total_transaction_value
--Requirements:
--1. Exclude rows where customer_id IS NULL.
--2. Count distinct invoices using COUNT(DISTINCT invoice_no).
--3. Calculate each customer's total transaction value using SUM(quantity * unit_price).
--4. Include only customers with at least 10 distinct invoices.
--5. Sort by distinct_invoice_count descending, then total_transaction_value descending.
SELECT customer_id,
       COUNT(DISTINCT invoice_no) AS distinct_invoice_count,
	   SUM(quantity * unit_price) AS total_transaction_value
FROM online_retail
WHERE customer_id IS NOT NULL
GROUP BY customer_id
HAVING COUNT(DISTINCT invoice_no) >=10
ORDER BY distinct_invoice_count DESC,
total_transaction_value DESC;
--Question 9 of 20 — Customer Average Invoice Value
--A retail manager wants to identify customers with an average transaction value 
--per invoice greater than £500.
--Return:
-- customer_id
-- distinct_invoice_count
-- total_transaction_value
-- average_invoice_value
--Requirements:
--1. Exclude rows where customer_id IS NULL.
--2. Calculate each customer's total value per invoice first.
--3. Calculate the average invoice value for each customer.
--4. Include only customers whose average invoice value exceeds 500.
--5. Sort by average_invoice_value descending.
WITH invoice_stats AS (
    SELECT customer_id,
           invoice_no,
           SUM(quantity * unit_price) AS invoice_value
    FROM online_retail
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id, invoice_no
),
average_stats AS (
    SELECT customer_id,
           COUNT(DISTINCT invoice_no) AS distinct_invoice_count,
           SUM(invoice_value) AS total_transaction_value,
           ROUND(AVG(invoice_value), 2) AS average_invoice_value
    FROM invoice_stats
	GROUP BY customer_id
)
SELECT customer_id,
       distinct_invoice_count,
	   total_transaction_value,
	   average_invoice_value
FROM average_stats
WHERE average_invoice_value > 500
ORDER BY average_invoice_value DESC;
--Question 10 of 20 — Monthly Customer Retention
--A retail manager wants to find how many customers purchased in consecutive available months.
--Return:
-- sales_month
-- active_customer_count
-- previous_month_customer_count
-- customer_count_change
--Requirements:
--1. Exclude records with missing customer_id or invoice_date.
--2. Count distinct customers per month.
--3. Use LAG() to retrieve the customer count from the previous available month.
--4. Calculate the change by subtracting the previous count from the current count.
--5. Sort chronologically.
WITH monthly_customer_stats AS(
SELECT DATE_TRUNC('month',invoice_date) AS sales_month,
	   COUNT(DISTINCT customer_id) AS active_customer_count
FROM online_retail
WHERE customer_id IS NOT NULL
AND
invoice_date IS NOT NULL
GROUP BY DATE_TRUNC('month',invoice_date)
),
previous_month_customer_stats AS(
SELECT sales_month,
       active_customer_count,
	   LAG(active_customer_count)
	   OVER(ORDER BY sales_month
			) AS previous_month_customer_count
FROM monthly_customer_stats
)
SELECT sales_month,
       active_customer_count,
	   previous_month_customer_count,
	   active_customer_count - previous_month_customer_count
	   AS customer_count_change
FROM previous_month_customer_stats
ORDER BY sales_month ASC;
--Question 11 of 20 — Monthly Customer Retention Rate
--Now let's build on the previous question.
--A retail manager wants to know what percentage of customers active in one month 
--also purchased in the next available month.
--Return:
-- sales_month
-- previous_month_customer_count
-- retained_customer_count
-- customer_retention_rate

WITH customer_months AS (
    SELECT DISTINCT
           customer_id,
           DATE_TRUNC('month', invoice_date) AS sales_month
    FROM online_retail
    WHERE customer_id IS NOT NULL
      AND invoice_date IS NOT NULL
),
monthly_sequence AS (
    SELECT
           sales_month,
           LAG(sales_month) OVER (
               ORDER BY sales_month
           ) AS previous_month
    FROM (
        SELECT DISTINCT sales_month
        FROM customer_months
    ) AS months
),
retained_customers AS (
    SELECT
           m.sales_month,
           m.previous_month,
           COUNT(DISTINCT c.customer_id) AS retained_customer_count
    FROM monthly_sequence m
    LEFT JOIN customer_months c
      ON c.sales_month = m.sales_month
    LEFT JOIN customer_months p
      ON p.customer_id = c.customer_id
     AND p.sales_month = m.previous_month
    GROUP BY
           m.sales_month,
           m.previous_month
),
previous_month_counts AS (
    SELECT
           sales_month,
           COUNT(DISTINCT customer_id) AS active_customer_count
    FROM customer_months
    GROUP BY sales_month
)
SELECT
       r.sales_month,
       COALESCE(p.active_customer_count, 0)
           AS previous_month_customer_count,
       r.retained_customer_count,
       ROUND(
           r.retained_customer_count * 100.0
           / NULLIF(p.active_customer_count, 0),
           2
       ) AS customer_retention_rate
FROM retained_customers r
LEFT JOIN previous_month_counts p
  ON p.sales_month = r.previous_month
ORDER BY r.sales_month ASC;
--Question 12 of 20 — Product Sales Concentration
--A retail manager wants to understand how much each product contributes to 
--the overall net transaction value.
--Return:
-- stock_code
-- description
-- product_transaction_value
-- overall_transaction_value
-- percentage_of_overall_value
--Requirements:
--1. Calculate each product's transaction value using SUM(quantity * unit_price).
--2. Calculate the overall transaction value across all products.
--3. Calculate each product's percentage contribution, rounded to two decimal places.
--4. Protect against division by zero with NULLIF() if needed.
--5. Return the top 20 products by percentage_of_overall_value, descending.
WITH product_sales_stats AS (
SELECT stock_code,
       description,
	   SUM(quantity * unit_price) AS product_transaction_value
FROM online_retail
GROUP BY stock_code,
         description
),
overal_product_stats AS (
SELECT stock_code,
       description,
	   product_transaction_value,
	   SUM(product_transaction_value)
	   OVER()AS overall_transaction_value
FROM product_sales_stats
)
SELECT stock_code,
       description,
	   product_transaction_value,
	   overall_transaction_value,
	   ROUND((product_transaction_value * 100.0)
	   /NULLIF(overall_transaction_value,0),2
	   ) AS percentage_of_overall_value
FROM overal_product_stats
ORDER BY percentage_of_overall_value DESC
LIMIT 20 ;
--Question 13 of 20 — Running Monthly Transaction Value
--A retail manager wants to track how the cumulative net transaction value grows over time.
--Return:
-- sales_month
-- monthly_transaction_value
-- running_transaction_value
--Requirements:
--1. Exclude rows with missing invoice_date.
--2. Calculate monthly transaction value using SUM(quantity * unit_price).
--3. Calculate the running total from the earliest month to the current month.
--4. Sort chronologically.
WITH monthly_stats AS (
SELECT DATE_TRUNC('month',invoice_date) AS sales_month,
       SUM(quantity * unit_price) AS monthly_transaction_value
FROM online_retail
WHERE invoice_date IS NOT NULL
GROUP BY DATE_TRUNC('month',invoice_date)
),
running_total_stats AS (
SELECT sales_month,
       monthly_transaction_value,
	   SUM(monthly_transaction_value) OVER (
       ORDER BY sales_month
       ) AS running_transaction_value
FROM monthly_stats
)
SELECT sales_month,
       monthly_transaction_value,
	   running_transaction_value
FROM running_total_stats
ORDER BY sales_month ASC;
--Question 14 of 20 — Month-over-Month Percentage Change
--A retail manager wants to identify how much the monthly net transaction value 
--changed as a percentage compared with the previous available month.
--Return:
-- sales_month
-- monthly_transaction_value
-- previous_month_value
-- month_over_month_percentage_change
WITH monthly_stats AS (
SELECT DATE_TRUNC('month',invoice_date) AS sales_month,
       SUM(quantity * unit_price) AS monthly_transaction_value
FROM online_retail
WHERE invoice_date IS NOT NULL
GROUP BY DATE_TRUNC('month',invoice_date)
),
previous_month_stats AS (
SELECT sales_month,
       monthly_transaction_value,
	   LAG(monthly_transaction_value) 
	   OVER(ORDER BY sales_month)
	   AS previous_month_value
FROM monthly_stats
)
SELECT sales_month,
       monthly_transaction_value,
	   previous_month_value,
	   ROUND((monthly_transaction_value - previous_month_value)
	   * 100
	   /NULLIF(ABS(previous_month_value),0),2)
	   AS month_over_month_percentage_change
FROM previous_month_stats
ORDER BY sales_month ASC;
--Question 15 of 20 — Top Products by Country
--A retail manager wants to identify the top three products by net transaction value within each country.
--Return:
-- country
-- stock_code
-- description
-- product_transaction_value
-- product_rank
--Requirements:
--1. Calculate each product's net transaction value within each country.
--2. Use DENSE_RANK() to rank products by transaction value, highest first, within each country.
--3. Return only products with rank 3 or better.
--4. Sort by country, then rank ascending.
WITH country_stats AS (
SELECT country,
       stock_code,
	   description,
	   SUM(quantity * unit_price) AS product_transaction_value
FROM online_retail
GROUP BY country,
         stock_code,
		 description
),
ranking_stats AS (
SELECT country,
       stock_code,
	   description,
	   product_transaction_value,
	   DENSE_RANK() OVER(
       PARTITION BY country
	   ORDER BY product_transaction_value DESC
	   ) AS product_rank
FROM country_stats
)
SELECT country,
       stock_code,
	   description,
	   product_transaction_value,
	   product_rank
FROM ranking_stats
WHERE product_rank <=3
ORDER BY country ASC,
product_rank ASC;
--Question 16 of 20 — Customer Purchase Recency
--A retail manager wants to identify each customer's most recent purchase date and the number of days 
--since that purchase.
--Return:
-- customer_id
-- last_purchase_date
-- days_since_last_purchase
--Requirements:
--1. Exclude missing customer IDs and invoice dates.
--2. Find each customer's most recent invoice_date.
--3. Calculate the number of days between that date and the current date.
--4. Sort by last_purchase_date descending, most recent first.
SELECT customer_id,
       MAX(invoice_date) AS last_purchase_date,
	   CURRENT_DATE - MAX(invoice_date)::date AS days_since_last_purchase
FROM online_retail
WHERE customer_id IS NOT NULL
AND
invoice_date IS NOT NULL
GROUP BY customer_id
ORDER BY last_purchase_date DESC;
--Question 17 of 20 — Customer Recency Segmentation
--A retail manager wants to segment customers according to how recently they purchased.
--Return:
-- customer_id
-- last_purchase_date
-- days_since_last_purchase
-- recency_segment
--Requirements:
--1. Exclude missing customer IDs and invoice dates.
--2. Find each customer's latest purchase date.
--3. Calculate the number of days since that date.
--4. Use CASE WHEN to assign the correct segment.
--5. Sort by days_since_last_purchase ascending.
WITH purchased_stats AS (
SELECT customer_id,
       MAX(invoice_date) AS last_purchase_date,
	   CURRENT_DATE - MAX(invoice_date)::date AS days_since_last_purchase
FROM online_retail
WHERE customer_id IS NOT NULL
AND
invoice_date IS NOT NULL
GROUP BY customer_id
)
SELECT customer_id,
       last_purchase_date,
	   days_since_last_purchase,
	   CASE 
	       WHEN days_since_last_purchase <= 30 
		   THEN 'Recent'
		   WHEN days_since_last_purchase <= 90
		   THEN 'At Risk'
		   ELSE 'Dormant'
		   END AS recency_segment
FROM purchased_stats
ORDER BY days_since_last_purchase ASC;
--Question 18 of 20 — Customer RFM Segmentation
--Difficulty: Advanced · 5 marks
--A retail manager wants to identify valuable customers using three metrics:
-- Recency: How many days since their latest purchase?
-- Frequency: How many distinct invoices have they placed?
-- Monetary: What is their total net transaction value?
--Your task
--Write a PostgreSQL query that returns:
--customer_id, last_purchase_date, days_since_last_purchase, total_invoices, total_transaction_value, 
--and customer_segment.
--Use these segmentation rules:
--Rule	Segment
--Total transaction value ≥ £10,000 and at least 10 invoices	VIP
--Total transaction value ≥ £2,000 and at least 5 invoices	Loyaltotal_transaction_value
--Everyone else	Standard
--Requirements:
--1. Exclude missing customer_id values.
--2. Calculate the latest invoice date for each customer.
--3. Count distinct invoices and calculate total transaction value.
--4. Use CASE WHEN to assign the segment.
--5. Sort by total transaction value, highest first.
WITH customer_stats AS (                                    
SELECT customer_id,
       MAX(invoice_date) AS last_purchase_date,
	   CURRENT_DATE - MAX(invoice_date)::date AS days_since_last_purchase,
	   COUNT(DISTINCT invoice_no) AS total_invoices,
	   SUM(quantity * unit_price) AS total_transaction_value
FROM online_retail
WHERE customer_id IS NOT NULL
AND invoice_date IS NOT NULL 
GROUP BY customer_id
)
SELECT customer_id,
       last_purchase_date,
	   days_since_last_purchase,
	   total_invoices,
	   total_transaction_value,
	   CASE 
	       WHEN total_transaction_value >= 10000
		   AND total_invoices >= 10 
		   THEN 'VIP'
		   WHEN total_transaction_value >= 2000
		   AND total_invoices >= 5 
		   THEN 'Loyal'
		   ELSE 'Standard'
		   END AS customer_segment
FROM customer_stats
ORDER BY total_transaction_value DESC;
--Question 19 of 20 — Customer Purchase Inactivity
--A retail manager wants to identify customers who may have stopped purchasing.
--Write a PostgreSQL query that returns:
-- customer_id
-- last_purchase_date
-- days_since_last_purchase
-- total_transaction_value
-- customer_status
--Use these rules:
--Condition	Customer status
--More than 180 days since last purchase	Inactive
--91–180 days since last purchase	Needs Attention
--0–90 days since last purchase	Active
--Requirements
--1. Exclude rows with missing customer_id or invoice_date.
--2. Calculate each customer's latest invoice date.
--3. Calculate days since their latest purchase.
--4. Calculate their total net transaction value.
--5. Use CASE WHEN to assign the status.
--6. Sort by days_since_last_purchase in descending order, so the longest-inactive 
--customers appear first.
WITH customer_stats AS (                                    
SELECT customer_id,
       MAX(invoice_date) AS last_purchase_date,
	   CURRENT_DATE - MAX(invoice_date)::date AS days_since_last_purchase,
	   COUNT(DISTINCT invoice_no) AS total_invoices,
	   SUM(quantity * unit_price) AS total_transaction_value
FROM online_retail
WHERE customer_id IS NOT NULL
AND invoice_date IS NOT NULL 
GROUP BY customer_id
)
SELECT customer_id,
       last_purchase_date,
	   days_since_last_purchase,
	   total_invoices,
	   total_transaction_value,
	   CASE 
	       WHEN days_since_last_purchase <= 90
		   THEN 'Active'
		   WHEN days_since_last_purchase <= 180
		   THEN 'Needs Attention'
		   ELSE 'Inactive'
		   END AS customer_status
FROM customer_stats
ORDER BY days_since_last_purchase DESC;
--Question 20 of 20 — Final SQL Assessment Challenge 🏆
--Future Data Analyst, this is your last assessment question! Build a customer-level 
--business report that combines several SQL concepts.
--Business scenario
--The retail manager wants to identify customers who:
-- Have placed at least 5 distinct invoices.
-- Have a total net transaction value of at least £2,000.
--For each qualifying customer, return:
--1. customer_id
--2. total_invoices
--3. total_transaction_value
--4. average_invoice_value
--5. last_purchase_date
--6. days_since_last_purchase
--7. customer_segment
--Use these segmentation rules:
--Condition	Segment
--Total value ≥ £10,000 and at least 10 invoices	VIP
--Total value ≥ £5,000	High Value
--Everyone else who qualifies	Regular
--Requirements
-- Exclude missing customer IDs and invoice dates.
-- Count distinct invoices.
-- Calculate total transaction value and average value per invoice.
-- Calculate the latest purchase date and days since purchase.
-- Use HAVING to filter customers meeting both qualification thresholds.
-- Use CASE WHEN to assign the segment.
-- Sort by total transaction value, highest first.
WITH invoice_stats AS (
    SELECT
        customer_id,
        invoice_no,
        SUM(quantity * unit_price) AS invoice_value,
        MAX(invoice_date) AS invoice_date
    FROM online_retail
    WHERE customer_id IS NOT NULL
      AND invoice_date IS NOT NULL
    GROUP BY customer_id, invoice_no
),
customer_stats AS (
    SELECT
        customer_id,
        COUNT(*) AS total_invoices,
        SUM(invoice_value) AS total_transaction_value,
        AVG(invoice_value) AS average_invoice_value,
        MAX(invoice_date) AS last_purchase_date,
        CURRENT_DATE - MAX(invoice_date)::date
            AS days_since_last_purchase
    FROM invoice_stats
    GROUP BY customer_id
    HAVING COUNT(*) >= 5
       AND SUM(invoice_value) >= 2000
)
SELECT
    customer_id,
    total_invoices,
    total_transaction_value,
    ROUND(average_invoice_value, 2) AS average_invoice_value,
    last_purchase_date,
    days_since_last_purchase,
    CASE
        WHEN total_transaction_value >= 10000
         AND total_invoices >= 10
            THEN 'VIP'
        WHEN total_transaction_value >= 5000
            THEN 'High Value'
        ELSE 'Regular'
    END AS customer_segment
FROM customer_stats
ORDER BY total_transaction_value DESC;
	   
