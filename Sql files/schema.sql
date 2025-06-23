-- ============================
-- Product Dimension Table
-- ============================
CREATE TABLE Product (
    product_id VARCHAR(10) PRIMARY KEY,      -- Unique identifier for each SKU
    category VARCHAR(50)                     -- Useful for category-level analysis (e.g., Electronics, Toys)
);

-- ============================
-- Store Dimension Table
-- ============================
CREATE TABLE Store (
    store_id VARCHAR(10) PRIMARY KEY,        -- Unique identifier for each store
    region VARCHAR(50)                       -- Enables filtering/reporting by region (East, West, etc.)
);

-- ============================
-- Pricing Fact Table
-- ============================
CREATE TABLE Pricing (
    date DATE,                               -- Date of pricing observation
    store_id VARCHAR(10),
    product_id VARCHAR(10),
    price DECIMAL(10,2),                     -- Actual selling price
    discount DECIMAL(5,2),                   -- Discount on that day
    competitor_price DECIMAL(10,2),          -- Competitor’s price for comparison

    PRIMARY KEY (date, store_id, product_id),    -- Composite key allows tracking price per item per store per day
    FOREIGN KEY (store_id) REFERENCES Store(store_id),
    FOREIGN KEY (product_id) REFERENCES Product(product_id)
);

-- ============================
-- Inventory Fact Table
-- ============================
CREATE TABLE Inventory (
    date DATE,
    store_id VARCHAR(10),
    product_id VARCHAR(10),
    inventory_level INT,                     -- Current stock level
    units_sold INT,                          -- Units sold on that day
    units_ordered INT,                       -- Units ordered from warehouse
    demand_forecast DECIMAL(10,2),           -- Forecasted demand

    PRIMARY KEY (date, store_id, product_id),    -- Composite key to maintain granularity
    FOREIGN KEY (store_id) REFERENCES Store(store_id),
    FOREIGN KEY (product_id) REFERENCES Product(product_id)
);

-- ============================
-- Calendar Dimension Table
-- ============================
CREATE TABLE Season (
    date DATE PRIMARY KEY,                   -- Date acts as primary key for calendar
    seasonality VARCHAR(20)                  -- Season (Winter, Summer, etc.)
);

-- ============================
-- Weather Dimension Table
-- ============================
CREATE TABLE Calendar (
    date DATE PRIMARY KEY,                   -- Date acts as primary key for calendar
    store_id VARCHAR(10),
    product_id VARCHAR(10),
    weather_condition VARCHAR(20),
    Holiday BOOLEAN,   
    PRIMARY KEY (date, store_id, product_id),    -- Composite key to maintain granularity
    FOREIGN KEY (store_id) REFERENCES Store(store_id),
    FOREIGN KEY (product_id) REFERENCES Product(product_id)
);

