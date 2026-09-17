SELECT COUNT(*) FROM products
WHERE product_category_name IS NULL
;

SELECT COUNT(*) FROM(SELECT product_id,
COALESCE(product_category_name_english, 'uncategorized') category_english
FROM products p
LEFT JOIN product_category_name_translation t ON
p.product_category_name = t.product_category_name
WHERE product_category_name_english IS NULL) ;

SELECT DISTINCT p.product_category_name
FROM products p
LEFT JOIN product_category_name_translation t 
    ON p.product_category_name = t.product_category_name
WHERE t.product_category_name_english IS NULL
  AND p.product_category_name IS NOT NULL;

-- Question 1: What is total product revenue?

SELECT SUM(price) total_product_revenue
FROM order_items;

--Question 2: What's the monthly revenue trend (by year and month)?

SELECT EXTRACT(YEAR FROM order_purchase_timestamp) yr,
EXTRACT(MONTH FROM order_purchase_timestamp) mnth,
SUM(price) total_product_revenue
FROM orders o
LEFT JOIN order_items oi ON 
o.order_id = oi.order_id
GROUP BY yr, mnth
ORDER BY yr,mnth;

--Question 3: What's the overall Late Delivery %?

SELECT ROUND(SUM(CASE WHEN order_delivered_customer_date ::DATE > order_estimated_delivery_date ::DATE THEN 1 ELSE 0 END) *1.0/
NULLIF(COUNT(order_delivered_customer_date),0)*100,2) AS late_Delivery
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

--Question 4: Late Delivery % by state?

SELECT customer_state,
ROUND(SUM(CASE WHEN order_delivered_customer_date ::DATE > order_estimated_delivery_date ::DATE THEN 1 ELSE 0 END) *1.0/
NULLIF(COUNT(order_delivered_customer_date),0) *100,2) AS late_Delivery
FROM orders o
LEFT JOIN customers c ON 
o.customer_id = c.customer_id
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY customer_state 
ORDER BY late_delivery DESC;

--Question 5: Late Delivery % by category?

SELECT COALESCE(product_category_name_english,'uncategorized') category_english,
ROUND(SUM(CASE WHEN order_delivered_customer_date ::DATE > order_estimated_delivery_date ::DATE THEN 1 ELSE 0 END) *1.0/
NULLIF(COUNT(order_delivered_customer_date),0) *100,2) AS late_Delivery
FROM orders o
LEFT JOIN order_items oi ON 
o.order_id = oi.order_id
LEFT JOIN products p ON
oi.product_id = p.product_id
LEFT JOIN product_category_name_translation pt ON 
p.product_category_name = pt.product_category_name
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY category_english
ORDER BY late_delivery DESC;

--Question 6: top 10 categories by revenue

SELECT COALESCE(product_category_name_english,'uncategorized') category_english,
SUM(price) total_product_revenue
FROM order_items oi 
LEFT JOIN products p ON 
oi.product_id = p.product_id
LEFT JOIN product_category_name_translation pt ON 
p.product_category_name = pt.product_category_name
GROUP BY category_english
ORDER BY total_product_revenue DESC
LIMIT 10;


--Question 7: Average order value

SELECT ROUND(AVG(order_total),2) avg_order
FROM(
SELECT order_id,SUM(price) order_total
FROM order_items
GROUP BY order_id)sub;

--Question 8: Revenue & AOV by Payment Method?

SELECT payment_type,
SUM(payment_value) total_amount_paid,
COUNT(DISTINCT order_id) unique_order,
ROUND(SUM(payment_value) / NULLIF(COUNT(DISTINCT order_id),0),2) avg_amount_paid_per_order
FROM payments
GROUP BY payment_type;

--Question 9: Payment installment distribution.

SELECT payment_installments,
COUNT(DISTINCT order_id) unique_order
FROM payments 
WHERE payment_type = 'credit_card'
AND payment_installments >=1
GROUP BY payment_installments
ORDER BY payment_installments;

--Question 10: Freight cost relative to product sales

SELECT SUM(freight_value)/SUM(price)*100 freight_sales_ratio
FROM order_items;



