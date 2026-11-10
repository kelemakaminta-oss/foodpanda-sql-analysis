-- Foodpanda database: schema + normalization of raw_foodpanda into 3NF tables.
-- Usage: create DB + tables, load the raw CSV into raw_foodpanda (see README),
-- then run the INSERT ... SELECT section at the bottom.
-- NOTE: running this file drops and recreates the `foodpanda` database.

DROP DATABASE IF EXISTS foodpanda;
CREATE DATABASE foodpanda;
USE foodpanda;

CREATE TABLE Customers(
    customer_id VARCHAR(10) PRIMARY KEY,
    gender VARCHAR(20),
    age VARCHAR(10),
    city VARCHAR(100),
    signup_date DATE,
    order_frequency INT CHECK (order_frequency >= 0),
    last_order_date DATE,
    loyalty_points INT CHECK (loyalty_points >= 0),
    churned VARCHAR(10)
);

CREATE TABLE Restaurants (
    restaurant_id INT AUTO_INCREMENT PRIMARY KEY,
    restaurant_name VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE Categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Dishes (
    dish_id INT AUTO_INCREMENT PRIMARY KEY,
    dish_name VARCHAR(255) NOT NULL,
    category_id INT NOT NULL,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id)
);

CREATE TABLE Orders (
    order_id VARCHAR(10) PRIMARY KEY,
    customer_id VARCHAR(10) NOT NULL,
    restaurant_id INT NOT NULL,
    order_date DATE,
    delivery_status VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    FOREIGN KEY (restaurant_id) REFERENCES Restaurants(restaurant_id)
);

CREATE TABLE OrderItems (
    order_id VARCHAR(10) NOT NULL,
    dish_id INT NOT NULL,
    quantity INT CHECK (quantity > 0),
    price DECIMAL(10,2) CHECK (price >= 0),
    PRIMARY KEY (order_id, dish_id),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (dish_id) REFERENCES Dishes(dish_id)
);

CREATE TABLE Payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id VARCHAR(10) NOT NULL UNIQUE,
    payment_method VARCHAR(50),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE
);

CREATE TABLE Ratings (
    rating_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id VARCHAR(10) NOT NULL UNIQUE,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    rating_date DATE,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE
);

-- Staging table mirroring the flat CSV (dates are text, converted on insert)
CREATE TABLE raw_foodpanda (
    customer_id VARCHAR(10),
    gender VARCHAR(20),
    age VARCHAR(10),
    city VARCHAR(100),
    signup_date VARCHAR(10),
    order_id VARCHAR(10),
    order_date VARCHAR(10),
    restaurant_name VARCHAR(255),
    dish_name VARCHAR(255),
    category VARCHAR(100),
    quantity INT,
    price DECIMAL(10,2),
    payment_method VARCHAR(50),
    order_frequency INT,
    last_order_date VARCHAR(10),
    loyalty_points INT,
    churned VARCHAR(10),
    rating INT,
    rating_date VARCHAR(10),
    delivery_status VARCHAR(50)
);

-- >>> Load the CSV into raw_foodpanda here (see README), then run below <<<

INSERT INTO Customers (
    customer_id, gender, age, city, signup_date,
    order_frequency, last_order_date, loyalty_points, churned
)
SELECT DISTINCT
    customer_id, gender, age, city, STR_TO_DATE(signup_date, '%m/%d/%Y'),
    order_frequency, STR_TO_DATE(last_order_date, '%m/%d/%Y'), loyalty_points, churned
FROM raw_foodpanda;

INSERT INTO Restaurants (restaurant_name)
SELECT DISTINCT restaurant_name
FROM raw_foodpanda
WHERE restaurant_name IS NOT NULL;

INSERT INTO Categories (category_name)
SELECT DISTINCT category
FROM raw_foodpanda
WHERE category IS NOT NULL;

INSERT INTO Dishes (dish_name, category_id)
SELECT DISTINCT r.dish_name, c.category_id
FROM raw_foodpanda r
JOIN Categories c
  ON r.category = c.category_name
WHERE r.dish_name IS NOT NULL;

INSERT INTO Orders (
    order_id, customer_id, restaurant_id, order_date, delivery_status
)
SELECT DISTINCT
    r.order_id,
    r.customer_id,
    rest.restaurant_id,
    STR_TO_DATE(r.order_date, '%m/%d/%Y'),
    r.delivery_status
FROM raw_foodpanda r
JOIN Restaurants rest
  ON r.restaurant_name = rest.restaurant_name;

INSERT INTO OrderItems (
    order_id, dish_id, quantity, price
)
SELECT
    r.order_id,
    d.dish_id,
    r.quantity,
    r.price
FROM raw_foodpanda r
JOIN Dishes d
  ON r.dish_name = d.dish_name;

INSERT INTO Payments (
    order_id, payment_method
)
SELECT DISTINCT order_id, payment_method
FROM raw_foodpanda
WHERE payment_method IS NOT NULL;

INSERT INTO Ratings (
    order_id, rating, rating_date
)
SELECT DISTINCT order_id, rating, STR_TO_DATE(rating_date, '%m/%d/%Y')
FROM raw_foodpanda
WHERE rating IS NOT NULL;
