INSERT INTO Product (product_id, category)
SELECT DISTINCT product_id, category
FROM RawInventory;

INSERT INTO Store (store_id, region)
SELECT DISTINCT store_id, region
FROM RawInventory;

INSERT INTO Pricing (date, store_id, region, product_id, price, discount, competitor_price)
SELECT DISTINCT
    date,
    store_id,
    region,
    product_id,
    price,
    discount,
    competitor_price
FROM RawInventory;

INSERT INTO Inventory (date, store_id, region, product_id, inventory_level, units_sold, units_ordered, demand_forecast)
SELECT DISTINCT
    date,
    store_id,
    region,
    product_id,
    inventory_level,
    units_sold,
    units_ordered,
    demand_forecast
FROM RawInventory;

INSERT INTO Season (date, seasonality)
SELECT DISTINCT date, seasonality
FROM RawInventory;

INSERT INTO Calendar (date, store_id, region, product_id, weather_condition, Holiday)
SELECT DISTINCT
    date,
    store_id,
    region,
    product_id,
    weather_condition,
    Holiday
FROM RawInventory;

