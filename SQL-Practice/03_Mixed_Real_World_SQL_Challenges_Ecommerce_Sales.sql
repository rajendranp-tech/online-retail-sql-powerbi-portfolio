--🏢 Mixed Challenge #1 — Customer Sales Performance
--"Which customers have generated more Completed Sales than the average Completed Sales of all customers?"
--ecommerce_sales_real_world_challenge_01.csv
--“Rajendra, please load this sales data into PostgreSQL. 
--Before we start analysis, I want you to make sure the data 
--has been imported correctly and understand what we're working with.”
--Inspect → Detect → Understand → Clean → Analyze
CREATE TABLE ecommerce_sales (
    Order_ID VARCHAR(50) PRIMARY KEY,
    Customer_ID VARCHAR(50),
    Customer VARCHAR(50),
    Region VARCHAR(50),
    Order_Date DATE,
    Product VARCHAR(50),
    Category VARCHAR(50),
    Quantity INT,
    Discount_Percent NUMERIC(5,2),
    Sales NUMERIC(12,2),
    Status VARCHAR(50),
    Payment_Method VARCHAR(50)
);
SELECT COUNT(*) FROM ecommerce_sales;
SELECT * FROM ecommerce_sales
LIMIT 10;
--🎯 Data Quality Check #1 — Missing Values
--“Rajendra, are there any missing values in the sales dataset?”
SELECT
    Order_ID,
    Customer_ID,
    Customer,
    Region,
    Order_Date,
    Product,
    Category,
    Quantity,
    Discount_Percent,
    Sales,
    Status,
    Payment_Method
FROM ecommerce_sales
WHERE Region IS NULL;

SELECT Sales FROM ecommerce_sales

WHERE Sales IS NULL;
--🎯 Next check: Duplicate Orders /CHECK DUPMICATE ROWS IN A COLUMN
SELECT COUNT(*) AS Total_Rows
FROM ecommerce_sales
GROUP BY order_id
HAVING COUNT(*) > 1;
--If we want PostgreSQL to show the duplicated ID, where should Order_ID appear?
SELECT Order_ID,
       COUNT(*) AS Total_Rows
FROM ecommerce_sales
GROUP BY Order_ID
HAVING COUNT(*) > 1;

--How can we see all the different values currently stored in the Status column?
SELECT DISTINCT Status  
FROM ecommerce_sales;  

--🎯 Next step — investigate the inconsistent record
SELECT *
FROM ecommerce_sales
WHERE Status = 'completed';
-- CHANGEING completed to Completed
--UPDATE is used when we want to modify existing data inside a table.
UPDATE ecommerce_sales
SET Status = 'Completed'
WHERE Status = 'completed';
--🎯 Your next task: write a query to display the complete record for Order_ID = 'O10212'.
SELECT * 
FROM ecommerce_sales
WHERE Order_ID = 'O10212';

--“Does Customer_31 have other orders, and if so, what Region is recorded on those orders?”
SELECT *
FROM ecommerce_sales
WHERE Customer_ID = 'C1031';
--🔎 Next Check: Invalid Quantity
SELECT *
FROM ecommerce_sales
WHERE Quantity <=0;
--OR
SELECT Quantity
FROM ecommerce_sales
WHERE Quantity <=0; 
--🚀 Next check: Sales values
--Can Sales be zero or negative?
SELECT *
FROM ecommerce_sales
WHERE Sales <= 0;
--🔎 Next Data Quality Check: Discount
--Find any records where the discount is less than 0 OR greater than 100.
SELECT *
FROM ecommerce_sales
WHERE discount_percent < 0 
OR
discount_percent > 100 ;

--🔎 One more important check: Customer IDs
--Before we move from data quality into actual business analysis, 
--let's check whether every order has a Customer_ID.
SELECT *
FROM ecommerce_sales
WHERE customer_id IS NULL;

--“Rajendra, what period does this sales data cover?”
SELECT
    MIN(Order_Date),
	MAX(Order_Date)
FROM ecommerce_sales;

--🚀 First Real Business Analysis Challenge
--"What is our total sales revenue from Completed orders?"
SELECT SUM(Sales) AS Total_Sales
FROM ecommerce_sales
WHERE Status = 'Completed';
--“How many Completed orders contributed to that ₹10.49 million in sales?”
SELECT COUNT(*) AS Completed_Orders
FROM ecommerce_sales
WHERE Status = 'Completed';
--“What is the average sales value per Completed order?”
SELECT AVG(Sales) AS AVG_Sales
FROM ecommerce_sales
WHERE Status = 'Completed';
--"What percentage of all orders were Completed?"
WITH ecommerce_sales_analysis AS (
     SELECT COUNT(*) AS Total_Orders,
	        COUNT(CASE
			        WHEN Status = 'Completed'
					THEN 1
					END) AS Completed_Orders
FROM ecommerce_sales
)
SELECT Total_Orders,
       Completed_Orders,
	   (Completed_Orders * 100.0) 
	   / NULLIF(Total_Orders,0) AS Percentage_Completed_Orders
FROM ecommerce_sales_analysis;
--"What percentage of our sales revenue came from Completed orders?"
WITH Sales_Revenue_analysis AS (
     SELECT SUM(Sales) AS Total_Sales,
	        SUM(CASE 
			       WHEN STATUS = 'Completed' 
				   THEN Sales 
				   ELSE 0 
				   END) AS Completed_Sales
FROM ecommerce_sales
)
SELECT Total_Sales,
       Completed_Sales,
	   (Completed_Sales * 100.0) 
	   / NULLIF(Total_Sales,0) AS Percentage_Sales_Revenue
FROM Sales_Revenue_analysis;
--“I want to know how much Completed Sales revenue each Region generated.”
SELECT Region,
       SUM(Sales) AS Total_Sales
FROM ecommerce_sales
WHERE Status = 'Completed'
GROUP BY Region;
--“North has the highest sales, but is North also responsible for
--the largest number of Completed orders?”
SELECT Region,
       COUNT(*) AS Total_Orders
FROM ecommerce_sales
WHERE Status = 'Completed'
GROUP BY Region;
--Completed Sales Revenue by Region
--vs.
--Completed Order Count by Region
--“Which Region has the highest average sales per Completed order?”
SELECT Region,
       AVG(Sales) AS Average_Sales_Per_Order
FROM ecommerce_sales
WHERE Status = 'Completed'
GROUP BY Region;
--For each individual Completed order, how much sales value does that Region generate on average?
SELECT Region,
       SUM(Sales) AS Completed_Sales,
	   COUNT(*) AS Total_Orders,
       AVG(Sales) AS Average_Sales_Per_Order
FROM ecommerce_sales
WHERE Status = 'Completed'
GROUP BY Region;
--"Which Product generated the highest Completed Sales revenue?"
SELECT * FROM ecommerce_sales LIMIT 5;
SELECT product,
       SUM(Sales) AS Total_Completed_Sales
FROM ecommerce_sales
WHERE Status = 'Completed'
GROUP BY product
ORDER BY SUM(Sales) DESC
LIMIT 1;
--“How many Completed orders generated that Laptop revenue?”
SELECT COUNT(*) AS Laptop_Completed_Order
FROM ecommerce_sales
WHERE status = 'Completed'
AND product = 'Laptop';
--“What is the average sales value of a Completed Laptop order?”
SELECT AVG(Sales) AS Average_Laptop_Completed_Order
FROM ecommerce_sales
WHERE status = 'Completed'
AND product = 'Laptop';
--"For each Product, show the Total Completed Sales, 
--number of Completed Orders, and Average Sales per Completed Order."     
SELECT Product,
       SUM(Sales) AS Total_Completed_Sales,
       COUNT(*) AS Completed_Orders,
	   AVG(Sales) AS Average_Sales_per_Completed_Order
FROM ecommerce_sales
WHERE status = 'Completed'
GROUP BY Product;
--"For each Product, what percentage of the company's total Completed Sales 
--revenue does that product contribute?"
--(When one result contains one overall value, and we need that same value available 
--for every row of another result, CROSS JOIN can be used.)
WITH Sales_Stats AS (
    SELECT Product,
           SUM(Sales) AS Product_Sales
    FROM ecommerce_sales
    WHERE Status = 'Completed'
    GROUP BY Product
),
Total_Revenue AS (
    SELECT SUM(Sales) AS Total_Company_Sales
    FROM ecommerce_sales
    WHERE Status = 'Completed'
)
SELECT S.Product,
       S.Product_Sales,
       T.Total_Company_Sales,
       (S.Product_Sales * 100.0)
       / NULLIF(T.Total_Company_Sales, 0) AS Percentage_Completed_Sales
FROM Sales_Stats AS S
CROSS JOIN Total_Revenue AS T;
--“Which Products have an average Completed Order value 
--higher than the overall average Completed Order value across all Products?”
WITH Sales_Stats AS (
     SELECT Product,
	        AVG(Sales) AS Average_Completed_Order
	 FROM ecommerce_sales
	 WHERE Status = 'Completed'
	 GROUP BY Product
),
AVG_Stats AS (
    SELECT AVG(Sales) AS Average_Total_Completed_Order
	FROM ecommerce_sales
	WHERE Status = 'Completed'
)
SELECT S.Product,
       S.Average_Completed_Order,
	   A.Average_Total_Completed_Order
FROM Sales_Stats AS S
CROSS JOIN AVG_Stats AS A
WHERE S.Average_Completed_Order > A.Average_Total_Completed_Order;
--“For each Region, identify the Product that generated the 
--highest Completed Sales revenue in that Region.”
WITH Product_Stats AS(
     SELECT Product,
	        Region,
			SUM(Sales) AS Completed_Sales
FROM ecommerce_sales
WHERE Status = 'Completed'
GROUP BY Product,Region
),
Ranking_Stats AS (
SELECT Product,
       Region,
	   Completed_Sales,
	   DENSE_RANK() OVER(PARTITION BY Region
	                      ORDER BY Completed_Sales DESC
						  ) AS Completed_Sales_Rank
FROM Product_Stats
)
SELECT Product,
       Region,
	   Completed_Sales,
	   Completed_Sales_Rank
FROM Ranking_Stats
WHERE Completed_Sales_Rank = 1;
--“For each Region, show the Total Completed Sales, number of Completed Orders,
--Average Sales per Completed Order, 
--and identify the Region with the highest Average Sales per Completed Order.”
SELECT Region,
       SUM(Sales) AS Total_Completed_Sales,
       COUNT(*) AS Total_Completed_Orders,
       AVG(Sales) AS Average_Completed_Order
FROM ecommerce_sales
WHERE Status = 'Completed'
GROUP BY Region
ORDER BY Average_Completed_Order DESC
LIMIT 1;
--“For each Region, show the Total Completed Sales and the percentage of the 
--company's total Completed Sales contributed by that Region. 
--Then identify the Region with the highest contribution.”    
WITH Region_Stats AS (
    SELECT Region,
           SUM(Sales) AS Region_Total_Completed_Sales
    FROM ecommerce_sales
    WHERE Status = 'Completed'
    GROUP BY Region
),
Company_Stats AS (
        SELECT SUM(Sales) AS Total_Completed_Sales
		FROM ecommerce_sales
		WHERE Status = 'Completed'
)
SELECT R.Region,
       R.Region_Total_Completed_Sales,
       C.Total_Completed_Sales,
       (R.Region_Total_Completed_Sales * 100.0)
       / NULLIF(C.Total_Completed_Sales, 0) AS Percentage_Total_Completed_Sales
FROM Region_Stats AS R
CROSS JOIN Company_Stats AS C
ORDER BY Percentage_Total_Completed_Sales DESC
LIMIT 1;
--“For each Region, calculate the Total Completed Sales and the 
--average Completed Sales per order. Then compare each Region's average against the company's 
--overall average Completed Order value and identify the Regions performing above the company average.”
WITH Region_Stats AS(
     SELECT Region,
	        SUM(Sales) AS Total_Completed_Sales,
			AVG(Sales) AS Average_Completed_Sales
     FROM ecommerce_sales
	 WHERE Status = 'Completed'
	 GROUP BY Region
),
Company_Stats AS(
      SELECT AVG(Sales) Company_Average_Completed_Sales
	  FROM ecommerce_sales
	  WHERE Status = 'Completed'
)
SELECT R.Region,
	   R.Total_Completed_Sales,
	   R.Average_Completed_Sales,
	   C.Company_Average_Completed_Sales
FROM Region_Stats AS R
CROSS JOIN Company_Stats AS C
WHERE R.Average_Completed_Sales > C.Company_Average_Completed_Sales;
--“For each Region, calculate Total Completed Sales. 
--Then identify the Region whose Total Completed Sales 
--is above the average Total Completed Sales across all Regions.”
WITH Region_Stats AS(
     SELECT Region,
	        SUM(Sales) AS Total_Completed_Sales
     FROM ecommerce_sales
	 WHERE Status = 'Completed'
	 GROUP BY Region
),
Completed_Sales_Stats AS(
     SELECT AVG(Total_Completed_Sales) AS AVG_Total_Completed_Sales
	 FROM Region_Stats
)
SELECT R.Region,
       R.Total_Completed_Sales,
	   C.AVG_Total_Completed_Sales
FROM Region_Stats AS R
CROSS JOIN Completed_Sales_Stats AS C
WHERE R.Total_Completed_Sales > C.AVG_Total_Completed_Sales;
--🔥 Challenge #13 — Find the Top Revenue-Contributing Product in Each Region
--Business scenario
--Your sales manager wants to know which product contributes the most 
--Completed Sales revenue in each region.
--The manager needs the winning product, its revenue, and its percentage contribution 
--to that region's total Completed Sales revenue.
WITH Region_Stats AS (
    SELECT
        Region,
        Product,
        SUM(Sales) AS Product_Completed_Sales
    FROM ecommerce_sales
    WHERE Status = 'Completed'
    GROUP BY
        Region,
        Product
),
Ranking_Stats AS (
    SELECT
        Region,
        Product,
        Product_Completed_Sales,

        SUM(Product_Completed_Sales) OVER (
            PARTITION BY Region
        ) AS Region_Total_Completed_Sales,

        DENSE_RANK() OVER (
            PARTITION BY Region
            ORDER BY Product_Completed_Sales DESC
        ) AS Product_Rank

    FROM Region_Stats
)
SELECT
    Region,
    Product,
    Product_Completed_Sales,
    Region_Total_Completed_Sales,
    Product_Rank,

    ROUND((Product_Completed_Sales * 100.0)
        / NULLIF(Region_Total_Completed_Sales, 0),2)
        AS Percentage_Of_Region_Sales

FROM Ranking_Stats AS R
WHERE Product_Rank = 1
ORDER BY
    Region,
    Product;
--🔥 Challenge #14 — Find Products with High Returns
--Your company's sales manager is concerned about product returns.
--They want to identify products with the highest return rate, so the 
--team can investigate product quality, customer satisfaction, or delivery issues.
--Your task is to calculate the number of orders and returned orders for each product,
--calculate the return rate, and identify the product with the highest rate.
WITH Returns_Stats AS(
     SELECT Product,
	        COUNT(*) AS Total_Orders,
			COUNT(CASE
			          WHEN Status = 'Returned' THEN 1
				   END) AS Returned_Orders
	 FROM ecommerce_sales
	 GROUP BY Product
)
SELECT Product,
       Total_Orders,
	   Returned_Orders,
	   ROUND((Returned_Orders * 100.0)
	   /NULLIF(Total_Orders,0),2) AS Return_Rate_Percentage
FROM Returns_Stats
ORDER BY Return_Rate_Percentage DESC;
--🔥 Challenge #15 — High Revenue, High Returns
--Your sales manager notices that some products generate substantial revenue,
--but customers may also be returning them frequently.
--The manager wants to identify products that have both high Completed Sales revenue 
--and a high return rate so the business can investigate potential quality 
--or customer-experience problems.
WITH Product_Stats AS(
     SELECT Product,
	        SUM(CASE
			        WHEN Status = 'Completed' THEN Sales
					ELSE 0
					END) AS Product_Completed_Sales,
			COUNT(*) AS Total_Orders,
			COUNT(CASE 
			          WHEN Status = 'Returned' THEN 1
					  END) AS Returned_Orders
	FROM ecommerce_sales
	GROUP BY Product
),
Company_Stats AS (
    SELECT
        (SELECT AVG(Product_Completed_Sales)
         FROM Product_Stats
        ) AS Avg_Product_Completed_Sales,

        ROUND(
            (SELECT COUNT(*)
             FROM ecommerce_sales
             WHERE Status = 'Returned'
            ) * 100.0
            /
            NULLIF(
                (SELECT COUNT(*)
                 FROM ecommerce_sales),
                0
            ),
            2
        ) AS Overall_Return_Rate_Percentage
)
SELECT
    P.Product,
    P.Product_Completed_Sales,
    P.Total_Orders,
    P.Returned_Orders,
    ROUND(
        P.Returned_Orders * 100.0
        / NULLIF(P.Total_Orders, 0),
        2
    ) AS Product_Return_Rate_Percentage,
    C.Avg_Product_Completed_Sales,
    C.Overall_Return_Rate_Percentage
FROM Product_Stats AS P
CROSS JOIN Company_Stats AS C
WHERE
    P.Product_Completed_Sales > C.Avg_Product_Completed_Sales
    AND
    (
        P.Returned_Orders * 100.0
        / NULLIF(P.Total_Orders, 0)
    ) > C.Overall_Return_Rate_Percentage
ORDER BY Product_Return_Rate_Percentage DESC; 
---OR

WITH Product_Stats AS (
    SELECT
        Product,
        SUM(CASE WHEN Status = 'Completed' THEN Sales ELSE 0 END)
            AS Product_Completed_Sales,
        COUNT(*) AS Total_Orders,
        COUNT(CASE WHEN Status = 'Returned' THEN 1 END)
            AS Returned_Orders
    FROM ecommerce_sales
    GROUP BY Product
),
Company_Stats AS (
    SELECT
        AVG(Product_Completed_Sales) AS Avg_Product_Completed_Sales,
        SUM(Returned_Orders) * 100.0
            / NULLIF(SUM(Total_Orders), 0)
            AS Overall_Return_Rate_Percentage
    FROM Product_Stats
)
SELECT
    P.Product,
    P.Product_Completed_Sales,
    P.Total_Orders,
    P.Returned_Orders,
    ROUND(
        P.Returned_Orders * 100.0 / NULLIF(P.Total_Orders, 0),
        2
    ) AS Product_Return_Rate_Percentage
FROM Product_Stats P
CROSS JOIN Company_Stats C
WHERE P.Product_Completed_Sales > C.Avg_Product_Completed_Sales
  AND P.Returned_Orders * 100.0 / NULLIF(P.Total_Orders, 0)
      > C.Overall_Return_Rate_Percentage
ORDER BY Product_Return_Rate_Percentage DESC;
--🔥 Challenge #16 — Monthly Sales Growth & Declining Products
--1. The business problem
--Your sales manager wants to understand which products are growing and which are losing sales momentum.
--The manager asks:
--Compare each product's monthly Completed Sales with the previous month's sales.
--Calculate month-over-month (MoM) growth and identify products whose sales declined.
SELECT * FROM ecommerce_sales LIMIT 5
WITH Monthly_Stats AS(
     SELECT product,
	        DATE_TRUNC('month', Order_Date) AS Sales_Month,
			SUM(Sales) AS Monthly_Completed_Sales
	 FROM ecommerce_sales
	 WHERE Status = 'Completed'
	 GROUP BY product,
	          DATE_TRUNC('month', Order_Date)
),
Previous_Month_Stats AS(
     SELECT product,
	        Sales_Month,
	        Monthly_Completed_Sales,
			LAG(Monthly_Completed_Sales)
			OVER(PARTITION BY product 
			     ORDER BY Sales_Month
			)AS Previous_Month_Sales
	  FROM Monthly_Stats
),
Growth_Stats AS(
      SELECT product,
	         Sales_Month,
			 Monthly_Completed_Sales,
			 Previous_Month_Sales,
			 ROUND((Monthly_Completed_Sales - Previous_Month_Sales) * 100.0
			 /NULLIF(Previous_Month_Sales,0),2) AS MoM_Growth_Percentage
	  FROM Previous_Month_Stats
),
Final_Trend AS (
SELECT product,
       Sales_Month,
	   Monthly_Completed_Sales,
	   Previous_Month_Sales,
	   MoM_Growth_Percentage,
	   CASE WHEN Previous_Month_Sales IS NULL
            THEN 'First Month'
			WHEN Previous_Month_Sales = 0
            THEN 'Cannot Calculate'
			WHEN Monthly_Completed_Sales > Previous_Month_Sales
            THEN 'Growing'
			WHEN Monthly_Completed_Sales < Previous_Month_Sales
            THEN 'Declining'
			ELSE 'No Change'
		END AS Sales_Trend
FROM Growth_Stats
)
SELECT *
FROM Final_Trend
WHERE Sales_Trend ='Declining'
ORDER BY product,
         Sales_Month;
--🔥 Challenge #17 — Identify Customers Whose Spending Is Declining
--Business scenario
--Your e-commerce manager wants to identify customers whose spending is decreasing month over month, 
--so the company can investigate customer engagement and retention.
WITH Customer_Monthly_Stats AS(
SELECT
    Customer,
    DATE_TRUNC('month', Order_Date) AS Sales_Month,
    SUM(Sales) AS Monthly_Sales
FROM ecommerce_sales
WHERE Status = 'Completed'
GROUP BY
    Customer,
    DATE_TRUNC('month', Order_Date)
),
Previous_Month_Stats AS(
SELECT Customer,
       Sales_Month,
	   Monthly_Sales,
	   LAG(Monthly_Sales) OVER(PARTITION BY Customer
	                           ORDER BY Sales_Month
							   ) AS Previous_Month_Sales
FROM Customer_Monthly_Stats
),
Growth_Stats AS(
SELECT Customer,
       Sales_Month,
	   Monthly_Sales,
	   Previous_Month_Sales,
	   ROUND((Monthly_Sales - Previous_Month_Sales)*100.0
	   /NULLIF(Previous_Month_Sales,0),2) AS MoM_Growth_Percentage
FROM Previous_Month_Stats
)
SELECT
    Customer,
    Sales_Month,
    Monthly_Sales,
    Previous_Month_Sales,
    MoM_Growth_Percentage
FROM Growth_Stats
WHERE MoM_Growth_Percentage < 0
ORDER BY Customer, Sales_Month;
--Challenge #18 — Identify customers with consistently declining sales over multiple months.

WITH Customer_Monthly_Stats AS (
    SELECT
        Customer,
        DATE_TRUNC('month', Order_Date) AS Sales_Month,
        SUM(Sales) AS Monthly_Sales
    FROM ecommerce_sales
    WHERE Status = 'Completed'
    GROUP BY
        Customer,
        DATE_TRUNC('month', Order_Date)
),

Previous_Month_Stats AS (
    SELECT
        Customer,
        Sales_Month,
        Monthly_Sales,
        LAG(Monthly_Sales) OVER (
            PARTITION BY Customer
            ORDER BY Sales_Month
        ) AS Previous_Month_Sales
    FROM Customer_Monthly_Stats
),

Growth_Stats AS (
    SELECT
        Customer,
        Sales_Month,
        Monthly_Sales,
        Previous_Month_Sales,
        ROUND(
            (Monthly_Sales - Previous_Month_Sales) * 100.0
            / NULLIF(Previous_Month_Sales, 0),
            2
        ) AS MoM_Growth_Percentage
    FROM Previous_Month_Stats
),

Sales_Trend AS (
    SELECT
        Customer,
        Sales_Month,
        Monthly_Sales,
        Previous_Month_Sales,
        MoM_Growth_Percentage,
        CASE
            WHEN Previous_Month_Sales IS NULL
                THEN 'First Month'
            WHEN Monthly_Sales < Previous_Month_Sales
                THEN 'Declining'
            WHEN Monthly_Sales > Previous_Month_Sales
                THEN 'Growing'
            ELSE 'No Change'
        END AS Sales_Trend
    FROM Growth_Stats
),

Previous_Month_Trend AS (
    SELECT
        Customer,
        Sales_Month,
        Monthly_Sales,
        Previous_Month_Sales,
        MoM_Growth_Percentage,
        Sales_Trend,

        LAG(Sales_Trend) OVER (
            PARTITION BY Customer
            ORDER BY Sales_Month
        ) AS Previous_Month_Trend,

        LAG(Sales_Month) OVER (
            PARTITION BY Customer
            ORDER BY Sales_Month
        ) AS Previous_Available_Month

    FROM Sales_Trend
)

SELECT *
FROM Previous_Month_Trend
WHERE Sales_Trend = 'Declining'
  AND Previous_Month_Trend = 'Declining'
  AND Previous_Available_Month =
      Sales_Month - INTERVAL '1 month'
ORDER BY Customer, Sales_Month;
--Challenge #19 — Customer Revenue Contribution
--Business scenario
--An e-commerce company wants to understand which customers contribute the most to its 
--total completed sales revenue.
WITH Customer_Stats AS(
SELECT Customer,
       SUM(Sales) AS Customer_Completed_Sales
FROM ecommerce_sales
WHERE Status = 'Completed'
GROUP BY Customer
),
Company_Stats AS(
SELECT Customer,
       Customer_Completed_Sales,
       SUM(Customer_Completed_Sales) OVER()
	   AS Total_Completed_Sales
FROM Customer_Stats
)
SELECT Customer,
       Customer_Completed_Sales,
	   Total_Completed_Sales,
	   ROUND((Customer_Completed_Sales * 100.0)
	   /NULLIF(Total_Completed_Sales,0),2
	   ) AS Revenue_Contribution_Percentage
FROM Company_Stats
ORDER BY Customer_Completed_Sales DESC;
--🔥 Challenge #20 — Find customers responsible for 80% of revenue
--Business scenario
--Management wants to identify how many of its highest-revenue customers 
--generate approximately 80% of completed sales.
WITH Customer_Stats AS (
    SELECT
        Customer,
        SUM(Sales) AS Customer_Completed_Sales
    FROM ecommerce_sales
    WHERE Status = 'Completed'
    GROUP BY Customer
), 
Cumulative_Stats AS (
    SELECT
        Customer,
        Customer_Completed_Sales,
		SUM(Customer_Completed_Sales) OVER()
		AS Total_Completed_Sales,
        SUM(Customer_Completed_Sales) OVER (
            ORDER BY Customer_Completed_Sales DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
                     AND CURRENT ROW
        ) AS Cumulative_Sales
    FROM Customer_Stats
)
SELECT Customer,
       Customer_Completed_Sales,
	   Total_Completed_Sales,
	   Cumulative_Sales,
	   ROUND((Cumulative_Sales * 100.0)
	   /NULLIF(Total_Completed_Sales,0),2
	   ) AS Cumulative_Revenue_Contribution_Percentage
FROM Cumulative_Stats
ORDER BY Customer_Completed_Sales DESC;
--Challenge #20 — Step 9: Include the threshold-crossing customer

WITH Customer_Stats AS (
    SELECT
        Customer,
        SUM(Sales) AS Customer_Completed_Sales
    FROM ecommerce_sales
    WHERE Status = 'Completed'
    GROUP BY Customer
),

Cumulative_Stats AS (
    SELECT
        Customer,
        Customer_Completed_Sales,

        SUM(Customer_Completed_Sales) OVER (
            ORDER BY Customer_Completed_Sales DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
                     AND CURRENT ROW
        ) AS Cumulative_Sales,

        SUM(Customer_Completed_Sales) OVER ()
            AS Total_Completed_Sales
    FROM Customer_Stats
),

Percentage_Stats AS (
    SELECT
        *,
        ROUND(
            Cumulative_Sales * 100.0
            / NULLIF(Total_Completed_Sales, 0),
            2
        ) AS Cumulative_Revenue_Contribution_Percentage
    FROM Cumulative_Stats
),

Contribution_Stats AS (
    SELECT
        *,
        LAG(Cumulative_Revenue_Contribution_Percentage)
            OVER (
                ORDER BY Customer_Completed_Sales DESC
            ) AS Previous_Contribution_Percentage
    FROM Percentage_Stats
)

SELECT
    Customer,
    Customer_Completed_Sales,
    Cumulative_Sales,
    Total_Completed_Sales,
    Cumulative_Revenue_Contribution_Percentage
FROM Contribution_Stats
WHERE Cumulative_Revenue_Contribution_Percentage < 80
   OR (
       Cumulative_Revenue_Contribution_Percentage >= 80
       AND Previous_Contribution_Percentage < 80
   )
ORDER BY Customer_Completed_Sales DESC;
	   
       



















