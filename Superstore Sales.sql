-- Create the 'superstore' database
CREATE DATABASE superstore;

ALTER DATABASE superstore CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Use the new 'superstore' database
USE superstore;

-- Create the 'customers' table
CREATE TABLE customers (
    CustomerID VARCHAR(50) PRIMARY KEY,
    CustomerName VARCHAR(100),
    Segment VARCHAR(50),
    Country VARCHAR(50),
    City VARCHAR(50),
    State VARCHAR(50),
    PostalCode VARCHAR(20),
    RegionID VARCHAR(50)
);

-- Create the 'products' table
CREATE TABLE products (
    ProductID VARCHAR(50) PRIMARY KEY,
    ProductName VARCHAR(100),
    Category VARCHAR(50),
    SubCategory VARCHAR(50)
);

-- Create the 'orders' table
CREATE TABLE orders (
    OrderID VARCHAR(50) PRIMARY KEY,
    OrderDate DATE,
    ShipDate DATE,
    ShipMode VARCHAR(50),
    CustomerID VARCHAR(50),
    ProductID VARCHAR(50),
    Sales DECIMAL(10, 2),
    Quantity INT,
    Discount DECIMAL(5, 2),
    Profit DECIMAL(10, 2),
    FOREIGN KEY (CustomerID) REFERENCES customers(CustomerID),
    FOREIGN KEY (ProductID) REFERENCES products(ProductID)
);

-- Create the 'regions' table
CREATE TABLE regions (
    RegionID VARCHAR(50) PRIMARY KEY,
    RegionName VARCHAR(50)
);

SHOW VARIABLES LIKE 'secure_file_priv';

-- Import data into 'customers' table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/customer.csv' 
INTO TABLE customers 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS 
(CustomerID, CustomerName, Segment, Country, City, State, PostalCode, RegionID);

select * from superstore.customers;

ALTER TABLE products MODIFY COLUMN ProductName VARCHAR(500);

-- Import data into 'products' table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/product.csv' 
INTO TABLE products 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS 
(ProductID, ProductName, Category, SubCategory);

SELECT * FROM superstore.orders;
-- Import data into 'orders' table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order.csv' 
INTO TABLE orders 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS 
(OrderID, OrderDate, ShipDate, ShipMode, CustomerID, ProductID, Sales, Quantity, Discount, Profit);

-- Import data into 'regions' table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/region.csv' 
INTO TABLE regions 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS 
(RegionID, RegionName);

-- Sales and Profit by Region and Category
SELECT 
    r.RegionName, 
    p.Category, 
    SUM(o.Sales) AS Total_Sales, 
    SUM(o.Profit) AS Total_Profit
FROM orders o
JOIN customers c ON o.CustomerID = c.CustomerID
JOIN products p ON o.ProductID = p.ProductID
JOIN regions r ON c.RegionID = r.RegionID
GROUP BY r.RegionName, p.Category
ORDER BY Total_Profit DESC;

-- Monthly sales and profit
SELECT 
    DATE_FORMAT(o.OrderDate, '%Y-%m') AS Month, 
    SUM(o.Sales) AS Monthly_Sales, 
    SUM(o.Profit) AS Monthly_Profit
FROM orders o
GROUP BY Month
ORDER BY Month;

-- Top 5 Customers by Sales
SELECT 
    c.CustomerName, 
    SUM(o.Sales) AS Total_Sales
FROM orders o
JOIN customers c ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerName
ORDER BY Total_Sales DESC
LIMIT 10;

-- Profit Margin by Product Category (CTE)
WITH Profit_Margin_CTE AS (
    SELECT 
        p.Category, 
        SUM(o.Profit) AS Total_Profit, 
        SUM(o.Sales) AS Total_Sales
    FROM orders o
    JOIN products p ON o.ProductID = p.ProductID
    GROUP BY p.Category
)
SELECT 
    Category, 
    Total_Profit, 
    Total_Sales, 
    (Total_Profit / Total_Sales) * 100 AS Profit_Margin_Percentage
FROM Profit_Margin_CTE
ORDER BY Profit_Margin_Percentage DESC;

-- Stored Procedure for Sales Trends
DELIMITER $$

CREATE PROCEDURE GetSalesTrends()
BEGIN
    SELECT 
        DATE_FORMAT(OrderDate, '%Y-%m') AS Month, 
        SUM(Sales) AS Total_Sales, 
        SUM(Profit) AS Total_Profit
    FROM orders
    GROUP BY Month
    ORDER BY Month;
END$$

DELIMITER ;

CALL GetSalesTrends();

-- Customer Lifetime Value (CLV) Analysis
SELECT 
    c.CustomerName, 
    SUM(o.Sales) AS Lifetime_Value
FROM orders o
JOIN customers c ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerName
ORDER BY Lifetime_Value DESC;

-- Churn Prediction Insight: Customers with No Orders in the Last 6 Months
SELECT 
    c.CustomerName, 
    MAX(o.OrderDate) AS Last_Order_Date
FROM orders o
JOIN customers c ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerName
HAVING MAX(o.OrderDate) < DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
ORDER BY Last_Order_Date ASC;

-- Top 5 products by Profit
SELECT 
    p.ProductName, 
    SUM(o.Profit) AS Total_Profit
FROM orders o
JOIN products p ON o.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY Total_Profit DESC
LIMIT 5;


-- Average Order Value (AOV) by Customer Segment
SELECT 
    c.Segment, 
    AVG(o.Sales) AS Avg_Order_Value
FROM orders o
JOIN customers c ON o.CustomerID = c.CustomerID
GROUP BY c.Segment
ORDER BY Avg_Order_Value DESC;

-- Top Shipping modes
SELECT 
    o.ShipMode, 
    SUM(o.Sales) AS Total_Sales, 
    SUM(o.Profit) AS Total_Profit
FROM orders o
GROUP BY o.ShipMode
ORDER BY Total_Profit DESC;


-- Avg Shipping Time by Region
SELECT 
    r.RegionName, 
    AVG(DATEDIFF(o.ShipDate, o.OrderDate)) AS Avg_Shipping_Time
FROM orders o
JOIN customers c ON o.CustomerID = c.CustomerID
JOIN regions r ON c.RegionID = r.RegionID
GROUP BY r.RegionName
ORDER BY Avg_Shipping_Time;

-- Revenue growth Rate over Time
SELECT 
    DATE_FORMAT(OrderDate, '%Y-%m') AS Month, 
    SUM(Sales) AS Monthly_Sales, 
    (SUM(Sales) - LAG(SUM(Sales), 1) OVER (ORDER BY DATE_FORMAT(OrderDate, '%Y-%m'))) / LAG(SUM(Sales), 1) OVER (ORDER BY DATE_FORMAT(OrderDate, '%Y-%m')) * 100 AS Growth_Rate
FROM orders
GROUP BY Month
ORDER BY Month;

-- Customer Retention Rate
WITH Monthly_Customers AS (
    SELECT 
        CustomerID, 
        DATE_FORMAT(OrderDate, '%Y-%m') AS Month
    FROM orders
    GROUP BY CustomerID, Month
)
SELECT 
    Month, 
    COUNT(DISTINCT CustomerID) AS Total_Customers, 
    COUNT(DISTINCT CASE WHEN EXISTS (
        SELECT 1 FROM Monthly_Customers mc2 
        WHERE mc2.CustomerID = mc.CustomerID 
        AND mc2.Month = DATE_FORMAT(DATE_SUB(STR_TO_DATE(CONCAT(Month, '-01'), '%Y-%m-%d'), INTERVAL 1 MONTH), '%Y-%m')
    ) THEN mc.CustomerID END) AS Returning_Customers,
    (COUNT(DISTINCT CASE WHEN EXISTS (
        SELECT 1 FROM Monthly_Customers mc2 
        WHERE mc2.CustomerID = mc.CustomerID 
        AND mc2.Month = DATE_FORMAT(DATE_SUB(STR_TO_DATE(CONCAT(Month, '-01'), '%Y-%m-%d'), INTERVAL 1 MONTH), '%Y-%m')
    ) THEN mc.CustomerID END) / COUNT(DISTINCT CustomerID)) * 100 AS Retention_Rate
FROM Monthly_Customers mc
GROUP BY Month;


