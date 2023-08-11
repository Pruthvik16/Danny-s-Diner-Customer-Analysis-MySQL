CREATE DATABASE dannys_diner;

USE dannys_diner;

CREATE TABLE members(
customer_id INT UNSIGNED auto_increment PRIMARY KEY, #unsigned INT will store only positive value and since the customer_ID will have only positive value we kept it unsigned to be more efficient
first_name varchar(50),
last_name varchar(50),
join_date DATE
);

ALTER TABLE members auto_increment = 1000;

CREATE TABLE menu(
product_id INT UNSIGNED auto_increment PRIMARY KEY,
product_name varchar(50),
price FLOAT
);

ALTER TABLE menu auto_increment = 2000;

CREATE TABLE sales(
customer_id INT UNSIGNED,
order_date DATE,
product_id INT UNSIGNED,
FOREIGN KEY(customer_id) REFERENCES members(customer_id),
FOREIGN KEY(product_id) REFERENCES menu(product_id)
);

#populating data
INSERT INTO members(first_name,last_name,join_date) VALUES
('John', 'Doe', '2021-01-01'),
('Jane', 'Smith', '2021-02-15'),
('Michael', 'Johnson', '2021-03-10'),
('Emily', 'Williams', '2021-04-22'),
('David', 'Brown', '2021-05-05'),
('Sarah', 'Jones', '2021-06-12'),
('Daniel', 'Davis', '2021-07-18'),
('Jessica', 'Miller', '2021-08-25'),
('Christopher', 'Wilson', '2021-09-30'),
('Olivia', 'Anderson', '2021-10-15');


INSERT INTO menu(product_name, price) VALUES
('Pizza', 9.99),
('Burger', 5.99),
('Salad', 7.99),
('Pasta', 12.99),
('Sandwich', 6.99),
('Steak', 15.99),
('Sushi', 10.99),
('Chicken Wings', 8.99),
('Fish and Chips', 11.99),
('Ice Cream', 4.99);

select customer_id from members;

INSERT INTO sales(customer_id,order_date,product_id) VALUES
(1001, '2021-01-01', 2001),
(1002, '2021-02-15', 2002),
(1003, '2021-03-10', 2001),
(1004, '2021-04-22', 2003),
(1005, '2021-05-05', 2002),
(1006, '2021-06-12', 2004),
(1007, '2021-07-18', 2003),
(1008, '2021-08-25', 2005),
(1009, '2021-09-30', 2004),
(1000, '2021-10-15', 2001),
(1002, '2021-02-20', 2003),
(1004, '2021-04-30', 2001),
(1006, '2021-06-15', 2002),
(1008, '2021-08-27', 2004),
(1000, '2021-10-20', 2003),
(1001, '2021-01-05', 2005),
(1003, '2021-03-15', 2004),
(1005, '2021-05-08', 2001),
(1007, '2021-07-20', 2002),
(1009, '2021-09-25', 2003),
(1001, '2021-01-10', 2002),
(1003, '2021-03-20', 2003),
(1005, '2021-05-12', 2001),
(1007, '2021-07-25', 2004),
(1009, '2021-09-28', 2005),
(1001, '2021-01-15', 2004),
(1003, '2021-03-25', 2001),
(1005, '2021-05-18', 2002),
(1007, '2021-07-30', 2003),
(1009, '2021-09-30', 2004);




-- 1. What is the total amount each customer spent at the restaurant?

SELECT m.customer_id, m.first_name, m.last_name, round(sum(price),2) AS total_spent
FROM members m
JOIN sales s 
ON m.customer_id = s.customer_id
JOIN menu mn 
ON s.product_id = mn.product_id
GROUP BY m.customer_id
ORDER BY total_spent DESC;

-- 2. How many days has each customer visited the restaurant?

SELECT m.customer_id, m.first_name, m.last_name, count(s.order_date) as days_visited
FROM members m
JOIN sales s 
ON m.customer_id = s.customer_id
GROUP BY m.customer_id
ORDER BY days_visited DESC;


-- 3. What was the first item from the menu purchased by each customer?

WITH customer_first_purchase AS(
SELECT customer_id, min(order_date) AS first_purchase_date
FROM sales
GROUP BY customer_id)

SELECT m.customer_id, m.first_name, m.last_name, product_name
FROM members m
JOIN customer_first_purchase cf
ON m.customer_id = cf.customer_id
JOIN sales s
ON cf.customer_id = s.customer_id
AND cf.first_purchase_date = s.order_date
JOIN menu mn
ON s.product_id = mn.product_id;



-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

# gives us the most orderd item
select product_id, count(product_id) as popular_item
FROM sales
GROUP BY product_id
ORDER BY popular_item DESC;

SELECT m.customer_id, m.first_name, m.last_name, mn.product_name, count(s.product_id) as number_of_purchase
FROM members m
JOIN sales s
ON m.customer_id = s.customer_id
JOIN menu mn
ON s.product_id = mn.product_id
WHERE s.product_id IN (2001,2003,2004)
GROUP BY m.customer_id, mn.product_name;


-- 5. Which item was the most popular for each customer?

with product_popularity AS 
(SELECT s.customer_id, m.first_name, m.last_name, mn.product_name, count(*) AS purchase_count,
DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY count(*) DESC) AS ranks
FROM members m
JOIN sales s 
ON m.customer_id = s.customer_id
JOIN menu mn
ON s.product_id = mn.product_id
GROUP BY s.customer_id, m.first_name, m.last_name, mn.product_name)

SELECT customer_id, first_name, last_name, product_name, purchase_count 
FROM product_popularity
WHERE ranks = 1;


-- 6. Which item was purchased first by the customer after they became a member?


WITH first_purchased AS 
(select m.customer_id, s.order_date, s.product_id, row_number() OVER (PARTITION BY customer_id) as first_date
FROM sales s
JOIN members m
on s.customer_id = m.customer_id
WHERE s.order_date > m.join_date
ORDER BY first_date)

select fp.customer_id, fp.order_date, mn.product_name
FROM first_purchased fp
JOIN menu mn
ON fp.product_id = mn.product_id
WHERE first_date = 1;




-- 7. Which item was purchased just before the customer became a member?
WITH purchase_date_before_member AS
(SELECT m.customer_id, m.first_name,m.last_name, s.order_date, mn.product_name,
DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY s.order_date DESC) AS before_cust_purchdate
FROM members m
JOIN sales s
ON m.customer_id = s.customer_id
JOIN menu mn
ON s.product_id = mn.product_id
WHERE s.order_date < m.join_date)

SELECT customer_id, first_name,last_name, order_date, product_name
FROM purchase_date_before_member
WHERE before_cust_purchdate = 1;


-- 8. What is the total items and amount spent for each member before they became a member?

WITH order_before_member AS 
(SELECT m.customer_id, m.first_name, m.last_name, s.order_date, s.product_id
FROM members m 
JOIN sales s
ON m.customer_id = s.customer_id
where s.order_date < m.join_date)

SELECT customer_id, first_name, last_name, concat('$',(round(sum(mn.price),2))) AS total_spent
FROM order_before_member bm
JOIN menu mn
ON bm.product_id = mn.product_id
GROUP BY customer_id;




-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT m.customer_id, m.first_name, m.last_name, round(sum(CASE
	WHEN mn.product_name = 'Sushi' THEN 20 * mn.price 
	ELSE 10 * mn.price
END),2) total_points
FROM members m
JOIN sales s
ON m.customer_id = s.customer_id
JOIN menu mn 
ON s.product_id = mn.product_id
GROUP BY m.customer_id;



/* 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
how many points do customer A and B have at the end of January?*/

SELECT s.customer_id, m.first_name, m.last_name, sum(
CASE
	WHEN s.order_date BETWEEN m.join_date AND DATE_ADD(m.join_date, INTERVAL 7 DAY) THEN round(mn.price * 20,2)
    WHEN mn.product_name = 'Sushi' THEN round(mn.price * 20,2)
    ELSE round(mn.price * 10,2)
END) AS total_points
FROM sales s
JOIN menu mn
ON s.product_id = mn.product_id
LEFT JOIN members m
ON s.customer_id = m.customer_id
GROUP BY s.customer_id;

-- 11. Recreate the table output using the available data
SELECT m.customer_id, m.first_name, m.last_name, s.order_date, mn.product_name, mn.price, 
CASE
	WHEN s.order_date >= m.join_date THEN 'Y'
    ELSE 'N'
END AS customer
FROM sales s
LEFT JOIN members m
ON s.customer_id = m.customer_id
JOIN menu mn
ON s.product_id = mn.product_id
ORDER BY m.customer_id, s.order_date;




