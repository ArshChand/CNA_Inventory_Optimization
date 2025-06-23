-- ABC ANALYSIS - Product Classification by Revenue Impact
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
    WHERE i.date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
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