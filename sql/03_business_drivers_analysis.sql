
USE walmart_sales_analysis;

-- =========================================
-- WALMART BUSINESS DRIVERS ANALYSIS
-- =========================================

-- 1. Holiday sales performance by store type

SELECT
    Type AS store_type,
    IsHoliday,
    COUNT(*) AS total_records,
    SUM(Weekly_Sales) AS total_sales,
    ROUND(AVG(Weekly_Sales), 2) AS average_sales
FROM walmart_analysis
GROUP BY Type, IsHoliday
ORDER BY Type, IsHoliday;


-- 2. Holiday sales uplift by store type

WITH holiday_analysis AS (
    SELECT
        Type,
        AVG(CASE WHEN IsHoliday = 'TRUE'
            THEN Weekly_Sales END) AS holiday_avg,
        AVG(CASE WHEN IsHoliday = 'FALSE'
            THEN Weekly_Sales END) AS non_holiday_avg
    FROM walmart_analysis
    GROUP BY Type
)
SELECT
    Type,
    ROUND(holiday_avg, 2) AS holiday_avg,
    ROUND(non_holiday_avg, 2) AS non_holiday_avg,
    ROUND(
        (holiday_avg - non_holiday_avg) * 100
        / NULLIF(non_holiday_avg, 0), 2
    ) AS holiday_uplift_percentage
FROM holiday_analysis;


-- 3. Promotional markdown analysis
-- Aggregate sales at store-week level first

WITH weekly_sales AS (
    SELECT
        Store,
        `Date`,
        SUM(Weekly_Sales) AS total_sales
    FROM walmart_sales
    GROUP BY Store, `Date`
)
SELECT
    CASE
        WHEN COALESCE(f.MarkDown1, 0)
           + COALESCE(f.MarkDown2, 0)
           + COALESCE(f.MarkDown3, 0)
           + COALESCE(f.MarkDown4, 0)
           + COALESCE(f.MarkDown5, 0) > 0
        THEN 'Positive Recorded Markdown'
        ELSE 'No Positive Recorded Markdown'
    END AS promotion_status,
    COUNT(*) AS store_weeks,
    ROUND(AVG(w.total_sales), 2) AS average_sales
FROM weekly_sales w
JOIN features f
    ON w.Store = f.Store
    AND w.`Date` = f.`Date`
WHERE w.`Date` >= '2011-11-01'
  AND COALESCE(
      f.MarkDown1, f.MarkDown2, f.MarkDown3,
      f.MarkDown4, f.MarkDown5
  ) IS NOT NULL
GROUP BY promotion_status;


-- 4. Temperature and sales performance

WITH weekly_sales AS (
    SELECT
        Store,
        `Date`,
        SUM(Weekly_Sales) AS total_sales
    FROM walmart_sales
    GROUP BY Store, `Date`
)
SELECT
    CASE
        WHEN f.Temperature < 40 THEN 'Cold'
        WHEN f.Temperature < 70 THEN 'Moderate'
        ELSE 'Warm'
    END AS temperature_category,
    COUNT(*) AS store_weeks,
    ROUND(AVG(w.total_sales), 2) AS average_sales
FROM weekly_sales w
JOIN features f
    ON w.Store = f.Store
    AND w.`Date` = f.`Date`
WHERE f.Temperature IS NOT NULL
GROUP BY temperature_category;


-- 5. Economic factors and monthly sales

SELECT
    DATE_FORMAT(w.`Date`, '%Y-%m') AS sales_month,
    SUM(w.total_sales) AS total_sales,
    ROUND(AVG(f.Fuel_Price), 3) AS average_fuel_price,
    ROUND(AVG(f.CPI), 2) AS average_cpi,
    ROUND(AVG(f.Unemployment), 2) AS average_unemployment
FROM (
    SELECT
        Store,
        `Date`,
        SUM(Weekly_Sales) AS total_sales
    FROM walmart_sales
    GROUP BY Store, `Date`
) w
JOIN features f
    ON w.Store = f.Store
    AND w.`Date` = f.`Date`
GROUP BY DATE_FORMAT(w.`Date`, '%Y-%m')
ORDER BY sales_month;


-- 6. Store-level sales consistency

WITH weekly_store_sales AS (
    SELECT
        Store,
        `Date`,
        SUM(Weekly_Sales) AS total_weekly_sales
    FROM walmart_sales
    GROUP BY Store, `Date`
)
SELECT
    Store,
    COUNT(*) AS weeks_covered,
    ROUND(AVG(total_weekly_sales), 2) AS average_sales,
    ROUND(STDDEV_POP(total_weekly_sales), 2)
        AS sales_volatility,
    ROUND(
        STDDEV_POP(total_weekly_sales) * 100
        / NULLIF(AVG(total_weekly_sales), 0), 2
    ) AS coefficient_of_variation
FROM weekly_store_sales
GROUP BY Store
ORDER BY coefficient_of_variation ASC;


-- 7. Final data quality assessment

SELECT
    COUNT(*) AS total_records,
    SUM(MarkDown1 IS NULL) AS missing_markdown1,
    SUM(MarkDown2 IS NULL) AS missing_markdown2,
    SUM(MarkDown3 IS NULL) AS missing_markdown3,
    SUM(MarkDown4 IS NULL) AS missing_markdown4,
    SUM(MarkDown5 IS NULL) AS missing_markdown5,
    SUM(CPI IS NULL) AS missing_cpi,
    SUM(Unemployment IS NULL) AS missing_unemployment,
    SUM(Weekly_Sales < 0) AS negative_sales_records
FROM walmart_analysis;


-- 8. Duplicate record validation

SELECT
    Store,
    Dept,
    `Date`,
    COUNT(*) AS duplicate_count
FROM walmart_sales
GROUP BY Store, Dept, `Date`
HAVING COUNT(*) > 1;
