-- Superstore Retail Performance Analysis
-- Note: written for SQLite; swap strftime()/julianday() for
-- DATE_TRUNC()/date subtraction if porting to Postgres.

-- Q1: Month-over-month sales growth by region
WITH monthly_sales AS (
  SELECT strftime('%Y-%m', order_date) AS month,
         region,
         SUM(sales) AS total_sales
  FROM orders
  GROUP BY 1, 2
)
SELECT month, region, total_sales,
       LAG(total_sales) OVER (PARTITION BY region ORDER BY month) AS prev_month,
       ROUND(100.0 * (total_sales - LAG(total_sales) OVER (PARTITION BY region ORDER BY month))
             / NULLIF(LAG(total_sales) OVER (PARTITION BY region ORDER BY month), 0), 1) AS mom_growth_pct
FROM monthly_sales
ORDER BY region, month;

-- Q2: Profit margin by sub-category
WITH sub_cat_profit AS (
  SELECT p.category, p.sub_category,
         SUM(o.sales) AS total_sales,
         SUM(o.profit) AS total_profit
  FROM orders o
  JOIN products p ON o.product_id = p.product_id
  GROUP BY 1, 2
)
SELECT *, ROUND(100.0 * total_profit / NULLIF(total_sales,0), 1) AS profit_margin_pct
FROM sub_cat_profit
ORDER BY profit_margin_pct ASC;

-- Q3: Customer LTV ranked within segment
WITH customer_value AS (
  SELECT c.customer_id, c.customer_name, c.segment, SUM(o.sales) AS ltv
  FROM orders o
  JOIN customers c ON o.customer_id = c.customer_id
  GROUP BY 1, 2, 3
)
SELECT *, RANK() OVER (PARTITION BY segment ORDER BY ltv DESC) AS ltv_rank
FROM customer_value
ORDER BY segment, ltv_rank
LIMIT 30;

-- Q4: Top 5 loss-making sub-categories
SELECT p.sub_category, SUM(o.profit) AS total_profit
FROM orders o JOIN products p ON o.product_id = p.product_id
GROUP BY 1
ORDER BY total_profit ASC
LIMIT 5;

-- Q5: Discount level vs avg profit margin
SELECT
  CASE
    WHEN discount = 0 THEN '0%'
    WHEN discount <= 0.2 THEN '1-20%'
    WHEN discount <= 0.4 THEN '21-40%'
    ELSE '40%+'
  END AS discount_bucket,
  ROUND(AVG(profit / NULLIF(sales,0)) * 100, 1) AS avg_margin_pct,
  COUNT(*) AS n_orders
FROM orders
GROUP BY 1
ORDER BY 1;

-- Q6: Top 10 customers by lifetime value
SELECT c.customer_name, SUM(o.sales) AS ltv
FROM orders o JOIN customers c ON o.customer_id = c.customer_id
GROUP BY 1
ORDER BY ltv DESC
LIMIT 10;

-- Q7: Repeat purchase rate by cohort month
WITH first_order AS (
  SELECT customer_id, MIN(order_date) AS first_date
  FROM orders GROUP BY 1
),
cohort AS (
  SELECT f.customer_id, strftime('%Y-%m', f.first_date) AS cohort_month,
         COUNT(DISTINCT o.order_id) AS n_orders
  FROM first_order f
  JOIN orders o ON o.customer_id = f.customer_id
  GROUP BY 1, 2
)
SELECT cohort_month,
       COUNT(*) AS customers,
       SUM(CASE WHEN n_orders > 1 THEN 1 ELSE 0 END) AS repeat_customers,
       ROUND(100.0 * SUM(CASE WHEN n_orders > 1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS repeat_rate_pct
FROM cohort
GROUP BY 1
ORDER BY 1;

-- Q8: Shipping mode vs avg delivery delay
SELECT ship_mode,
       ROUND(AVG(julianday(ship_date) - julianday(order_date)), 1) AS avg_delivery_days
FROM orders
GROUP BY 1
ORDER BY avg_delivery_days;

-- Q9: Category profitability vs sales volume
SELECT p.category,
       SUM(o.sales) AS total_sales,
       SUM(o.profit) AS total_profit,
       ROUND(100.0 * SUM(o.profit) / NULLIF(SUM(o.sales),0), 1) AS margin_pct
FROM orders o JOIN products p ON o.product_id = p.product_id
GROUP BY 1
ORDER BY total_sales DESC;

-- Q10: State-level sales concentration (Pareto)
WITH state_sales AS (
  SELECT state, SUM(sales) AS total_sales
  FROM orders GROUP BY 1
),
ranked AS (
  SELECT *, SUM(total_sales) OVER (ORDER BY total_sales DESC) AS running_total,
         SUM(total_sales) OVER () AS grand_total
  FROM state_sales
)
SELECT state, total_sales,
       ROUND(100.0 * running_total / grand_total, 1) AS cumulative_pct
FROM ranked
ORDER BY total_sales DESC
LIMIT 15;

-- Q11: Order frequency per customer segment
SELECT c.segment,
       COUNT(DISTINCT o.order_id) * 1.0 / COUNT(DISTINCT c.customer_id) AS avg_orders_per_customer
FROM orders o JOIN customers c ON o.customer_id = c.customer_id
GROUP BY 1;

-- Q12: Seasonal sales trend by month/year
SELECT strftime('%m', order_date) AS month_num,
       strftime('%Y', order_date) AS year,
       SUM(sales) AS total_sales
FROM orders
GROUP BY 1, 2
ORDER BY 1, 2;

