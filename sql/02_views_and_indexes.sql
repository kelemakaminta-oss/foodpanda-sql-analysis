USE foodpanda;

-- VIEW: one row per order with restaurant, customer, payment, rating and total.
-- Replaces a 6-table join that nearly every analysis query needs.
CREATE OR REPLACE VIEW v_order_summary AS
SELECT
    o.order_id,
    o.order_date,
    o.delivery_status,
    c.customer_id,
    c.age,
    c.gender,
    c.loyalty_points,
    r.restaurant_name,
    p.payment_method,
    rt.rating,
    SUM(oi.price * oi.quantity) AS order_total
FROM Orders o
JOIN Customers   c  ON c.customer_id   = o.customer_id
JOIN Restaurants r  ON r.restaurant_id = o.restaurant_id
JOIN OrderItems  oi ON oi.order_id     = o.order_id
LEFT JOIN Payments p  ON p.order_id    = o.order_id
LEFT JOIN Ratings  rt ON rt.order_id   = o.order_id
GROUP BY o.order_id, o.order_date, o.delivery_status, c.customer_id, c.age,
         c.gender, c.loyalty_points, r.restaurant_name, p.payment_method, rt.rating;

-- INDEX: the analysis repeatedly groups orders by month (YEAR/MONTH of order_date)
-- and filters/groups by delivery_status. These columns have no index by default
-- (only PK/FK columns do), so monthly trend queries would scan the whole table.
CREATE INDEX idx_orders_order_date ON Orders(order_date);
CREATE INDEX idx_orders_delivery_status ON Orders(delivery_status);
