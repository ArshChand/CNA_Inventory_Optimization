CREATE DATABASE IF NOT EXISTS inventory_forecasting;
USE inventory_forecasting;

-- =============================
-- Drop tables if they already exist (to avoid duplicate errors)
-- =============================
DROP TABLE IF EXISTS Pricing;
DROP TABLE IF EXISTS Inventory;
DROP TABLE IF EXISTS Calendar;
DROP TABLE IF EXISTS Store;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS Region;
DROP TABLE IF EXISTS Category;

-- =============================
-- Category Dimension Table
-- =============================
CREATE TABLE Category (
    category_id VARCHAR(10) PRIMARY KEY,
    category_name VARCHAR(50)
);

-- =============================
-- Region Dimension Table
-- =============================
CREATE TABLE Region (
    region_id VARCHAR(10) PRIMARY KEY,
    region_name VARCHAR(50)
);

-- =============================
-- Product Dimension Table
-- =============================
CREATE TABLE Product (
    product_id VARCHAR(10) PRIMARY KEY,
    category_id VARCHAR(10),
    FOREIGN KEY (category_id) REFERENCES Category(category_id)
);

-- =============================
-- Store Dimension Table
-- =============================
CREATE TABLE Store (
    store_id VARCHAR(10) PRIMARY KEY,
    region_id VARCHAR(10),
    FOREIGN KEY (region_id) REFERENCES Region(region_id)
);

-- =============================
-- Calendar Dimension Table
-- =============================
CREATE TABLE Calendar (
    date DATE PRIMARY KEY,
    weather_condition VARCHAR(20),
    holiday_promotion BOOLEAN,
    seasonality VARCHAR(20)
);

-- =============================
-- Inventory Fact Table
-- =============================
CREATE TABLE Inventory (
    date DATE,
    store_id VARCHAR(10),
    product_id VARCHAR(10),
    inventory_level INT,
    units_sold INT,
    units_ordered INT,
    demand_forecast DECIMAL(10,2),
    PRIMARY KEY (date, store_id, product_id),
    FOREIGN KEY (date) REFERENCES Calendar(date),
    FOREIGN KEY (store_id) REFERENCES Store(store_id),
    FOREIGN KEY (product_id) REFERENCES Product(product_id)
);

-- =============================
-- Pricing Fact Table
-- =============================
CREATE TABLE Pricing (
    date DATE,
    store_id VARCHAR(10),
    product_id VARCHAR(10),
    price DECIMAL(10,2),
    discount DECIMAL(5,2),
    competitor_price DECIMAL(10,2),
    PRIMARY KEY (date, store_id, product_id),
    FOREIGN KEY (date) REFERENCES Calendar(date),
    FOREIGN KEY (store_id) REFERENCES Store(store_id),
    FOREIGN KEY (product_id) REFERENCES Product(product_id)
);
