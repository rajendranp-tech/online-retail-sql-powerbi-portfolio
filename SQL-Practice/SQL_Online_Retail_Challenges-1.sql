--insert a new dataset Online Retail
CREATE TABLE online_retail (
    invoice_no VARCHAR(20),
    stock_code VARCHAR(20),
    description TEXT,
    quantity INTEGER,
    invoice_date TIMESTAMP,
    unit_price NUMERIC(10, 2),
    customer_id NUMERIC(10, 0),
    country VARCHAR(100)
);
--Step 1: Verify the complete import
SELECT *
FROM online_retail
LIMIT 10;
--Step 1: Verify the complete import
SELECT COUNT(*) AS total_records
FROM online_retail;
--Step A — Count missing descriptions
SELECT
    COUNT(*) AS total_rows,
    COUNT(description) AS rows_with_description,
    COUNT(*) - COUNT(description) AS missing_descriptions
FROM online_retail;
--Step B — Inspect rows with missing descriptions
SELECT
    stock_code,
    description,
    quantity,
    unit_price,
    quantity * unit_price AS transaction_value
FROM online_retail
WHERE description IS NULL
LIMIT 20;
--Step C — Check products with zero total revenue
SELECT
    stock_code,
    description,
    SUM(quantity * unit_price) AS total_revenue
FROM online_retail
GROUP BY stock_code, description
HAVING SUM(quantity * unit_price) = 0
LIMIT 20;
--Your next small task — inspect stock code 10080
SELECT
    invoice_no,
    stock_code,
    description,
    quantity,
    unit_price,
    quantity * unit_price AS transaction_value
FROM online_retail
WHERE stock_code = '10080'
ORDER BY invoice_date;
--2. Let's verify the groups
SELECT
    stock_code,
    description,
    COUNT(*) AS transaction_count,
    SUM(quantity) AS total_quantity,
    SUM(quantity * unit_price) AS total_revenue
FROM online_retail
WHERE stock_code = '10080'
GROUP BY stock_code, description
ORDER BY total_revenue DESC;
--"What is the total sales revenue recorded in our dataset?"
WITH revenue_stats AS(
     SELECT (quantity * unit_price) AS Total_Price
FROM online_retail
)
SELECT SUM(Total_Price) AS Total_Revenue
FROM revenue_stats;
-- OR 
SELECT SUM(quantity * unit_price) AS total_revenue
FROM online_retail;
--Challenge #2
--Business scenario: Your manager now wants to know which countries generate the most transaction value.
--Show the top 10 countries by total revenue, highest first.
SELECT country,
       SUM(quantity * unit_price) AS total_revenue
FROM online_retail
GROUP BY country
ORDER BY total_revenue DESC
LIMIT 10;
--Challenge #3-Monthly Revenue Trend 📈
--Business scenario: Your manager wants to understand how transaction value 
--changes month by month to identify seasonal patterns.
SELECT DATE_TRUNC('month',invoice_date) AS sales_month,
       SUM(quantity * unit_price) AS total_revenue
FROM online_retail
GROUP BY DATE_TRUNC('month',invoice_date)
ORDER BY sales_month ASC;
--Challenge #4 — Month-over-Month Growth
--Business scenario: Your manager asks, “By what percentage did transaction value
--increase or decrease compared with the previous month?”
WITH M0M_Stats AS(
    SELECT DATE_TRUNC('month',invoice_date) AS sales_month,
	       SUM(quantity * unit_price) AS total_revenue
	FROM online_retail
    GROUP BY DATE_TRUNC('month',invoice_date)
),
previous_month_stats AS(
    SELECT sales_month,
	       total_revenue,
		   LAG(total_revenue) 
		   OVER(ORDER BY sales_month) AS previous_month_revenue
	FROM M0M_Stats
),
Growth_Stats AS(
SELECT sales_month,
       total_revenue,
	   previous_month_revenue,
	   ROUND((total_revenue - previous_month_revenue) * 100.0
	   /NULLIF(previous_month_revenue,0),2) AS mom_growth_percentage
FROM previous_month_stats
)
SELECT sales_month,
       total_revenue,
	   previous_month_revenue,
	   mom_growth_percentage,
	   CASE
	       WHEN previous_month_revenue IS NULL
		   THEN 'First_Month'
		   WHEN total_revenue > previous_month_revenue 
		   THEN 'Increase'
		   WHEN total_revenue < previous_month_revenue
		   THEN 'Decrease'
		   ELSE 'No Change'
		   END AS revenue_trend
FROM Growth_Stats
ORDER BY sales_month;
--Challenge 5 — Top 5 Products by Revenue
--Business scenario: 
--Your manager wants to identify the five products generating the highest transaction value.
SELECT * FROM online_retail LIMIT 5
SELECT stock_code,
       description,
	   SUM(quantity * unit_price) AS total_revenue
FROM online_retail
GROUP BY stock_code,
         description
ORDER BY total_revenue DESC
LIMIT 5;
--Challenge #6
--Business question: 
--Find the top 10 customers by total transaction value in the Online Retail dataset.
SELECT customer_id,
       SUM(quantity * unit_price) AS Total_Transaction_Value
FROM online_retail
WHERE customer_id IS NOT NULL
GROUP BY customer_id
ORDER BY Total_Transaction_Value DESC
LIMIT 10;
--Challenge #7
--Business question: 
--Find the top 10 products by total quantity sold, 
--excluding records with negative quantities and zero-priced transactions.
SELECT stock_code,
       description,
	   SUM(quantity) AS Total_Quantity
FROM online_retail
WHERE quantity > 0
AND unit_price > 0
GROUP BY stock_code,
         description
ORDER BY Total_Quantity DESC
LIMIT 10;
--Challenge #8
--Business question: Find the top 10 customers by the number of distinct invoices they placed.
SELECT customer_id,
      COUNT (DISTINCT invoice_no) AS Distinct_Invoices
FROM online_retail
WHERE customer_id IS NOT NULL
GROUP BY customer_id
ORDER BY Distinct_Invoices DESC
LIMIT 10;
--Challenge #9
--Business question: 
--Find the top 10 customers by their average transaction value per distinct invoice.
WITH Average_Transaction_Stats AS(
     SELECT customer_id,
	        SUM(quantity * unit_price) AS Total_Transaction_Value,
			COUNT(DISTINCT invoice_no) AS Distinct_Invoices
	 FROM online_retail
	 WHERE 
	 WHERE customer_id IS NOT NULL
	 GROUP BY customer_id
)
SELECT customer_id,
       Total_Transaction_Value,
	   Distinct_Invoices,
	   ROUND(Total_Transaction_Value / NULLIF(Distinct_Invoices,0)
	   ,2) AS Average_Per_Invoice
FROM Average_Transaction_Stats
ORDER BY Average_Per_Invoice DESC
LIMIT 10;
--Challenge #10
--Business question: Find the number of distinct customers who made purchases in each month.
SELECT
    DATE_TRUNC('month', invoice_date) AS sales_month,
    COUNT(DISTINCT customer_id) AS distinct_customers
FROM online_retail
WHERE customer_id IS NOT NULL
GROUP BY DATE_TRUNC('month', invoice_date)
ORDER BY sales_month;
--Challenge #11 — Customer Retention Analysis
--Business scenario: 
--An e-commerce manager wants to identify customers who purchased in more than one distinct month. 
--This helps the business understand repeat customer activity.
WITH Month_Stats AS(
SELECT customer_id,
       DATE_TRUNC('month', invoice_date) AS sales_month
FROM online_retail
WHERE customer_id IS NOT NULL
GROUP BY customer_id,DATE_TRUNC('month', invoice_date)
)

SELECT
    customer_id,
    COUNT(DISTINCT sales_month) AS Distinct_Month
FROM Month_Stats
GROUP BY customer_id
HAVING COUNT(DISTINCT sales_month) > 1
ORDER BY Distinct_Month DESC;
--Challenge #12 of 20 — Revenue from Repeat Customers
--Business question: 
--How much net transaction value did each customer generate across the dataset, 
--and how many distinct months were they active?

WITH Month_Stats AS (
    SELECT
        customer_id,
        SUM(quantity * unit_price) AS Monthly_Transaction_Value,
        DATE_TRUNC('month', invoice_date) AS sales_month
    FROM online_retail
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id, DATE_TRUNC('month', invoice_date)
)
SELECT
    customer_id,
    SUM(Monthly_Transaction_Value) AS Total_Transaction_Value,
    COUNT(DISTINCT sales_month) AS Active_Months
FROM Month_Stats
GROUP BY customer_id
HAVING COUNT(DISTINCT sales_month) >= 6
ORDER BY Total_Transaction_Value DESC;
--Challenge #13 — Customer Value Segmentation
--Scenario: 
--The e-commerce manager wants to classify customers into three groups 
--based on their total net transaction value.
WITH Customer_Stats AS(
     SELECT customer_id,
	        SUM(quantity * unit_price) AS total_transaction_value
	 FROM online_retail
	 WHERE customer_id IS NOT NULL
	 GROUP BY customer_id
)
SELECT customer_id,
       total_transaction_value,
	   CASE
          WHEN total_transaction_value >= 10000 THEN 'High Value'
          WHEN total_transaction_value >= 2000 THEN 'Medium Value'
          ELSE 'Low Value'
       END AS customer_segment
FROM Customer_Stats
ORDER BY total_transaction_value DESC;
--Challenge #14-Identify High-Value Customers by Country
--Business scenario
--An e-commerce company wants to identify its highest-value customers in each country 
--so its marketing team can design targeted loyalty campaigns.
SELECT * FROM online_retail LIMIT 10
WITH customer_stats AS(
SELECT customer_id,
       country,
	   SUM(quantity * unit_price) AS total_transaction_value
FROM online_retail
WHERE customer_id IS NOT NULL
GROUP BY customer_id,
         country
),
ranking_stats AS(
SELECT customer_id,
       country,
	   total_transaction_value,
	   DENSE_RANK() OVER(PARTITION BY country
	                     ORDER BY total_transaction_value DESC
						 ) AS customer_rank
FROM customer_stats
)
SELECT customer_id,
       country,
	   total_transaction_value,
	   customer_rank
FROM ranking_stats
WHERE customer_rank <=3
ORDER BY country,customer_rank;
--Challenge #15: Customers Above Their Country's Average
--Business scenario
--An e-commerce company wants to identify customers whose total transaction value 
--is higher than the average customer transaction value in their country. 
--The company will use this analysis to target loyalty campaigns.
WITH customer_stats AS(
     SELECT customer_id,
	        country,
			SUM(quantity * unit_price) AS total_transaction_value
	 FROM online_retail
     WHERE customer_id IS NOT NULL
     GROUP BY customer_id,
              country	
),
country_stats AS(
     SELECT customer_id,
	        country,
			total_transaction_value,
			AVG(total_transaction_value) OVER(
            PARTITION BY country
			) AS country_average_value
     FROM customer_stats
)
SELECT customer_id,
       country,
	   total_transaction_value,
	   country_average_value
FROM country_stats
WHERE total_transaction_value > country_average_value
ORDER BY country, total_transaction_value DESC;
--Challenge #16 — Customer Repeat-Purchase Analysis
--Business Scenario
--An e-commerce manager wants to identify customers who made purchases across
--multiple distinct invoices.
--The manager wants to understand which customers are repeat buyers 
--and how much transaction value they generated.
SELECT customer_id,
       SUM(quantity * unit_price) AS total_transaction_value,
	   COUNT(DISTINCT invoice_no) AS distinct_invoices
FROM online_retail
WHERE customer_id IS NOT NULL
GROUP BY customer_id
HAVING COUNT(DISTINCT invoice_no) > 1
ORDER BY total_transaction_value DESC;
--🔥 Challenge #17 — Product Return Analysis (INTERDUCE ABS() means absolute value)
--Business scenario
--An e-commerce manager wants to identify products with the highest returned quantities. 
--In this dataset, negative quantity values can indicate returns or cancellations, 
--so we’ll use them as a return indicator for this exercise.
SELECT
    stock_code,
    description,
    SUM(ABS(quantity)) AS total_returned_quantity
FROM online_retail
WHERE quantity < 0
GROUP BY stock_code, description
ORDER BY total_returned_quantity DESC
LIMIT 10;
--🔥 Challenge #18 — Product Return Rate Analysis
--Business scenario
--An e-commerce manager wants to identify products with 
--unusually high return quantities compared with their sold quantities.
--In this exercise, we'll use negative quantities as a return indicator, 
--while remembering that some negative records may represent cancellations or operational adjustments.
WITH quantity_stats AS (
    SELECT
        stock_code,
        description,
        SUM(
            CASE
                WHEN quantity > 0 THEN quantity
                ELSE 0
            END
        ) AS total_sold_quantity
    FROM online_retail
    GROUP BY stock_code, description
),
return_stats AS (
    SELECT
        stock_code,
        description,
        SUM(ABS(quantity)) AS total_returned_quantity
    FROM online_retail
    WHERE quantity < 0
    GROUP BY stock_code, description
)
SELECT
    Q.stock_code,
    Q.description,
    Q.total_sold_quantity,
    COALESCE(R.total_returned_quantity, 0) AS total_returned_quantity,
    ROUND(
        COALESCE(R.total_returned_quantity, 0) * 100.0
        / NULLIF(Q.total_sold_quantity, 0),
        2
    ) AS return_rate_percentage
FROM quantity_stats AS Q
LEFT JOIN return_stats AS R
    ON Q.stock_code = R.stock_code
   AND Q.description IS NOT DISTINCT FROM R.description
WHERE Q.total_sold_quantity >= 100
ORDER BY return_rate_percentage DESC NULLS LAST
LIMIT 10;
--🔥 Challenge #19 — Customer Purchase Trends
--Business scenario
--An e-commerce manager wants to identify customers whose monthly transaction value increased 
--compared with the previous month.
SELECT * FROM online_retail LIMIT 2
WITH customer_stats AS(
     SELECT customer_id,
	        DATE_TRUNC('month', invoice_date) AS sales_month,
			SUM(quantity * unit_price) AS monthly_transaction_value
	 FROM online_retail
	 WHERE customer_id IS NOT NULL
	 GROUP BY customer_id,
	          DATE_TRUNC('month', invoice_date)
),
previous_month_stats AS(
   SELECT customer_id,
          sales_month,
		  monthly_transaction_value,
		  LAG(monthly_transaction_value) OVER(PARTITION BY customer_id
		                        ORDER BY sales_month
								) AS previous_month_value
   FROM customer_stats
),
monthly_change_stats AS(
SELECT customer_id,
       sales_month,
	   monthly_transaction_value,
	   previous_month_value,
	   monthly_transaction_value -previous_month_value
	   AS month_over_month_change
FROM previous_month_stats
)
SELECT customer_id,
       sales_month,
	   monthly_transaction_value,
	   previous_month_value,
	   month_over_month_change
FROM monthly_change_stats
WHERE month_over_month_change > 0
ORDER BY customer_id,sales_month;
--🔥 Challenge #20 — Customer Purchase Consistency
--Business scenario
--An e-commerce manager wants to identify customers who made purchases in at 
--least 6 distinct months and calculate their average monthly transaction value.
WITH monthly_stats AS (
     SELECT customer_id,
	        DATE_TRUNC('month', invoice_date) AS sales_month,
			SUM(quantity * unit_price) AS monthly_transaction_value
	 FROM online_retail
	 WHERE customer_id IS NOT NULL
	 GROUP BY customer_id,
	          DATE_TRUNC('month', invoice_date)
)
SELECT customer_id,
	   COUNT(DISTINCT sales_month) AS active_months,
	   SUM(monthly_transaction_value) AS total_transaction_value,
	   ROUND(AVG(monthly_transaction_value),2) AS  average_monthly_transaction_value
FROM monthly_stats
GROUP BY customer_id
HAVING COUNT(DISTINCT sales_month) >=6
ORDER BY total_transaction_value DESC;
    
