use dannys_diner;


CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
  
CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


-- 1. What is the total amount each customer spent at the restaurant?
select s.customer_id,sum(m.price) as spent
from dannys_diner.sales as s
join dannys_diner.menu as m
on s.product_id=m.product_id
group by s.customer_id;

-- 2. How many days has each customer visited the restaurant?
select customer_id,count(distinct order_date) as times_visited
from dannys_diner.sales 
group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?
with final as(
	select s.customer_id,m.product_name,
	rank() over (partition by s.customer_id order by s.order_date) as date_rank
	from dannys_diner.sales as s
	join dannys_diner.menu as m
	on s.product_id=m.product_id)
select *
from final
where date_rank=1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
with final as (
	select product_name,count(m.product_name) as times_ordered,
	rank() over (order by count(m.product_name) desc) as ranking
	from dannys_diner.sales as s
	join dannys_diner.menu as m
	on s.product_id=m.product_id
	group by product_name)
select product_name,times_ordered
from final
where ranking =1;

-- 5. Which item was the most popular for each customer?
with final as (
	select 
		s.customer_id,
        m.product_name,
        count(*) as total
	from 
		dannys_diner.sales as s
		join dannys_diner.menu as m on s.product_id=m.product_id
	group by 
		s.customer_id , 
        m.product_name
	)
select 
	customer_id,
    product_name
from ( 
	select 
		customer_id,
		product_name,
		rank() over (partition by customer_id order by total) as ranking
	from 
        final
	) as ranked_data
where 
	ranking=1;

-- 6. Which item was purchased first by the customer after they became a member?
with final as (
	select s.customer_id,s.product_id,
		rank() over (partition by s.customer_id order by order_date desc) as ranking
	from dannys_diner.sales as s
		 left join dannys_diner.members as m on s.customer_id=m.customer_id
	where s.order_date>=m.join_date
	)
select f.customer_id,mn.product_name
from final as f
    left join dannys_diner.menu as mn on f.product_id=mn.product_id
where ranking=1;

-- 7. Which item was purchased just before the customer became a member?
with final as (
	select s.customer_id,s.product_id,
		rank() over (partition by s.customer_id order by order_date desc) as ranking
	from dannys_diner.sales as s
		 left join dannys_diner.members as m on s.customer_id=m.customer_id
	where s.order_date<m.join_date
	)
select f.customer_id,mn.product_name
from final as f
    left join dannys_diner.menu as mn on f.product_id=mn.product_id
where ranking=1;

-- 8. What is the total items and amount spent for each member before they became a member?
with final as (
	select a.customer_id,a.product_id,order_date,price,join_date,product_name
	from dannys_diner.sales as a
		left join dannys_diner.menu as b
		on a.product_id=b.product_id
		right join dannys_diner.members as c
		on a.customer_id=c.customer_id
	where join_date>order_date
)
select customer_id,sum(price) as total_spent,count(distinct product_name) as total_items
from final
group by customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with final as (
select a.customer_id,order_date,a.product_id,product_name,price,
	   case when product_name="sushi" then price*20
       else price*10 end as points
from dannys_diner.sales as a
	 join dannys_diner.menu as b
     on a.product_id=b.product_id
)
select customer_id,sum(points)
from final
group by customer_id;

/*10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
- how many points do customer A and B have at the end of January?*/
with final as (
select a.customer_id,a.product_id,order_date,price,join_date,product_name,
	   case when (a.order_date between c.join_date and (c.join_date+ interval 6 day)) or product_name="sushi" then price *20
       else price*10 end as points 
from dannys_diner.sales as a
	left join dannys_diner.menu as b
	on a.product_id=b.product_id
	right join dannys_diner.members as c
	on a.customer_id=c.customer_id
where a.order_date<='2021-01-31'
)
select customer_id,sum(points)
from final
group by customer_id









































