CREATE OR REPLACE TABLE `Instacart_processed_data.user_survival_data` AS
WITH user_stats AS (
  SELECT
    o.user_id,
    COUNT(*) AS order_count,
    SUM(IFNULL(o.days_since_prior_order, 0)) AS total_days,
    MAX(IFNULL(o.days_since_prior_order, 0)) AS max_gap
  FROM `Instacart_Raw_Data.Orders` o
  GROUP BY o.user_id
),

-- Define churned user based on max_gap (e.g. > 30 days)
add_churn_flag AS (
  SELECT
    user_id,
    order_count,
    total_days,
    max_gap,
    CASE WHEN max_gap >= 30 THEN 1 ELSE 0 END AS churned
  FROM user_stats
),

-- User segment labels (from clustering result)
user_segments AS (
  SELECT
    user_id,
    segment_name
  FROM `Instacart_processed_data.user_segments_labeled`  -- replace with actual name
)

-- Final user survival data
SELECT
  s.user_id,
  u.segment_name,
  s.order_count,
  s.total_days,
  s.max_gap,
  s.churned
FROM add_churn_flag s
LEFT JOIN user_segments u
ON s.user_id = u.user_id;
