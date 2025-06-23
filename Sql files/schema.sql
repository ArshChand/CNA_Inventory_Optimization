CREATE DATABASE IF NOT EXISTS inventory_forecasting;
USE inventory_forecasting;

DROP TABLE IF EXISTS Pricing;
DROP TABLE IF EXISTS Inventory;
DROP TABLE IF EXISTS Calendar;
DROP TABLE IF EXISTS Store;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS Season;


CREATE TABLE IF NOT EXISTS RawInventory (
    date DATE,
    store_id VARCHAR(10),
    product_id VARCHAR(10),
    category VARCHAR(50),
    region VARCHAR(50),
    inventory_level INT,
    units_sold INT,
    units_ordered INT,
    demand_forecast DECIMAL(10,2),
    price DECIMAL(10,2),
    discount DECIMAL(5,2),
    weather_condition VARCHAR(20),
    Holiday BOOLEAN,
    competitor_price DECIMAL(10,2),
    seasonality VARCHAR(20)
);



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
    store_id VARCHAR(10),
    region VARCHAR(50),
    PRIMARY KEY (store_id, region)
);

-- ============================
-- Pricing Fact Table
-- ============================
CREATE TABLE Pricing (
    date DATE,
    store_id VARCHAR(10),
    region VARCHAR(50),
    product_id VARCHAR(10),
    price DECIMAL(10,2),
    discount DECIMAL(5,2),
    competitor_price DECIMAL(10,2),
    
    PRIMARY KEY (date, store_id, region, product_id),
    FOREIGN KEY (store_id, region) REFERENCES Store(store_id, region),
    FOREIGN KEY (product_id) REFERENCES Product(product_id)
);

-- ============================
-- Inventory Fact Table
-- ============================
CREATE TABLE Inventory (
    date DATE,
    store_id VARCHAR(10),
    region VARCHAR(50),
    product_id VARCHAR(10),
    inventory_level INT,
    units_sold INT,
    units_ordered INT,
    demand_forecast DECIMAL(10,2),

    PRIMARY KEY (date, store_id, region, product_id),
    FOREIGN KEY (store_id, region) REFERENCES Store(store_id, region),
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
    date DATE,
    store_id VARCHAR(10),
    region VARCHAR(50),
    product_id VARCHAR(10),
    weather_condition VARCHAR(20),
    Holiday BOOLEAN,

    PRIMARY KEY (date, store_id, region, product_id),
    FOREIGN KEY (store_id, region) REFERENCES Store(store_id, region),
    FOREIGN KEY (product_id) REFERENCES Product(product_id)
);
