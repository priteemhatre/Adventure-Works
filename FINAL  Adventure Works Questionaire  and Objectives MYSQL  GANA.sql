use adventureproject;
-- 1. Append/Union of Fact Internet sales and Fact internet sales new - SALES

/* We merged old and new internet sales datasets into a single fact table called SALES using UNION ALL
 to preserve all transactional records.*/
 
CREATE TABLE SALES AS
SELECT 
    ProductKey,
    OrderDateKey,
    DueDateKey,
    ShipDateKey,
    CustomerKey,
    PromotionKey,
    CurrencyKey,
    SalesTerritoryKey,
    SalesOrderNumber,
    SalesOrderLineNumber,
    RevisionNumber,
    OrderQuantity,
    UnitPrice,
    ExtendedAmount,
    UnitPriceDiscountPct,
    DiscountAmount,
    ProductStandardCost,
    TaxAmt,
    Freight,
    CarrierTrackingNumber,
    CustomerPONumber,
    OrderDate,
    DueDate,
    ShipDate
FROM fact_internet_sales_new

UNION ALL

SELECT 
    ProductKey,
    OrderDateKey,
    DueDateKey,
    ShipDateKey,
    CustomerKey,
    PromotionKey,
    CurrencyKey,
    SalesTerritoryKey,
    SalesOrderNumber,
    SalesOrderLineNumber,
    RevisionNumber,
    OrderQuantity,
    UnitPrice,
    ExtendedAmount,
    UnitPriceDiscountPct,
    DiscountAmount,
    ProductStandardCost,
    TaxAmt,
    Freight,
    CarrierTrackingNumber,
    CustomerPONumber,
    OrderDate,
    DueDate,
    ShipDate
FROM factinternetsales;

-- 2.MERGE PRODUCT TABLE ,PRODUCTCATEGORY TABLE AND PRODUCTSUBCATEGORYTABLE..NEW TABLE NAME PRODUCTMAIN
/*Alias 	Actual Table
p	        dimproduct
ps	        dimproductsubcategory
pc	        dimproductcategory
*/

 CREATE TABLE productmain AS
SELECT 
    p.ProductKey,  -- P. ALIAS SHORTNAME FOR DIMPRODUCT

    p.`Unit price`,
    p.ProductAlternateKey,
    p.ProductSubcategoryKey AS ProductSubcategoryKey_Product,

    p.EnglishProductName,
    p.SpanishProductName,
    p.FrenchProductName,

    p.StandardCost,
    p.FinishedGoodsFlag,
    p.Color,
    p.SafetyStockLevel,
    p.ReorderPoint,
    p.ListPrice,
    p.Size,
    p.SizeRange,
    p.Weight,
    p.DaysToManufacture,
    p.ProductLine,
    p.DealerPrice,
    p.Class,
    p.Style,
    p.ModelName,

    p.EnglishDescription,
    p.FrenchDescription,
    p.ChineseDescription,
    p.ArabicDescription,
    p.HebrewDescription,
    p.ThaiDescription,
    p.GermanDescription,
    p.JapaneseDescription,
    p.TurkishDescription,

    p.StartDate,
    p.EndDate,
    p.Status,

    ps.ProductSubcategoryKey AS ProductSubcategoryKey_Sub,
    ps.ProductSubcategoryAlternateKey,
    ps.EnglishProductSubcategoryName,
    ps.SpanishProductSubcategoryName,
    ps.FrenchProductSubcategoryName,

    pc.ProductCategoryKey,
    pc.ProductCategoryAlternateKey,
    pc.EnglishProductCategoryName,
    pc.SpanishProductCategoryName,
    pc.FrenchProductCategoryName

FROM dimproduct p   -- HERE WE MAKE DIMPRODUCT SHORT NAME AS P 

LEFT JOIN dimproductsubcategory ps 
    ON p.ProductSubcategoryKey = ps.ProductSubcategoryKey /*Take ALL rows from the left table (dimproduct)
                                                            Match rows from the right table (dimproductsubcategory)*/

LEFT JOIN dimproductcategory pc   -- DIMPRODUCTCATEGORY AS PC 
    ON ps.ProductCategoryKey = pc.ProductCategoryKey;
    
    /*We created a denormalized Product Dimension called PRODUCTMAIN
    to avoid multiple joins during reporting and improve analytical performance*/
    
    
    /*Star Schema Design
Central Fact Table sales
Connected Dimension Tables
1.productmain
2.dimcustomer
3.dimdate
4. dimsalesterritory
 

Foreign Keys: Foreign keys establish relationships

ProductKey → productmain.ProductKey
CustomerKey → dimcustomer.CustomerKey
OrderDateKey → dimdate.DateKey
ShipDateKey → dimdate.DateKey
DueDateKey → dimdate.DateKey
SalesTerritoryKey → dimsalesterritory.SalesTerritoryKey

CREATE FOREIGN KEY RELATIONSHIPS
PRODUCT to SALES

*/
ALTER TABLE sales
ADD CONSTRAINT fk_sales_product
FOREIGN KEY (ProductKey)
REFERENCES productmain(ProductKey);
/*[ productmain ]  <--- Parent Table (Contains master list of unique products)

         |
         | ProductKey (Primary Key)
         v
     [ sales ]     <--- Child Table 
           ProductKey (Foreign Key)*/

-- CUSTOMER to  SALES
ALTER TABLE sales
ADD CONSTRAINT fk_sales_customer
FOREIGN KEY (CustomerKey)
REFERENCES dimcustomer(CustomerKey);
/* [ dimcustomer ]  <--- Parent Table 


         |
         | CustomerKey (Primary Key)
         v
     [ sales ]       <--- Child Table 
           CustomerKey (Foreign Key)*/
           
-- DATE to SALES (ORDER DATE)
ALTER TABLE sales
ADD CONSTRAINT fk_sales_orderdate
FOREIGN KEY (OrderDateKey)
REFERENCES dimdate(DateKey);
-- DATE to SALES (DUE DATE)

ALTER TABLE sales
ADD CONSTRAINT fk_sales_duedate
FOREIGN KEY (DueDateKey)
REFERENCES dimdate(DateKey);

/* [ dimdate ]     <--- Parent Table (Master calendar dimension)



         |
         | DateKey (Primary Key)
         v
     [ sales ]       <--- Child Table 
           OrderDateKey (Foreign Key)*/

-- TERRITORY TO SALES
ALTER TABLE sales
ADD CONSTRAINT fk_sales_territory
FOREIGN KEY (SalesTerritoryKey)
REFERENCES dimsalesterritory(SalesTerritoryKey);
/*
[ dimsalesterritory ]  <--- Parent Table 



           |
           | SalesTerritoryKey (Primary Key)
           v
       [ sales ]          <--- Child Table 
             SalesTerritoryKey (Foreign Key)*/
   /*
   By running these four commands, you have successfully built the core structural links of a Star Schema.
Your database now treats the sales table as a central Fact Table surrounded by four Dimension Tables (dim).
   */          
-- TOTAL REVENUE ANS:29358677.22070

SELECT SUM(ExtendedAmount) AS TotalRevenue
FROM sales;
 -- Check orphan records (must be 0) 
 -- 1 PRODUCT CHECK it counts how many records in your sales table 
 -- contain a ProductKey that does not exist in your productmain table
 -- ANS:0
 SELECT COUNT(*)
FROM sales s
LEFT JOIN productmain p
ON s.ProductKey = p.ProductKey
WHERE p.ProductKey IS NULL;
-- 2 CUSTOMER check table
SELECT COUNT(*)
FROM sales s
LEFT JOIN dimcustomer c
ON s.CustomerKey = c.CustomerKey
WHERE c.CustomerKey IS NULL;
/*counting how many records in your sales table 
contain a CustomerKey that does not exist in your dimcustomer table.*/

-- 3. TERRITORY CHECK
SELECT COUNT(*)
FROM sales s
LEFT JOIN dimsalesterritory t
ON s.SalesTerritoryKey = t.SalesTerritoryKey
WHERE t.SalesTerritoryKey IS NULL;
/*   counting how many records in your sales table 
contain a SalesTerritoryKey that does not exist in your dimsalesterritory table.
ANS:0
*/
-- 4.DATE CHECK
SELECT COUNT(*)
FROM sales s
LEFT JOIN dimdate d
ON s.OrderDateKey = d.DateKey
WHERE d.DateKey IS NULL;
/*counting how many records in your sales table 
contain an OrderDateKey that does not exist in your dimdate table.
ANS:0
*/


-- Q: Lookup the Productname from the Productmain sheet to Sales sheet
SELECT 
    s.*,                      -- Pulls all columns from the sales table
    p.EnglishProductName AS ProductName -- Looks up and outputs the name from productmain
FROM sales s
INNER JOIN productmain p 
    ON s.ProductKey = p.ProductKey;





DESCRIBE productmain;
describe sales;
-- Lookup the Customerfullname from the dimcustomer  table to sales table

SELECT * FROM SALES;

SELECT 
    s.*, -- Pulls all transaction columns from your sales table
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerFullName -- Combines and looks up the name
FROM sales s
INNER JOIN dimcustomer c 
    ON s.CustomerKey = c.CustomerKey;
    
    
SELECT * FROM SALES;
-- LOOKUP and Unit Price from Product Table to Sales sheet.
SELECT 
    s.*, -- Pulls all columns from your sales table
    p.`Unit price` AS ProductUnitPrice -- Looks up the price from productmain
FROM sales s
INNER JOIN productmain p 
    ON s.ProductKey = p.ProductKey;
    
/* VIEW TOGETHER
1. Lookup the Productname from the Product sheet to Sales sheet,
2. Lookup the Customerfullname from the Customer Table and Unit Price from Product Table to Sales sheet.
*/
SELECT 
    s.*, -- Pulls all transaction columns from your sales table
    p.EnglishProductName AS ProductName, -- Lookup 1: Product Name
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerFullName, -- Lookup 2: Customer Full Name
    p.`Unit price` AS ProductUnitPrice -- Lookup 3: Unit Price
FROM sales s
INNER JOIN productmain p 
    ON s.ProductKey = p.ProductKey
INNER JOIN dimcustomer c 
    ON s.CustomerKey = c.CustomerKey;


SELECT * FROM SALES;

-- question no:3 year alterations
WITH derived_sales AS (
    SELECT 
        s.SalesOrderNumber,
        s.ExtendedAmount,
        -- Step 1: First create the Date Field from OrderDateKey
        STR_TO_DATE(s.OrderDateKey, '%Y%m%d') AS OrderDate
    FROM sales s
)
SELECT 
    SalesOrderNumber,
    OrderDate, -- Your newly created date field

    -- A. Year
    YEAR(OrderDate) AS Year,

    -- B. Monthno
    MONTH(OrderDate) AS MonthNo,

    -- C. Monthfullname
    MONTHNAME(OrderDate) AS MonthFullName,

    -- D. Quarter (Q1,Q2,Q3,Q4)
    CONCAT('Q', QUARTER(OrderDate)) AS Quarter,

    -- E. YearMonth (YYYY-MMM)
    DATE_FORMAT(OrderDate, '%Y-%b') AS YearMonth,

    -- F. Weekday Number (1=Monday ... 7=Sunday)
    WEEKDAY(OrderDate) + 1 AS WeekdayNo,

    -- G. Weekday Name
    DAYNAME(OrderDate) AS WeekdayName,

    -- H. Financial Month (April = 1 ... March = 12)
    CASE 
        WHEN MONTH(OrderDate) >= 4 THEN MONTH(OrderDate) - 3
        ELSE MONTH(OrderDate) + 9
    END AS FinancialMonth,

    -- I. Financial Quarter
    CASE 
        WHEN MONTH(OrderDate) BETWEEN 4 AND 6 THEN 'Q1'
        WHEN MONTH(OrderDate) BETWEEN 7 AND 9 THEN 'Q2'
        WHEN MONTH(OrderDate) BETWEEN 10 AND 12 THEN 'Q3'
        ELSE 'Q4'
    END AS FinancialQuarter,

    ExtendedAmount

FROM derived_sales;


-- view table for this question
CREATE OR REPLACE VIEW v_sales_date_calculations AS
SELECT 
    derived.SalesOrderNumber,
    derived.OrderDate, -- The newly created base date field

    -- A. Year
    YEAR(derived.OrderDate) AS Year,

    -- B. Monthno
    MONTH(derived.OrderDate) AS MonthNo,

    -- C. Monthfullname
    MONTHNAME(derived.OrderDate) AS MonthFullName,

    -- D. Quarter (Q1,Q2,Q3,Q4)
    CONCAT('Q', QUARTER(derived.OrderDate)) AS Quarter,

    -- E. YearMonth (YYYY-MMM)
    DATE_FORMAT(derived.OrderDate, '%Y-%b') AS YearMonth,

    -- F. Weekday Number (1 = Monday ... 7 = Sunday)
    WEEKDAY(derived.OrderDate) + 1 AS WeekdayNo,

    -- G. Weekday Name
    DAYNAME(derived.OrderDate) AS WeekdayName,

    -- H. Financial Month (April = 1 ... March = 12)
    CASE 
        WHEN MONTH(derived.OrderDate) >= 4 THEN MONTH(derived.OrderDate) - 3
        ELSE MONTH(derived.OrderDate) + 9
    END AS FinancialMonth,

    -- I. Financial Quarter
    CASE 
        WHEN MONTH(derived.OrderDate) BETWEEN 4 AND 6 THEN 'Q1'
        WHEN MONTH(derived.OrderDate) BETWEEN 7 AND 9 THEN 'Q2'
        WHEN MONTH(derived.OrderDate) BETWEEN 10 AND 12 THEN 'Q3'
        ELSE 'Q4'
    END AS FinancialQuarter,

    derived.ExtendedAmount

FROM (
    SELECT 
        s.SalesOrderNumber,
        s.ExtendedAmount,
        -- First create the base Date Field from OrderDateKey
        STR_TO_DATE(s.OrderDateKey, '%Y%m%d') AS OrderDate
    FROM sales s
) derived;
SELECT * FROM v_sales_date_calculations ;

-- Q: CALCULATE SALES AMOUNT USING COLUMNS UNIT PRICE ,ORDER QUANTITY,UNITDISCOUNT
-- TOTAL SALES : ANS:29358677.220705014
SELECT 
    SUM((OrderQuantity * UnitPrice) - DiscountAmount) AS TotalSalesAmount FROM sales;




-- TOTAL PRODUCTION COST  ANS:'17277793.57569827'

-- Total Cost = Unit Cost × Quantity
SELECT 
    SUM(ProductStandardCost * OrderQuantity) AS TotalCost
FROM sales;


-- total profit ANS:'12080883.645000728'

-- Profit = (UnitPrice × OrderQuantity × (1 − Discount)) − (ProductStandardCost × OrderQuantity)
SELECT 
    SUM(
        (s.UnitPrice * s.OrderQuantity * (1 - IFNULL(s.UnitPriceDiscountPct,0)/100))
        - (s.ProductStandardCost * s.OrderQuantity)
    ) AS TotalProfit
FROM sales s;

-- profit mergin ANS :'41.149277789943355'

-- Profit Margin % = (Total Profit / Total Sales) × 100
SELECT 
    CASE 
        WHEN SUM(s.UnitPrice * s.OrderQuantity * (1 - IFNULL(s.UnitPriceDiscountPct,0)/100)) = 0 
        THEN 0
        ELSE
        (
            SUM(
                (s.UnitPrice * s.OrderQuantity * (1 - IFNULL(s.UnitPriceDiscountPct,0)/100))
                - (s.ProductStandardCost * s.OrderQuantity)
            )
            /
            SUM(
                s.UnitPrice * s.OrderQuantity * (1 - IFNULL(s.UnitPriceDiscountPct,0)/100)
            )
        ) * 100
    END AS TotalProfitMarginPercent
FROM sales s;


-- total customers ANS:'18484'

SELECT 
    COUNT(DISTINCT CustomerKey) AS TotalCustomers
FROM sales;



 -- total order ANS:27659
    SELECT 
    COUNT(DISTINCT SalesOrderNumber) AS TotalOrders
FROM sales;


-- repeat orders
SELECT 
    CustomerKey,
    COUNT(DISTINCT SalesOrderNumber) AS TotalOrders
FROM sales
GROUP BY CustomerKey
HAVING COUNT(DISTINCT SalesOrderNumber) > 1
ORDER BY TotalOrders DESC;



-- repeating customers count ANS:6865
SELECT 
    COUNT(*) AS RepeatingCustomers
FROM (
    SELECT 
        CustomerKey
    FROM sales
    GROUP BY CustomerKey
    HAVING COUNT(DISTINCT SalesOrderNumber) > 1
) t;


-- repeat rate in % ANS:'37.14023'

-- Repeat Rate = (Repeat Customers / Total Customers) × 100
SELECT 
    (repeat_count * 100.0) / total_count AS RepeatRatePercent
FROM
(
    SELECT COUNT(*) AS repeat_count
    FROM (
        SELECT CustomerKey
        FROM sales
        GROUP BY CustomerKey
        HAVING COUNT(DISTINCT SalesOrderNumber) > 1
    ) r
) a
CROSS JOIN
(
    SELECT COUNT(DISTINCT CustomerKey) AS total_count
    FROM sales
) b;




-- AVERAGE ORDER PER CUSTOMER ANS:'1.4964'

-- Average Orders per Customer = Total Orders / Total Customers
SELECT 
    total_orders.total_orders_count / total_customers.customer_count AS AvgOrdersPerCustomer
FROM
(
    SELECT COUNT(DISTINCT SalesOrderNumber) AS total_orders_count
    FROM sales
) total_orders
CROSS JOIN
(
    SELECT COUNT(DISTINCT CustomerKey) AS customer_count
    FROM sales
) total_customers;






-- Low Profit Margin Products
SELECT 
    s.ProductKey,

    SUM(
        s.UnitPrice * s.OrderQuantity * (1 - IFNULL(s.UnitPriceDiscountPct,0)/100)
    ) AS TotalSales,

    SUM(
        (s.UnitPrice * s.OrderQuantity * (1 - IFNULL(s.UnitPriceDiscountPct,0)/100))
        - (s.ProductStandardCost * s.OrderQuantity)
    ) AS TotalProfit,

    (
        SUM(
            (s.UnitPrice * s.OrderQuantity * (1 - IFNULL(s.UnitPriceDiscountPct,0)/100))
            - (s.ProductStandardCost * s.OrderQuantity)
        )
        /
        NULLIF(SUM(
            s.UnitPrice * s.OrderQuantity * (1 - IFNULL(s.UnitPriceDiscountPct,0)/100)
        ),0)
    ) * 100 AS ProfitMarginPercent

FROM sales s
GROUP BY s.ProductKey
ORDER BY ProfitMarginPercent ASC
LIMIT 10;

-- PEAK SALES MONTH WITH YEAR
-- 1. MONTHLY SALAES AGGREGATE
SELECT 
    d.CalendarYear,
    d.MonthNumberOfYear,
    d.EnglishMonthName,
    SUM(s.ExtendedAmount) AS TotalSales
FROM sales s
JOIN dimdate d
    ON s.OrderDateKey = d.DateKey
GROUP BY 
    d.CalendarYear,
    d.MonthNumberOfYear,
    d.EnglishMonthName;
    -- PEAK SALES
    SELECT 
    CalendarYear,
    MonthNumberOfYear,
    EnglishMonthName,
    TotalSales
FROM (
    SELECT 
        d.CalendarYear,
        d.MonthNumberOfYear,
        d.EnglishMonthName,
        SUM(s.ExtendedAmount) AS TotalSales
    FROM sales s
    JOIN dimdate d
        ON s.OrderDateKey = d.DateKey
    GROUP BY 
        d.CalendarYear,
        d.MonthNumberOfYear,
        d.EnglishMonthName
) x
ORDER BY TotalSales DESC
LIMIT 1;
-- PEAK SALES AMOUNT WITH MONTH AND YEAR
SELECT 
    CalendarYear,
    MonthNumberOfYear,
    EnglishMonthName,
    TotalSales
FROM (
    SELECT 
        d.CalendarYear,
        d.MonthNumberOfYear,
        d.EnglishMonthName,
        SUM(s.ExtendedAmount) AS TotalSales
    FROM sales s
    JOIN dimdate d
        ON s.OrderDateKey = d.DateKey
    GROUP BY 
        d.CalendarYear,
        d.MonthNumberOfYear,
        d.EnglishMonthName
) x
ORDER BY TotalSales DESC
LIMIT 1;




-- REVENUE BY PRODUCT
SELECT 
    p.EnglishProductName,
    SUM(s.ExtendedAmount) AS Revenue
FROM sales s
JOIN productmain p ON s.ProductKey = p.ProductKey
GROUP BY p.EnglishProductName
ORDER BY Revenue DESC;




-- REVENUE BY TERRITORRY
SELECT 
    t.SalesTerritoryRegion,
    SUM(s.ExtendedAmount) AS Revenue
FROM sales s
JOIN dimsalesterritory t ON s.SalesTerritoryKey = t.SalesTerritoryKey
GROUP BY t.SalesTerritoryRegion
ORDER BY Revenue DESC;



-- MONTHLY TRENDS
SELECT 
    d.CalendarYear,
    d.EnglishMonthName,
    SUM(s.ExtendedAmount) AS Revenue
FROM sales s
JOIN dimdate d ON s.OrderDateKey = d.DateKey
GROUP BY d.CalendarYear, d.EnglishMonthName
ORDER BY d.CalendarYear;






    -- question 4 Sales Amount = UnitPrice × OrderQuantity × (1 − UnitDiscount)
    SELECT 
    ProductKey,
    OrderQuantity,
    UnitPrice,
    UnitPriceDiscountPct,

    (UnitPrice * OrderQuantity * 
        (1 - (UnitPriceDiscountPct / 100))
    ) AS SalesAmount
FROM sales;


-- 5. Calculate the Productioncost using the columns (Unit cost, Order quantity)
-- Production Cost = Unit Cost × Order Quantity
SELECT 
    ProductKey,
    OrderQuantity,
    ProductStandardCost AS UnitCost,

    (ProductStandardCost * OrderQuantity) AS ProductionCost
FROM sales;


-- 6.  Calculate the Profit. (Sales - ProductionCost)
-- Profit = Sales Amount − Production Cost
SELECT 
    ProductKey,
    OrderQuantity,
    UnitPrice,
    ProductStandardCost,
    UnitPriceDiscountPct,

    -- Sales Amount
    (UnitPrice * OrderQuantity * 
        (1 - IFNULL(UnitPriceDiscountPct, 0) / 100)
    ) AS SalesAmount,

    -- Production Cost
    -- (ProductStandardCost * OrderQuantity) AS ProductionCost,

    -- Profit
    (
        (UnitPrice * OrderQuantity * 
            (1 - IFNULL(UnitPriceDiscountPct, 0) / 100)
        )
        -
        (ProductStandardCost * OrderQuantity)
    ) AS Profit

FROM sales;



-- 7.monthwise sales table
SELECT 
    d.CalendarYear AS Year,
    d.MonthNumberOfYear AS MonthNo,
    d.EnglishMonthName AS MonthName,

    CONCAT(d.CalendarYear, '-', d.EnglishMonthName) AS YearMonth,

    SUM(s.ExtendedAmount) AS TotalSales

FROM sales s
JOIN dimdate d
    ON s.OrderDateKey = d.DateKey

GROUP BY 
    d.CalendarYear,
    d.MonthNumberOfYear,
    d.EnglishMonthName

ORDER BY 
    d.CalendarYear,
    d.MonthNumberOfYear;
    
    
    
    
    
    -- yearwise sales
    SELECT 
    d.CalendarYear AS Year,
    SUM(s.ExtendedAmount) AS TotalSales
FROM sales s
JOIN dimdate d
    ON s.OrderDateKey = d.DateKey
GROUP BY 
    d.CalendarYear
ORDER BY 
    d.CalendarYear;
    
    
    
    
    
    -- monthwise sales
    SELECT 
    d.CalendarYear AS Year,
    d.MonthNumberOfYear AS MonthNo,
    d.EnglishMonthName AS MonthName,

    SUM(s.ExtendedAmount) AS TotalSales

FROM sales s
JOIN dimdate d
    ON s.OrderDateKey = d.DateKey

GROUP BY 
    d.CalendarYear,
    d.MonthNumberOfYear,
    d.EnglishMonthName

ORDER BY 
    d.CalendarYear,
    d.MonthNumberOfYear;
    
    
    
    
    -- quarterwise sale
    SELECT 
    d.CalendarYear AS Year,
    CONCAT('Q', d.CalendarQuarter) AS Quarter,

    SUM(s.ExtendedAmount) AS TotalSales

FROM sales s
JOIN dimdate d
    ON s.OrderDateKey = d.DateKey

GROUP BY 
    d.CalendarYear,
    d.CalendarQuarter

ORDER BY 
    d.CalendarYear,
    d.CalendarQuarter;
    
    
    
    
    
    
    
    
    
    -- OBJECTIVES
    -- Analyze yearly sales trends to monitor business growth over time
    -- YEARLY SALES TREND ANALYSIS
    
    SELECT 
    d.CalendarYear AS Year,
    SUM(s.ExtendedAmount) AS TotalSales
FROM sales s
JOIN dimdate d
    ON s.OrderDateKey = d.DateKey
GROUP BY 
    d.CalendarYear
ORDER BY 
    d.CalendarYear;
   -- Compare sales contribution across different region groups
   SELECT 
    t.SalesTerritoryGroup,
    SUM(s.ExtendedAmount) AS TotalRevenue
FROM sales s
JOIN dimsalesterritory t
    ON s.SalesTerritoryKey = t.SalesTerritoryKey
GROUP BY t.SalesTerritoryGroup
ORDER BY TotalRevenue DESC;

-- Compare sales contribution across product categories
SELECT 
    p.EnglishProductCategoryName AS ProductCategory,
    SUM(s.ExtendedAmount) AS TotalRevenue
FROM sales s
JOIN productmain p
    ON s.ProductKey = p.ProductKey
GROUP BY p.EnglishProductCategoryName
ORDER BY TotalRevenue DESC;

-- Analyze customer distribution across regions to understand market presence
SELECT 
    t.SalesTerritoryGroup,
    COUNT(DISTINCT c.CustomerKey) AS TotalCustomers
FROM sales s
JOIN dimcustomer c
    ON s.CustomerKey = c.CustomerKey
JOIN dimsalesterritory t
    ON s.SalesTerritoryKey = t.SalesTerritoryKey
GROUP BY t.SalesTerritoryGroup
ORDER BY TotalCustomers DESC;

-- PAGE 2
-- Page 2: Time Series Analysis :
-- Analyze yearly, quarterly, and monthly sales trends
-- A.YEARLY SALES TREND
SELECT 
    d.CalendarYear AS Year,
    SUM(s.ExtendedAmount) AS TotalSales
FROM sales s
JOIN dimdate d
    ON s.OrderDateKey = d.DateKey
GROUP BY d.CalendarYear
ORDER BY d.CalendarYear;

-- QUATERLY SALES TREND
SELECT 
    d.CalendarYear AS Year,
    CONCAT('Q', d.CalendarQuarter) AS Quarter,
    SUM(s.ExtendedAmount) AS TotalSales
FROM sales s
JOIN dimdate d
    ON s.OrderDateKey = d.DateKey
GROUP BY 
    d.CalendarYear,
    d.CalendarQuarter
ORDER BY 
    d.CalendarYear,
    d.CalendarQuarter;
    
    -- MONTHLY SALES TREND ANALYSIS
    SELECT 
    d.CalendarYear AS Year,
    d.MonthNumberOfYear AS MonthNo,
    d.EnglishMonthName AS MonthName,
    SUM(s.ExtendedAmount) AS TotalSales
FROM sales s
JOIN dimdate d
    ON s.OrderDateKey = d.DateKey
GROUP BY 
    d.CalendarYear,
    d.MonthNumberOfYear,
    d.EnglishMonthName
ORDER BY 
    d.CalendarYear,
    d.MonthNumberOfYear;
      -- PEAK SALES MONTH IDENTIFICATION
      SELECT 
    CalendarYear,
    MonthNumberOfYear,
    EnglishMonthName,
    TotalSales
FROM (
    SELECT 
        d.CalendarYear,
        d.MonthNumberOfYear,
        d.EnglishMonthName,
        SUM(s.ExtendedAmount) AS TotalSales
    FROM sales s
    JOIN dimdate d
        ON s.OrderDateKey = d.DateKey
    GROUP BY 
        d.CalendarYear,
        d.MonthNumberOfYear,
        d.EnglishMonthName
) x
ORDER BY TotalSales DESC
LIMIT 1;

-- SALES DATE VIEW
CREATE VIEW vw_sales_date_intel AS
SELECT 
    s.*,

    STR_TO_DATE(d.FullDateAlternateKey, '%Y-%m-%d') AS OrderDate_Clean,

    YEAR(STR_TO_DATE(d.FullDateAlternateKey, '%Y-%m-%d')) AS Year,

    MONTH(STR_TO_DATE(d.FullDateAlternateKey, '%Y-%m-%d')) AS MonthNo,

    MONTHNAME(STR_TO_DATE(d.FullDateAlternateKey, '%Y-%m-%d')) AS MonthFullName,

    CONCAT('Q', QUARTER(STR_TO_DATE(d.FullDateAlternateKey, '%Y-%m-%d'))) AS Quarter,

    DATE_FORMAT(
        STR_TO_DATE(d.FullDateAlternateKey, '%Y-%m-%d'),
        '%Y-%b'
    ) AS YearMonth

FROM sales s
JOIN dimdate d
    ON s.OrderDateKey = d.DateKey;
    
     SELECT * FROM vw_sales_date_intel;
     
   -- 2.Identify seasonal patterns and peak sales periods
   
   -- 1. Monthly Seasonal Sales Pattern
   SELECT 
    d.CalendarYear,
    d.MonthNumberOfYear,
    d.EnglishMonthName,
    SUM(s.ExtendedAmount) AS TotalSales
FROM sales s
JOIN dimdate d
    ON s.OrderDateKey = d.DateKey
GROUP BY 
    d.CalendarYear,
    d.MonthNumberOfYear,
    d.EnglishMonthName
ORDER BY 
    d.CalendarYear,
    d.MonthNumberOfYear;
    -- 2. Quarterly Seasonal Analysis
    
    SELECT 
    d.CalendarYear AS Year,
    CONCAT('Q', d.CalendarQuarter) AS Quarter,
    SUM(s.ExtendedAmount) AS TotalSales
FROM sales s
JOIN dimdate d
    ON s.OrderDateKey = d.DateKey
GROUP BY 
    d.CalendarYear,
    d.CalendarQuarter
ORDER BY 
    d.CalendarYear,
    d.CalendarQuarter;
    
    -- 3. Peak Sales Month Detection
    SELECT 
    CalendarYear,
    MonthNumberOfYear,
    EnglishMonthName,
    TotalSales
FROM (
    SELECT 
        d.CalendarYear,
        d.MonthNumberOfYear,
        d.EnglishMonthName,
        SUM(s.ExtendedAmount) AS TotalSales
    FROM sales s
    JOIN dimdate d
        ON s.OrderDateKey = d.DateKey
    GROUP BY 
        d.CalendarYear,
        d.MonthNumberOfYear,
        d.EnglishMonthName
) x
ORDER BY TotalSales DESC
LIMIT 1;

-- 3.
-- . Yearly Sales, Cost & Profit Analysis
SELECT 
    d.CalendarYear AS Year,

    -- Total Sales
    SUM(
        s.UnitPrice * s.OrderQuantity * 
        (1 - IFNULL(s.UnitPriceDiscountPct, 0) / 100)
    ) AS TotalSales,

    -- Total Production Cost
    SUM(
        s.ProductStandardCost * s.OrderQuantity
    ) AS TotalProductionCost,

    -- Total Profit
    SUM(
        (
            s.UnitPrice * s.OrderQuantity *
            (1 - IFNULL(s.UnitPriceDiscountPct, 0) / 100)
        )
        -
        (
            s.ProductStandardCost * s.OrderQuantity
        )
    ) AS TotalProfit

FROM sales s

JOIN dimdate d
    ON s.OrderDateKey = d.DateKey

GROUP BY d.CalendarYear

ORDER BY d.CalendarYear;

-- Monitor overall business growth and performance changes

-- Yearly Revenue Growth Analysis

SELECT 
    d.CalendarYear AS Year,
    SUM(s.ExtendedAmount) AS TotalRevenue
FROM sales s
JOIN dimdate d
    ON s.OrderDateKey = d.DateKey
GROUP BY d.CalendarYear
ORDER BY d.CalendarYear;

-- 2. Yearly Profit Trend Analysis

SELECT 
    d.CalendarYear AS Year,

    SUM(
        (
            s.UnitPrice * s.OrderQuantity *
            (1 - IFNULL(s.UnitPriceDiscountPct,0)/100)
        )
        -
        (
            s.ProductStandardCost * s.OrderQuantity
        )
    ) AS TotalProfit

FROM sales s

JOIN dimdate d
    ON s.OrderDateKey = d.DateKey

GROUP BY d.CalendarYear

ORDER BY d.CalendarYear;


-- Page 3: Customer Analysis:
--  Analyze customer distribution across regions and countries


-- Customer Distribution by Region

SELECT 
    t.SalesTerritoryRegion,
    COUNT(DISTINCT c.CustomerKey) AS TotalCustomers
FROM dimcustomer c

JOIN sales s
    ON c.CustomerKey = s.CustomerKey

JOIN dimsalesterritory t
    ON s.SalesTerritoryKey = t.SalesTerritoryKey

GROUP BY t.SalesTerritoryRegion

ORDER BY TotalCustomers DESC;

-- 2. Customer Distribution by Country

SELECT 
    t.SalesTerritoryCountry,
    COUNT(DISTINCT c.CustomerKey) AS TotalCustomers
FROM dimcustomer c

JOIN sales s
    ON c.CustomerKey = s.CustomerKey

JOIN dimsalesterritory t
    ON s.SalesTerritoryKey = t.SalesTerritoryKey

GROUP BY t.SalesTerritoryCountry

ORDER BY TotalCustomers DESC;

-- Identify repeat customers and customer retention trends
-- 1. Identify Repeat Customers

SELECT 
    CustomerKey,
    COUNT(DISTINCT SalesOrderNumber) AS TotalOrders
FROM sales
GROUP BY CustomerKey
HAVING COUNT(DISTINCT SalesOrderNumber) > 1
ORDER BY TotalOrders DESC;

-- 2. Count of Repeat Customers
SELECT 
    COUNT(*) AS RepeatingCustomers
FROM (
    SELECT CustomerKey
    FROM sales
    GROUP BY CustomerKey
    HAVING COUNT(DISTINCT SalesOrderNumber) > 1
) t;


-- 3. Customer Retention Rate %

SELECT 
    (repeat_count * 100.0) / total_count AS RepeatRatePercent
FROM
(
    SELECT COUNT(*) AS repeat_count
    FROM (
        SELECT CustomerKey
        FROM sales
        GROUP BY CustomerKey
        HAVING COUNT(DISTINCT SalesOrderNumber) > 1
    ) r
) a
CROSS JOIN
(
    SELECT COUNT(DISTINCT CustomerKey) AS total_count
    FROM sales
) b;

-- Identify top customers based on sales
SELECT 
    s.CustomerKey,

    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,

    SUM(s.ExtendedAmount) AS TotalSales

FROM sales s

JOIN dimcustomer c
    ON s.CustomerKey = c.CustomerKey

GROUP BY 
    s.CustomerKey,
    c.FirstName,
    c.LastName

ORDER BY TotalSales DESC

LIMIT 10;

-- 2. Top Customers with Order Count
SELECT 
    s.CustomerKey,

    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,

    COUNT(DISTINCT s.SalesOrderNumber) AS TotalOrders,

    SUM(s.ExtendedAmount) AS TotalSales

FROM sales s

JOIN dimcustomer c
    ON s.CustomerKey = c.CustomerKey

GROUP BY 
    s.CustomerKey,
    c.FirstName,
    c.LastName

ORDER BY TotalSales DESC

LIMIT 10;

-- 4.Analyze customer purchasing behavior across different markets
   
   
   -- 1. Customer Purchase Behavior by Region
   SELECT 
    t.SalesTerritoryRegion,

    COUNT(DISTINCT s.CustomerKey) AS TotalCustomers,

    COUNT(DISTINCT s.SalesOrderNumber) AS TotalOrders,

    SUM(s.ExtendedAmount) AS TotalRevenue,

    AVG(s.ExtendedAmount) AS AvgOrderValue

FROM sales s

JOIN dimsalesterritory t
    ON s.SalesTerritoryKey = t.SalesTerritoryKey

GROUP BY t.SalesTerritoryRegion

ORDER BY TotalRevenue DESC;

-- 2. Customer Purchasing Behavior by Country
SELECT 
    t.SalesTerritoryCountry,

    COUNT(DISTINCT s.CustomerKey) AS TotalCustomers,

    COUNT(DISTINCT s.SalesOrderNumber) AS TotalOrders,

    SUM(s.ExtendedAmount) AS TotalRevenue,

    AVG(s.ExtendedAmount) AS AvgOrderValue

FROM sales s

JOIN dimsalesterritory t
    ON s.SalesTerritoryKey = t.SalesTerritoryKey

GROUP BY t.SalesTerritoryCountry

ORDER BY TotalRevenue DESC;

-- Page 4: Product & Regional Analysis
-- 9. Analyze sales performance by product category and subcategory

-- 1. Sales by Product Category
SELECT 
    p.EnglishProductCategoryName AS Category,
    SUM(s.ExtendedAmount) AS TotalSales
FROM sales s
JOIN productmain p
    ON s.ProductKey = p.ProductKey
GROUP BY p.EnglishProductCategoryName
ORDER BY TotalSales DESC;

-- 2. Sales by Product Subcategory
SELECT 
    p.EnglishProductSubcategoryName AS SubCategory,
    SUM(s.ExtendedAmount) AS TotalSales
FROM sales s
JOIN productmain p
    ON s.ProductKey = p.ProductKey
GROUP BY p.EnglishProductSubcategoryName
ORDER BY TotalSales DESC;

-- 3. Profit by Product Category
SELECT 
    p.EnglishProductCategoryName AS Category,

    SUM(
        (s.UnitPrice * s.OrderQuantity)
        - (s.ProductStandardCost * s.OrderQuantity)
    ) AS Profit

FROM sales s
JOIN productmain p
    ON s.ProductKey = p.ProductKey

GROUP BY p.EnglishProductCategoryName
ORDER BY Profit DESC;

-- 4. Top Selling Products within Categories
SELECT 
    p.EnglishProductCategoryName AS Category,
    p.EnglishProductName AS Product,
    SUM(s.ExtendedAmount) AS Revenue

FROM sales s
JOIN productmain p
    ON s.ProductKey = p.ProductKey

GROUP BY 
    p.EnglishProductCategoryName,
    p.EnglishProductName

ORDER BY Revenue DESC
LIMIT 10;

-- 5. top low-selling products in ascending order
SELECT 
    p.EnglishProductName AS ProductName,
    SUM(s.ExtendedAmount) AS TotalSales

FROM sales s
JOIN productmain p
    ON s.ProductKey = p.ProductKey

GROUP BY p.EnglishProductName

ORDER BY TotalSales ASC

LIMIT 10;


-- 10. Identify top-selling and high-profit products
-- TOP SELLING PRODUCTS
SELECT 
    p.EnglishProductName AS ProductName,

    SUM(s.ExtendedAmount) AS TotalSales

FROM sales s
JOIN productmain p
    ON s.ProductKey = p.ProductKey

GROUP BY p.EnglishProductName

ORDER BY TotalSales DESC

LIMIT 10;
-- 2. High-Profit Products

SELECT 
    p.EnglishProductName AS ProductName,

    SUM(
        (s.UnitPrice * s.OrderQuantity)
        - (s.ProductStandardCost * s.OrderQuantity)
    ) AS TotalProfit

FROM sales s
JOIN productmain p
    ON s.ProductKey = p.ProductKey

GROUP BY p.EnglishProductName

ORDER BY TotalProfit DESC

LIMIT 10;

-- 3. Products with High Sales but Low Profit
SELECT 
    p.EnglishProductName AS ProductName,

    SUM(s.ExtendedAmount) AS TotalSales,

    SUM(
        (s.UnitPrice * s.OrderQuantity)
        - (s.ProductStandardCost * s.OrderQuantity)
    ) AS TotalProfit

FROM sales s
JOIN productmain p
    ON s.ProductKey = p.ProductKey

GROUP BY p.EnglishProductName

ORDER BY TotalSales DESC

LIMIT 10;

-- 11. Detect low-profit or loss-making products for cost reduction
-- Low-Profit / Loss-Making Products
SELECT 
    p.EnglishProductName AS ProductName,

    SUM(s.ExtendedAmount) AS TotalSales,

    SUM(
        (s.UnitPrice * s.OrderQuantity)
        - (s.ProductStandardCost * s.OrderQuantity)
    ) AS TotalProfit,

    (
        SUM(
            (s.UnitPrice * s.OrderQuantity)
            - (s.ProductStandardCost * s.OrderQuantity)
        )
        /
        NULLIF(SUM(s.ExtendedAmount), 0)
    ) * 100 AS ProfitMarginPercent

FROM sales s
JOIN productmain p
    ON s.ProductKey = p.ProductKey

GROUP BY p.EnglishProductName

ORDER BY TotalProfit ASC

LIMIT 10;
/* Above analysis identifies products with low profitability or losses by comparing sales revenue against production costs.
-- It helps the business reduce operational costs, 
-- improve pricing strategy, and focus on more profitable products.*/


-- 12. Compare regional sales and profit performance to identify top-performing markets
-- Regional Sales and Profit Analysis
SELECT 
    t.SalesTerritoryRegion AS Region,

    SUM(s.ExtendedAmount) AS TotalSales,

    SUM(
        (s.UnitPrice * s.OrderQuantity)
        - (s.ProductStandardCost * s.OrderQuantity)
    ) AS TotalProfit,

    (
        SUM(
            (s.UnitPrice * s.OrderQuantity)
            - (s.ProductStandardCost * s.OrderQuantity)
        )
        /
        NULLIF(SUM(s.ExtendedAmount), 0)
    ) * 100 AS ProfitMarginPercent

FROM sales s
JOIN dimsalesterritory t
    ON s.SalesTerritoryKey = t.SalesTerritoryKey

GROUP BY t.SalesTerritoryRegion

ORDER BY TotalSales DESC;

/*
Above analysis compares sales revenue and profitability across sales territories
 to identify the strongest and weakest performing markets. 
It helps management optimize regional strategies, improve profitability, and prioritize high-growth territories.
*/

