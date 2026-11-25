
USE walmart_sales_analysis;

-- =========================================
-- WALMART ADVANCED BUSINESS ANALYSIS
-- =========================================

-- 1. Store performance ranking
-- Window function: DENSE_RANK

SELECT
    Store,
    Type,
    SUM(Weekly_Sales) AS total_sales,
    DENSE_RANK() OVER (
        ORDER BY SUM(Weekly_Sales) DESC
    ) AS store_rank
FROM walmart_analysis
GROUP BY Store, Type;


-- 2. Department revenue contribution
-- CTE and window function

WITH department_sales AS (
    SELECT
        Dept,
        SUM(Weekly_Sales) AS total_sales
    FROM walmart_analysis
    GROUP BY Dept
)
SELECT
    Dept,
    total_sales,
    ROUND(
        total_sales * 100 /
        SUM(total_sales) OVER (), 2
    ) AS revenue_percentage
FROM department_sales
ORDER BY total_sales DESC;


-- 3. Month-over-month sales growth
-- CTE and LAG function

WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(`Date`, '%Y-%m') AS sales_month,
        SUM(Weekly_Sales) AS total_sales
    FROM walmart_analysis
    GROUP BY DATE_FORMAT(`Date`, '%Y-%m')
),
previous_sales AS (
    SELECT
        sales_month,
        total_sales,
        LAG(total_sales) OVER (
            ORDER BY sales_month
        ) AS previous_month_sales
    FROM monthly_sales
)
SELECT
    sales_month,
    total_sales,
    previous_month_sales,
    ROUND(
        (total_sales - previous_month_sales)
        * 100 / NULLIF(previous_month_sales, 0),
        2
    ) AS growth_percentage
FROM previous_sales
ORDER BY sales_month;


-- 4. Cumulative monthly revenue

WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(`Date`, '%Y-%m') AS sales_month,
        SUM(Weekly_Sales) AS total_sales
    FROM walmart_analysis
    GROUP BY DATE_FORMAT(`Date`, '%Y-%m')
)
SELECT
    sales_month,
    total_sales,
    SUM(total_sales) OVER (
        ORDER BY sales_month
        ROWS BETWEEN UNBOUNDED PRECEDING
        AND CURRENT ROW
    ) AS cumulative_sales
FROM monthly_sales;


-- 5. Store performance relative to size

SELECT
    Store,
    Type,
    Size,
    SUM(Weekly_Sales) AS total_sales,
    ROUND(
        SUM(Weekly_Sales) / NULLIF(Size, 0), 2
    ) AS sales_per_size_unit
FROM walmart_analysis
GROUP BY Store, Type, Size
ORDER BY sales_per_size_unit DESC;


-- 6. Top 3 departments within each store type

WITH department_sales AS (
    SELECT
        Type,
        Dept,
        SUM(Weekly_Sales) AS total_sales
    FROM walmart_analysis
    GROUP BY Type, Dept
),
ranked_departments AS (
    SELECT
        Type,
        Dept,
        total_sales,
        DENSE_RANK() OVER (
            PARTITION BY Type
            ORDER BY total_sales DESC
        ) AS department_rank
    FROM department_sales
)
SELECT *
FROM ranked_departments
WHERE department_rank <= 3
ORDER BY Type, department_rank;


-- 7. Comparable-period year-over-year growth
-- Compare February through September

WITH annual_sales AS (
    SELECT
        YEAR(`Date`) AS sales_year,
        SUM(Weekly_Sales) AS total_sales
    FROM walmart_analysis
    WHERE MONTH(`Date`) BETWEEN 2 AND 9
    GROUP BY YEAR(`Date`)
),
previous_year AS (
    SELECT
        sales_year,
        total_sales,
        LAG(total_sales) OVER (
            ORDER BY sales_year
        ) AS previous_year_sales
    FROM annual_sales
)
SELECT
    sales_year,
    total_sales,
    previous_year_sales,
    ROUND(
        (total_sales - previous_year_sales)
        * 100 / NULLIF(previous_year_sales, 0),
        2
    ) AS yoy_growth_percentage
FROM previous_year
ORDER BY sales_year;
