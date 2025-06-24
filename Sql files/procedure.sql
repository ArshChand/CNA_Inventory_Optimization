DROP PROCEDURE IF EXISTS AnalyzeHistoricalReorderPatterns;
DROP PROCEDURE IF EXISTS GenerateHistoricalPerformanceReport;
DROP PROCEDURE IF EXISTS AnalyzeHistoricalCriticalEvents;

DELIMITER //
CREATE PROCEDURE AnalyzeHistoricalReorderPatterns()
BEGIN
    -- Create temporary table for pre-calculated averages
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_rolling_avgs AS
    SELECT 
        i.product_id,
        i.store_id,
        i.date,
        AVG(i2.units_sold) AS avg_7day_sales
    FROM Inventory i
    JOIN Inventory i2 ON 
        i.product_id = i2.product_id 
        AND i.store_id = i2.store_id
        AND i2.date BETWEEN i.date - INTERVAL 6 DAY AND i.date
    WHERE i.date BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY i.product_id, i.store_id, i.date;

    -- Main query using pre-calculated averages
    SELECT 
        i.product_id,
        p.category,
        s.region,
        i.store_id,
        i.date,
        i.inventory_level,
        a.avg_7day_sales,
        CASE 
            WHEN i.inventory_level <= a.avg_7day_sales * 7 THEN 'SHOULD HAVE REORDERED'
            WHEN i.inventory_level <= a.avg_7day_sales * 14 THEN 'LOW STOCK RISK'
            ELSE 'ADEQUATE STOCK'
        END as historical_stock_status
    FROM Inventory i
    JOIN temp_rolling_avgs a ON 
        i.product_id = a.product_id 
        AND i.store_id = a.store_id 
        AND i.date = a.date
    JOIN Product p ON i.product_id = p.product_id
    JOIN Store s ON i.store_id = s.store_id
    ORDER BY i.date, i.product_id, i.store_id;
    
    DROP TEMPORARY TABLE IF EXISTS temp_rolling_avgs;
END//
DELIMITER ;

DELIMITER //

CREATE PROCEDURE GenerateHistoricalPerformanceReport()
BEGIN
    -- Monthly performance summary for 2022-2023
    SELECT 
        YEAR(i.date) AS year,
        MONTH(i.date) AS month,
        MONTHNAME(MIN(i.date)) AS month_name,  -- Fixed here
        COUNT(DISTINCT i.product_id) AS total_products,
        SUM(i.units_sold) AS total_units_sold,
        ROUND(SUM(i.units_sold * pr.price), 2) AS total_revenue,
        ROUND(AVG(i.inventory_level), 0) AS avg_inventory_level,
        ROUND(AVG(CASE WHEN i.inventory_level = 0 THEN 1 ELSE 0 END) * 100, 2) AS stockout_percentage,
        ROUND(AVG(ABS(i.units_sold - i.demand_forecast) / NULLIF(i.units_sold, 0)) * 100, 1) AS avg_forecast_mape
    FROM Inventory i
    JOIN Pricing pr ON i.date = pr.date AND i.store_id = pr.store_id AND i.product_id = pr.product_id
    WHERE i.date BETWEEN '2022-01-01' AND '2023-12-31'
      AND i.demand_forecast IS NOT NULL
      AND i.units_sold > 0
    GROUP BY YEAR(i.date), MONTH(i.date)
    ORDER BY year, month;
END//

DELIMITER ;



DELIMITER //
CREATE PROCEDURE AnalyzeHistoricalCriticalEvents()
BEGIN
    -- Identify critical stockout periods during 2022-2023
    SELECT 
        'HISTORICAL STOCKOUTS' as event_type,
        i.product_id,
        p.category,
        s.region,
        i.store_id,
        i.date as stockout_date,
        COUNT(*) OVER (
            PARTITION BY i.product_id, i.store_id 
            ORDER BY i.date 
            ROWS BETWEEN CURRENT ROW AND 6 FOLLOWING
        ) as consecutive_stockout_days,
        'Critical inventory shortage identified' as event_description
    FROM Inventory i
    JOIN Product p ON i.product_id = p.product_id
    JOIN Store s ON i.store_id = s.store_id
    WHERE i.date BETWEEN '2022-01-01' AND '2023-12-31'
    AND i.inventory_level = 0
    
    UNION ALL
    
    -- Identify periods of poor forecast accuracy
    SELECT 
        'POOR FORECAST PERIODS' as event_type,
        i.product_id,
        p.category,
        s.region,
        i.store_id,
        i.date,
        ROUND(ABS(i.units_sold - i.demand_forecast) / NULLIF(i.units_sold, 0) * 100, 1) as mape_percent,
        CONCAT('Forecast error: ', ROUND(ABS(i.units_sold - i.demand_forecast) / NULLIF(i.units_sold, 0) * 100, 1), '%') as event_description
    FROM Inventory i
    JOIN Product p ON i.product_id = p.product_id
    JOIN Store s ON i.store_id = s.store_id
    WHERE i.date BETWEEN '2022-01-01' AND '2023-12-31'
    AND ABS(i.units_sold - i.demand_forecast) / NULLIF(i.units_sold, 0) > 0.3
    AND i.demand_forecast IS NOT NULL
    AND i.units_sold > 0
    
    ORDER BY stockout_date DESC, event_type;
END//
DELIMITER ;