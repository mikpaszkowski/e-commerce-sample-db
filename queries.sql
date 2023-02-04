-- The number of orders placed by each user, along with the total amount spent by that user
SELECT user1.user_id, COUNT(DISTINCT order1.order_id) AS num_orders, SUM(paymentdetails.amount) AS total_amount
FROM "User" user1
         JOIN "Order" order1 ON order1.USER_ID = user1.USER_ID
         JOIN PAYMENTDETAILS ON PAYMENTDETAILS.ORDER_ID = order1.ORDER_ID
GROUP BY user1.USER_ID;


-- Retrieve the average price of products for each category and the number of products sold in each category
SELECT CATEGORY, ROUND(AVG(price), 2) as avg_price, SUM(quantity) as total_quantity
FROM PRODUCT
         JOIN ORDERPRODUCT
              ON PRODUCT.PRODUCT_ID = ORDERPRODUCT.PRODUCT_ID
GROUP BY category
HAVING SUM(quantity) > 5;

-- selects the product_id, description, total quantity, and total sales for each product
SELECT PRODUCT.product_id,
       PRODUCT.description,
       SUM(ORDERPRODUCT.quantity)                 as total_quantity,
       SUM(ORDERPRODUCT.quantity * PRODUCT.price) as total_sales
FROM PRODUCT
         RIGHT JOIN ORDERPRODUCT
                    ON PRODUCT.product_id = ORDERPRODUCT.PRODUCT_ID
GROUP BY PRODUCT.product_id, PRODUCT.description
HAVING SUM(ORDERPRODUCT.quantity) > 10
ORDER BY PRODUCT_ID;


-- select order_id, user_id with the most expensive product in order
SELECT o.ORDER_ID, u.USER_ID, MAX(p.price) as max_price
FROM "Order" o
         JOIN "User" u ON o.USER_ID = u.user_id
         JOIN ORDERPRODUCT op ON o.ORDER_ID = op.ORDER_ID
         JOIN PRODUCT p ON op.PRODUCT_ID = p.PRODUCT_ID
GROUP BY o.ORDER_ID, u.USER_ID
ORDER BY ORDER_ID;

-- or

SELECT o.ORDER_ID,
       o.USER_ID,
       (SELECT MAX(p.price)
        FROM PRODUCT p
                 INNER JOIN ORDERPRODUCT op ON p.product_id = op.PRODUCT_ID
        WHERE op.ORDER_ID = o.ORDER_ID) AS most_expensive_product_price
FROM "Order" o;


-- select users who bought the most expensive product in the system along with the order_id

SELECT user1.USER_ID,
       order1.ORDER_ID
FROM "User" user1
         JOIN "Order" order1 ON user1.USER_ID = order1.USER_ID
         JOIN orderproduct ON order1.ORDER_ID = orderproduct.ORDER_ID
         JOIN product ON orderproduct.PRODUCT_ID = product.PRODUCT_ID
GROUP BY user1.USER_ID,
         order1.ORDER_ID,
         product.PRODUCT_ID
HAVING MAX(product.PRICE) = (SELECT MAX(price) FROM product);

-- finds all customers whose order amount sum is greater than the average order amount in the system
SELECT USER_ID
FROM "Order" outer
WHERE (SELECT SUM(total_amount) FROM "Order" inner WHERE inner.USER_ID = outer.USER_ID) >
      (SELECT AVG(total_amount) FROM "Order")
GROUP BY USER_ID;

---Get all products with discounts, which percentage is higher than 20%
SELECT PRODUCT.product_id, PRODUCT.price, PRODUCT.description, PRODUCT.category, DISCOUNT.percent_value
FROM PRODUCT
         JOIN ORDERPRODUCT ON PRODUCT.PRODUCT_ID = ORDERPRODUCT.PRODUCT_ID
         JOIN ORDERPRODUCT_DISCOUNT ON ORDERPRODUCT.ORDER_PRODUCT_ID = ORDERPRODUCT_DISCOUNT.ORDERPRODUCT_ID
         JOIN DISCOUNT ON ORDERPRODUCT_DISCOUNT.DISCOUNT_ID = DISCOUNT.DISCOUNT_ID
WHERE DISCOUNT.PERCENT_VALUE > 20;


-- find the average paid price for each product
SELECT PRODUCT.PRODUCT_ID, ROUND(AVG(PAYMENTDETAILS.amount / ORDERPRODUCT.quantity), 2) as avg_price
FROM ORDERPRODUCT
         LEFT JOIN PRODUCT ON ORDERPRODUCT.PRODUCT_ID = PRODUCT.PRODUCT_ID
         LEFT JOIN PAYMENTDETAILS ON ORDERPRODUCT.ORDER_ID = PAYMENTDETAILS.ORDER_ID
GROUP BY PRODUCT.PRODUCT_ID;


---Get all users with at least 10 orders or 1000 units of money spent
WITH user_orders AS (SELECT USER_ID, COUNT(*) as order_count, SUM(PAYMENTDETAILS.amount) as money_spent
                     FROM "Order" order1
                              LEFT JOIN PAYMENTDETAILS ON order1.PAYMENT_DET_ID = PAYMENTDETAILS.payment_det_id
                     GROUP BY USER_ID)
SELECT USER_ID
FROM user_orders
WHERE order_count >= 10
   OR money_spent > 1000;

---retrieve the product name and the total amount spent by the user on all their orders, for each order
SELECT PRODUCT.DESCRIPTION                               as product_name,
       order1.TOTAL_AMOUNT,
       (SELECT SUM(PAYMENTDETAILS.AMOUNT)
        FROM PAYMENTDETAILS
        WHERE PAYMENTDETAILS.ORDER_ID = order1.ORDER_ID) as total_spent
FROM ORDERPRODUCT
         LEFT JOIN PRODUCT ON PRODUCT.PRODUCT_ID = ORDERPRODUCT.PRODUCT_ID
         LEFT JOIN "Order" order1 ON order1.ORDER_ID = ORDERPRODUCT.ORDER_ID;

-- top 10 most popular products, based on the total quantity sold
SELECT PRODUCT.PRODUCT_ID, DESCRIPTION, SUM(ORDERPRODUCT.QUANTITY) AS total_quantity
FROM ORDERPRODUCT
         JOIN PRODUCT ON ORDERPRODUCT.PRODUCT_ID = PRODUCT.PRODUCT_ID
GROUP BY PRODUCT.PRODUCT_ID, PRODUCT.DESCRIPTION
ORDER BY total_quantity DESC
    FETCH NEXT 10 ROWS ONLY;


-- total revenue for each category of product
SELECT PRODUCT.CATEGORY,
       SUM(CASE
               WHEN order1.STATUS = 'PAID'
                   THEN ORDERPRODUCT.QUANTITY * PRODUCT.PRICE
               ELSE 0
           END) as revenue
FROM "Order" order1
         JOIN ORDERPRODUCT ON order1.ORDER_ID = ORDERPRODUCT.ORDER_ID
         JOIN PRODUCT ON ORDERPRODUCT.PRODUCT_ID = PRODUCT.PRODUCT_ID
GROUP BY PRODUCT.CATEGORY
ORDER BY PRODUCT.CATEGORY;





