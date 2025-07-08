CREATE OR REPLACE TABLE `Instacart_processed_data.user_1_order_behavior` AS
WITH first_order AS (
  SELECT
    o.user_id,
    o.order_id,
    o.order_dow,
    o.order_hour_of_day
  FROM `Instacart_Raw_Data.Orders` o
  WHERE o.order_number = 1
),

product_stats AS (
  SELECT
    fo.user_id,
    COUNT(opp.product_id) AS total_products,
    COUNT(DISTINCT p.aisle_id) AS distinct_aisles
  FROM first_order fo
  JOIN `Instacart_Raw_Data.order_product_prior` opp
    ON fo.order_id = opp.order_id
  JOIN `Instacart_Raw_Data.Products` p
    ON opp.product_id = p.product_id
  GROUP BY fo.user_id
),

time_buckets AS (
  SELECT
    user_id,
    CASE
      WHEN order_hour_of_day BETWEEN 5 AND 11 THEN 'Morning'
      WHEN order_hour_of_day BETWEEN 12 AND 17 THEN 'Afternoon'
      WHEN order_hour_of_day BETWEEN 18 AND 22 THEN 'Evening'
      ELSE 'Night'
    END AS order_time_segment,
    CASE
      WHEN order_dow IN (0, 6) THEN 'Weekend'
      ELSE 'Weekday'
    END AS order_day_segment
  FROM first_order
)

SELECT
  ps.user_id,
  ps.total_products,
  ps.distinct_aisles,
  tb.order_time_segment,
  tb.order_day_segment
FROM product_stats ps
JOIN time_buckets tb
USING (user_id);
