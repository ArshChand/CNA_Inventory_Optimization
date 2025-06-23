-- ABC ANALYSIS - Product Classification by Revenue Impact

-- ABC analysis is fundamental for inventory optimization, categorizing products based 
-- on their revenue contribution following the Pareto principle. The analysis classifies 
-- inventory into three categories: "A" items contributing approximately 80% of revenue, 
-- "B" items contributing 15%, and "C" items contributing the remaining 5%.

WITH product_sales AS (
    SELECT 
        i.product_id,
        p.category,
        SUM(i.units_sold * pr.price) as total_revenue,
        SUM(i.units_sold) as total_units_sold,
        AVG(i.inventory_level) as avg_inventory_level
    FROM Inventory i
    JOIN Product p ON i.product_id = p.product_id
    JOIN Pricing pr ON i.date = pr.date 
        AND i.store_id = pr.store_id 
        AND i.product_id = pr.product_id
    WHERE i.date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY i.product_id, p.category
),
revenue_ranking AS (
    SELECT *,
        (total_revenue / SUM(total_revenue) OVER()) * 100 as revenue_percentage,
        SUM(total_revenue) OVER(ORDER BY total_revenue DESC) / 
            SUM(total_revenue) OVER() * 100 as cumulative_revenue_pct
    FROM product_sales
)
SELECT 
    product_id,
    category,
    total_revenue,
    revenue_percentage,
    cumulative_revenue_pct,
    CASE 
        WHEN cumulative_revenue_pct <= 80 THEN 'A - High Value'
        WHEN cumulative_revenue_pct <= 95 THEN 'B - Medium Value' 
        ELSE 'C - Low Value'
    END as abc_classification,
    CASE 
        WHEN cumulative_revenue_pct <= 80 THEN 'Daily monitoring, tight controls'
        WHEN cumulative_revenue_pct <= 95 THEN 'Weekly monitoring, standard controls'
        ELSE 'Monthly monitoring, basic controls'
    END as management_strategy
FROM revenue_ranking
ORDER BY total_revenue DESC;

--------------------------------------------------------------------------------------------

-- INVENTORY TURNOVER ANALYSIS

-- Inventory turnover ratio is a critical metric measuring how efficiently 
-- a company manages its stock by calculating how often inventory is sold
-- and replaced over a specific period. The formula divides cost of goods
-- sold by average inventory to determine turnover frequency.

WITH inventory_metrics AS (
    SELECT 
        i.product_id,
        p.category,
        s.region,
        SUM(i.units_sold) as total_units_sold,
        AVG(i.inventory_level) as avg_inventory_level,
        COUNT(DISTINCT i.date) as days_tracked
    FROM Inventory i
    JOIN Product p ON i.product_id = p.product_id
    JOIN Store s ON i.store_id = s.store_id
    WHERE i.date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY i.product_id, p.category, s.region
)
SELECT 
    product_id,
    category,
    region,
    total_units_sold,
    avg_inventory_level,
    CASE 
        WHEN avg_inventory_level > 0 
        THEN ROUND(total_units_sold / avg_inventory_level, 2)
        ELSE 0 
    END as inventory_turnover_ratio,
    CASE 
        WHEN total_units_sold / avg_inventory_level >= 12 THEN 'Fast Moving (>12x/year)'
        WHEN total_units_sold / avg_inventory_level >= 6 THEN 'Medium Moving (6-12x/year)'
        WHEN total_units_sold / avg_inventory_level >= 2 THEN 'Slow Moving (2-6x/year)'
        ELSE 'Dead Stock (<2x/year)'
    END as movement_classification
FROM inventory_metrics
WHERE avg_inventory_level > 0
ORDER BY inventory_turnover_ratio DESC;

----------------------------------------------------------------------------------------------

-- SEASONAL DEMAND PATTERN ANALYSIS

-- Seasonal demand analysis is crucial for retail inventory management, 
-- allowing businesses to identify patterns and fluctuations in product 
-- demand throughout the year. This analysis helps retailers prepare for 
-- peak sales periods and adjust inventory levels accordingly.

WITH monthly_sales AS (
    SELECT 
        i.product_id,
        p.category,
        MONTH(i.date) as month_num,
        MONTHNAME(i.date) as month_name,
        s.seasonality,
        AVG(i.units_sold) as avg_monthly_sales
    FROM Inventory i
    JOIN Product p ON i.product_id = p.product_id
    JOIN Season s ON i.date = s.date
    WHERE i.date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY i.product_id, p.category, MONTH(i.date), MONTHNAME(i.date), s.seasonality
),
overall_averages AS (
    SELECT 
        product_id,
        AVG(avg_monthly_sales) as overall_avg_sales
    FROM monthly_sales
    GROUP BY product_id
)
SELECT 
    ms.product_id,
    ms.category,
    ms.month_name,
    ms.seasonality,
    ROUND(ms.avg_monthly_sales, 0) as avg_monthly_sales,
    ROUND(oa.overall_avg_sales, 0) as overall_avg_sales,
    ROUND((ms.avg_monthly_sales / oa.overall_avg_sales) * 100, 1) as seasonality_index,
    CASE 
        WHEN (ms.avg_monthly_sales / oa.overall_avg_sales) >= 1.2 THEN 'Peak Season'
        WHEN (ms.avg_monthly_sales / oa.overall_avg_sales) >= 0.8 THEN 'Normal Season'
        ELSE 'Low Season'
    END as seasonal_classification
FROM monthly_sales ms
JOIN overall_averages oa ON ms.product_id = oa.product_id
ORDER BY ms.product_id, ms.month_num;

------------------------------------------------------------------------------------------------

-- WEATHER IMPACT ANALYSIS

-- Weather Impact and External Factor Analysis
-- Weather conditions significantly impact retail sales patterns, 
-- with studies showing that pleasant weather can result in 
-- significant business loss to online retailers as customers 
-- prefer physical stores. Conversely, inclement weather generally 
-- benefits e-commerce operations.

WITH weather_sales AS (
    SELECT 
        i.product_id,
        p.category,
        c.weather_condition,
        AVG(i.units_sold) as avg_units_sold,
        COUNT(*) as observation_days
    FROM Inventory i
    JOIN Product p ON i.product_id = p.product_id
    JOIN Calendar c ON i.date = c.date 
        AND i.store_id = c.store_id 
        AND i.product_id = c.product_id
    WHERE i.date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY i.product_id, p.category, c.weather_condition
    HAVING COUNT(*) >= 10
),
baseline_sales AS (
    SELECT 
        product_id,
        AVG(avg_units_sold) as baseline_avg_sales
    FROM weather_sales
    GROUP BY product_id
)
SELECT 
    ws.product_id,
    ws.category,
    ws.weather_condition,
    ROUND(ws.avg_units_sold, 1) as avg_sales_in_weather,
    ROUND(bs.baseline_avg_sales, 1) as baseline_avg_sales,
    ROUND(((ws.avg_units_sold - bs.baseline_avg_sales) / bs.baseline_avg_sales) * 100, 1) as weather_impact_percent,
    CASE 
        WHEN ((ws.avg_units_sold - bs.baseline_avg_sales) / bs.baseline_avg_sales) > 0.1 
        THEN 'Positive Weather Impact'
        WHEN ((ws.avg_units_sold - bs.baseline_avg_sales) / bs.baseline_avg_sales) < -0.1 
        THEN 'Negative Weather Impact'
        ELSE 'Neutral Weather Impact'
    END as weather_sensitivity
FROM weather_sales ws
JOIN baseline_sales bs ON ws.product_id = bs.product_id
ORDER BY ABS(((ws.avg_units_sold - bs.baseline_avg_sales) / bs.baseline_avg_sales)) DESC;

------------------------------------------------------------------------------------------------

-- COMPETITIVE PRICING ANALYSIS

-- Competitive pricing analysis is essential for retail success, with up to 84% of buyers 
-- comparing competitor prices across multiple stores. This analysis enables real-time 
-- market positioning and pricing optimization strategies.

WITH pricing_analysis AS (
    SELECT 
        pr.product_id,
        p.category,
        s.region,
        AVG(pr.price) as avg_our_price,
        AVG(pr.competitor_price) as avg_competitor_price,
        AVG(i.units_sold) as avg_units_sold
    FROM Pricing pr
    JOIN Product p ON pr.product_id = p.product_id
    JOIN Store s ON pr.store_id = s.store_id
    JOIN Inventory i ON pr.date = i.date 
        AND pr.store_id = i.store_id 
        AND pr.product_id = i.product_id
    WHERE pr.date BETWEEN '2023-01-01' AND '2023-12-31'
        AND pr.competitor_price IS NOT NULL
    GROUP BY pr.product_id, p.category, s.region
)
SELECT 
    product_id,
    category,
    region,
    ROUND(avg_our_price, 2) as avg_our_price,
    ROUND(avg_competitor_price, 2) as avg_competitor_price,
    ROUND(((avg_our_price - avg_competitor_price) / avg_competitor_price) * 100, 1) as price_premium_percent,
    CASE 
        WHEN ((avg_our_price - avg_competitor_price) / avg_competitor_price) > 0.1 
        THEN 'Premium Pricing (+10%)'
        WHEN ((avg_our_price - avg_competitor_price) / avg_competitor_price) > -0.05 
        THEN 'Competitive Pricing (±5%)'
        ELSE 'Aggressive Pricing (-5%+)'
    END as pricing_strategy
FROM pricing_analysis
ORDER BY price_premium_percent DESC;

------------------------------------------------------------------------------------------------

-- DEMAND FORECAST ACCURACY ANALYSIS

-- Effective demand forecasting is crucial for supply chain optimization, 
-- requiring analysis of historical data, trends, and external factors to 
-- predict future demand accurately. SQL-based forecasting enables businesses 
-- to develop advanced models and make data-driven decisions.

WITH forecast_accuracy AS (
    SELECT 
        i.product_id,
        p.category,
        s.region,
        AVG(i.units_sold) as avg_actual_sales,
        AVG(i.demand_forecast) as avg_forecasted_sales,
        AVG(ABS(i.units_sold - i.demand_forecast) / NULLIF(i.units_sold, 0)) * 100 as mape
    FROM Inventory i
    JOIN Product p ON i.product_id = p.product_id
    JOIN Store s ON i.store_id = s.store_id
    WHERE i.date BETWEEN '2023-01-01' AND '2023-12-31'
        AND i.demand_forecast IS NOT NULL
        AND i.units_sold > 0
    GROUP BY i.product_id, p.category, s.region
)
SELECT 
    product_id,
    category,
    region,
    ROUND(avg_actual_sales, 0) as avg_actual_sales,
    ROUND(avg_forecasted_sales, 0) as avg_forecasted_sales,
    ROUND(mape, 1) as mape_percent,
    CASE 
        WHEN mape <= 10 THEN 'Excellent Forecast (≤10% MAPE)'
        WHEN mape <= 20 THEN 'Good Forecast (10-20% MAPE)'
        WHEN mape <= 30 THEN 'Fair Forecast (20-30% MAPE)'
        ELSE 'Poor Forecast (>30% MAPE)'
    END as forecast_quality
FROM forecast_accuracy
ORDER BY mape_percent ASC;