USE foodpanda;

-- 1. Filtering (WHERE): late-delivery orders in 2024
SELECT order_id, order_date, delivery_status
FROM Orders
WHERE delivery_status = 'Delayed'
  AND order_date BETWEEN '2024-01-01' AND '2024-12-31';

-- 2. Aggregation (GROUP BY): revenue and order count per restaurant
SELECT r.restaurant_name,
       COUNT(DISTINCT o.order_id)       AS num_orders,
       SUM(oi.price * oi.quantity)      AS total_revenue
FROM Orders o
JOIN Restaurants r  ON r.restaurant_id = o.restaurant_id
JOIN OrderItems  oi ON oi.order_id     = o.order_id
GROUP BY r.restaurant_name
ORDER BY total_revenue DESC;

-- 3. HAVING: restaurants whose average rating is below the overall average
SELECT r.restaurant_name, ROUND(AVG(rt.rating), 3) AS avg_rating
FROM Orders o
JOIN Restaurants r ON r.restaurant_id = o.restaurant_id
JOIN Ratings rt    ON rt.order_id     = o.order_id
GROUP BY r.restaurant_name
HAVING AVG(rt.rating) < (SELECT AVG(rating) FROM Ratings);

-- 4. Using the view: cancelled/delayed rate by payment method
SELECT payment_method,
       COUNT(*) AS orders,
       ROUND(SUM(delivery_status IN ('Cancelled','Delayed')) / COUNT(*), 3) AS problem_rate
FROM v_order_summary
GROUP BY payment_method
HAVING COUNT(*) > 100;

-- 5. Many-to-many (Orders <-> Dishes via OrderItems): top dishes by units sold
SELECT d.dish_name, c.category_name, SUM(oi.quantity) AS units_sold
FROM OrderItems oi
JOIN Dishes d     ON d.dish_id     = oi.dish_id
JOIN Categories c ON c.category_id = d.category_id
GROUP BY d.dish_name, c.category_name
ORDER BY units_sold DESC
LIMIT 10;
