
USE walmart_sales_analysis;

-- =========================================
-- WALMART BUSINESS ANALYSIS
-- PART 1: SALES PERFORMANCE
-- =========================================

-- 1. Overall sales KPIs

SELECT
    SUM(Weekly_Sales) AS total_sales,
    ROUND(AVG(Weekly_Sales), 2) AS average_weekly_sales,
    COUNT(DISTINCT Store) AS total_stores,
    COUNT(DISTINCT Dept) AS total_departments
FROM walmart_analysis;


-- 2. Sales performance by store type

SELECT
    Type AS store_type,
    COUNT(DISTINCT Store) AS number_of_stores,
    SUM(Weekly_Sales) AS total_sales,
    ROUND(AVG(Weekly_Sales), 2) AS average_sales,
    ROUND(
        SUM(Weekly_Sales) * 100 /
        (SELECT SUM(Weekly_Sales)
         FROM walmart_analysis), 2
    ) AS sales_percentage
FROM walmart_analysis
GROUP BY Type
ORDER BY total_sales DESC;


-- 3. Top 10 performing stores

SELECT
    Store,
    Type,
    SUM(Weekly_Sales) AS total_sales
FROM walmart_analysis
GROUP BY Store, Type
ORDER BY total_sales DESC
LIMIT 10;


-- 4. Top 10 performing departments

SELECT
    Dept,
    SUM(Weekly_Sales) AS total_sales
FROM walmart_analysis
GROUP BY Dept
ORDER BY total_sales DESC
LIMIT 10;


-- 5. Holiday vs non-holiday sales

SELECT
    CASE
        WHEN IsHoliday = 'TRUE' THEN 'Holiday'
        ELSE 'Non-Holiday'
    END AS week_type,
    COUNT(*) AS total_records,
    SUM(Weekly_Sales) AS total_sales,
    ROUND(AVG(Weekly_Sales), 2) AS average_sales
FROM walmart_analysis
GROUP BY week_type;


-- 6. Monthly sales trends

SELECT
    YEAR(`Date`) AS sales_year,
    MONTH(`Date`) AS sales_month,
    SUM(Weekly_Sales) AS total_sales
FROM walmart_analysis
GROUP BY YEAR(`Date`), MONTH(`Date`)
ORDER BY sales_year, sales_month;


-- 7. Annual sales performance

SELECT
    YEAR(`Date`) AS sales_year,
    COUNT(DISTINCT `Date`) AS weeks_covered,
    SUM(Weekly_Sales) AS total_sales,
    ROUND(AVG(Weekly_Sales), 2) AS average_sales
FROM walmart_analysis
GROUP BY YEAR(`Date`)
ORDER BY sales_year;
