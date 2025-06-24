-- Remove Executive Summary Dashboard view
DROP VIEW IF EXISTS ExecutiveSummaryDashboard;

-- Remove Monthly Performance Trends Dashboard view
DROP VIEW IF EXISTS MonthlyTrendsDashboard;

-- Remove Category Performance Dashboard view
DROP VIEW IF EXISTS CategoryPerformanceDashboard;

-- Remove Regional Performance Dashboard view
DROP VIEW IF EXISTS RegionalPerformanceDashboard;

-- Remove Year-over-Year Comparison view
DROP VIEW IF EXISTS YearOverYearComparison;

-- ============================
-- URBAN RETAIL CO. INVENTORY MANAGEMENT SYSTEM
-- Complete Dashboard Views Creation Script
-- Historical Analysis for 2022-2023 Dataset
-- ============================

USE inventory_forecasting;

-- ============================
-- 1. EXECUTIVE SUMMARY DASHBOARD
-- ============================
CREATE VIEW ExecutiveSummaryDashboard AS
SELECT 
    '2022-2023 Historical Analysis' as analysis_period,
    
    -- Total Business Metrics
    (SELECT COUNT(DISTINCT product_id) 
     FROM Inventory 
     WHERE date BETWEEN '2022-01-01' AND '2023-12-31') as total_products_tracked,
    
    (SELECT COUNT(DISTINCT store_id) 
     FROM Inventory 
     WHERE date BETWEEN '2022-01-01' AND '2023-12-31') as total_stores_analyzed,
    
    -- Revenue Performance
    (SELECT ROUND(SUM(i.units_sold * pr.price), 2) 
     FROM Inventory i 
     JOIN Pricing pr ON i.date = pr.date AND i.store_id = pr.store_id AND i.product_id = pr.product_id
     WHERE i.date BETWEEN '2022-01-01' AND '2023-12-31') as total_revenue_period,
    
    (SELECT SUM(units_sold) 
     FROM Inventory 
     WHERE date BETWEEN '2022-01-01' AND '2023-12-31') as total_units_sold,
    
    -- Inventory Health
    (SELECT ROUND(AVG(CASE WHEN inventory_level = 0 THEN 1 ELSE 0 END) * 100, 2)
     FROM Inventory 
     WHERE date BETWEEN '2022-01-01' AND '2023-12-31') as avg_stockout_rate_percent,
    
    (SELECT ROUND(AVG(inventory_level), 0)
     FROM Inventory 
     WHERE date BETWEEN '2022-01-01' AND '2023-12-31') as avg_inventory_level,
    
    -- Forecast Performance
    (SELECT ROUND(AVG(ABS(units_sold - demand_forecast) / NULLIF(units_sold, 0)) * 100, 1)
     FROM Inventory 
     WHERE date BETWEEN '2022-01-01' AND '2023-12-31'
     AND demand_forecast IS NOT NULL 
     AND units_sold > 0) as overall_forecast_mape_percent;

-- ============================
-- 2. MONTHLY PERFORMANCE TRENDS DASHBOARD
-- ============================
-- ============================
-- CORRECTED MONTHLY TRENDS DASHBOARD
-- ============================
CREATE VIEW MonthlyTrendsDashboard AS
SELECT 
    YEAR(i.date) AS year,
    MONTH(i.date) AS month,
    MONTHNAME(i.date) AS month_name,  -- Now included in GROUP BY
    SUM(i.units_sold) AS monthly_units_sold,
    ROUND(SUM(i.units_sold * pr.price), 2) AS monthly_revenue,
    COUNT(DISTINCT i.product_id) AS active_products,
    ROUND(AVG(i.inventory_level), 0) AS avg_inventory_level,
    ROUND(AVG(CASE WHEN i.inventory_level = 0 THEN 1 ELSE 0 END) * 100, 2) AS stockout_rate_percent,
    ROUND(AVG(ABS(i.units_sold - i.demand_forecast) / NULLIF(i.units_sold, 0)) * 100, 1) AS forecast_accuracy_mape,
    COUNT(DISTINCT s.region) AS active_regions
FROM Inventory i
JOIN Pricing pr ON i.date = pr.date 
    AND i.store_id = pr.store_id 
    AND i.product_id = pr.product_id
JOIN Store s ON i.store_id = s.store_id
WHERE i.date BETWEEN '2022-01-01' AND '2023-12-31'
    AND i.demand_forecast IS NOT NULL
    AND i.units_sold > 0
GROUP BY 
    YEAR(i.date),
    MONTH(i.date),
    MONTHNAME(i.date)  -- Added to GROUP BY to resolve error
ORDER BY year, month;


-- ============================
-- 3. CATEGORY PERFORMANCE DASHBOARD
-- ============================
CREATE VIEW CategoryPerformanceDashboard AS
SELECT 
    p.category,
    
    -- Volume Metrics
    SUM(i.units_sold) as total_units_sold,
    ROUND(SUM(i.units_sold * pr.price), 2) as total_revenue,
    COUNT(DISTINCT i.product_id) as products_in_category,
    
    -- Performance Metrics
    ROUND(AVG(i.inventory_level), 0) as avg_inventory_level,
    ROUND(AVG(CASE WHEN i.inventory_level = 0 THEN 1 ELSE 0 END) * 100, 2) as stockout_rate_percent,
    
    -- Efficiency Metrics
    ROUND(AVG(i.units_sold / NULLIF(i.inventory_level, 0)), 2) as avg_turnover_ratio,
    ROUND(AVG(ABS(i.units_sold - i.demand_forecast) / NULLIF(i.units_sold, 0)) * 100, 1) as forecast_accuracy_mape,
    
    -- Pricing Intelligence
    ROUND(AVG(pr.price), 2) as avg_selling_price,
    ROUND(AVG(pr.competitor_price), 2) as avg_competitor_price,
    ROUND(((AVG(pr.price) - AVG(pr.competitor_price)) / AVG(pr.competitor_price)) * 100, 1) as price_premium_percent
    
FROM Inventory i
JOIN Product p ON i.product_id = p.product_id
JOIN Pricing pr ON i.date = pr.date AND i.store_id = pr.store_id AND i.product_id = pr.product_id
WHERE i.date BETWEEN '2022-01-01' AND '2023-12-31'
AND i.demand_forecast IS NOT NULL
AND i.units_sold > 0
AND pr.competitor_price IS NOT NULL
GROUP BY p.category
ORDER BY total_revenue DESC;

-- ============================
-- 4. REGIONAL PERFORMANCE DASHBOARD
-- ============================
CREATE VIEW RegionalPerformanceDashboard AS
SELECT 
    s.region,
    
    -- Business Volume
    COUNT(DISTINCT i.store_id) as stores_in_region,
    COUNT(DISTINCT i.product_id) as products_sold,
    SUM(i.units_sold) as total_units_sold,
    ROUND(SUM(i.units_sold * pr.price), 2) as total_revenue,
    
    -- Operational Metrics
    ROUND(AVG(i.inventory_level), 0) as avg_inventory_level,
    ROUND(AVG(CASE WHEN i.inventory_level = 0 THEN 1 ELSE 0 END) * 100, 2) as stockout_rate_percent,
    
    -- External Factors Impact
    ROUND(AVG(CASE WHEN c.weather_condition = 'Sunny' THEN i.units_sold ELSE NULL END), 1) as avg_sales_sunny_days,
    ROUND(AVG(CASE WHEN c.weather_condition = 'Rainy' THEN i.units_sold ELSE NULL END), 1) as avg_sales_rainy_days,
    ROUND(AVG(CASE WHEN c.holiday = TRUE THEN i.units_sold ELSE NULL END), 1) as avg_sales_holidays,
    
    -- Performance Quality
    ROUND(AVG(ABS(i.units_sold - i.demand_forecast) / NULLIF(i.units_sold, 0)) * 100, 1) as forecast_accuracy_mape
    
FROM Inventory i
JOIN Store s ON i.store_id = s.store_id
JOIN Pricing pr ON i.date = pr.date AND i.store_id = pr.store_id AND i.product_id = pr.product_id
LEFT JOIN Calendar c ON i.date = c.date AND i.store_id = c.store_id
WHERE i.date BETWEEN '2022-01-01' AND '2023-12-31'
AND i.demand_forecast IS NOT NULL
AND i.units_sold > 0
GROUP BY s.region
ORDER BY total_revenue DESC;

-- ============================
-- 5. YEAR-OVER-YEAR COMPARISON VIEW
-- ============================
CREATE VIEW YearOverYearComparison AS
SELECT 
    YEAR(i.date) as year,
    COUNT(DISTINCT i.product_id) as active_products,
    SUM(i.units_sold) as total_units_sold,
    ROUND(SUM(i.units_sold * pr.price), 2) as total_revenue,
    ROUND(AVG(i.inventory_level), 0) as avg_inventory_level,
    ROUND(AVG(CASE WHEN i.inventory_level = 0 THEN 1 ELSE 0 END) * 100, 2) as stockout_rate_percent,
    ROUND(AVG(ABS(i.units_sold - i.demand_forecast) / NULLIF(i.units_sold, 0)) * 100, 1) as forecast_mape,
    COUNT(DISTINCT s.region) as active_regions
FROM Inventory i
JOIN Pricing pr ON i.date = pr.date AND i.store_id = pr.store_id AND i.product_id = pr.product_id
JOIN Store s ON i.store_id = s.store_id
WHERE i.date BETWEEN '2022-01-01' AND '2023-12-31'
AND i.demand_forecast IS NOT NULL
AND i.units_sold > 0
GROUP BY YEAR(i.date)
ORDER BY year;