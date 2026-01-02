# 1. How many unique post types are found in the 'fact_content' table?
SELECT DISTINCT post_type FROM fact_content;

##  What are the highest and lowest recorded impressions for each post type?
SELECT post_type,
MAX(impressions) AS highest_impression,
MIN(impressions) AS lowest_impression
FROM fact_content
GROUP BY post_type;

## Filter all the posts that were published on a weekend in the month of 
## March and April and export them to a separate csv file.

SELECT c.date, d.month_name, d.weekday_name, d.weekday_or_weekend, d.week_no,
c.post_category, c.post_type, c.video_duration, c.carousel_item_count,
c.impressions, c.reach, c.shares, c.follows, c.likes, c.comments, c.saves
FROM fact_content AS c
JOIN dim_dates AS d
ON c.date = d.date
WHERE d.month_name IN ('March', 'April')
AND d.weekday_or_weekend = 'Weekend';

## Create a report to get the statistics for the account. The final output 
## includes the following fields: month_name, total_profile_visits, total_new_followers

SELECT d.month_name,
SUM(a.profile_visits) AS total_profile_visits,
SUM(a.new_followers) AS total_new_followers
FROM fact_account AS a
JOIN dim_dates AS d
ON a.date = d.date
GROUP BY d.month_name;

## Write a CTE that calculates the total number of 'likes’ for each 
## 'post_category' during the month of 'July' and subsequently, arrange the 
## 'post_category' values in descending order according to their total likes.

WITH contentbydate AS (SELECT
c.date, d.month_name, d.weekday_name, d.weekday_or_weekend, d.week_no,
c.post_category, c.post_type, c.video_duration, c.carousel_item_count,
c.impressions, c.reach, c.shares, c.follows, c.likes, c.comments, c.saves
FROM fact_content AS c
JOIN dim_dates AS d
ON c.date = d.date
WHERE month_name="July")

SELECT post_category, SUM(likes) AS total_likes
FROM contentbydate
GROUP BY post_category
ORDER BY total_likes DESC;

## Create a report that displays the unique post_category names alongside 
## their respective counts for each month. The output should have three 
## columns:  
## • month_name 
## • post_category_names  
## • post_category_count 
## Example:  
## • 'April', 'Earphone,Laptop,Mobile,Other Gadgets,Smartwatch', '5' 
## • 'February', 'Earphone,Laptop,Mobile,Smartwatch', '4'

SELECT d.month_name,
GROUP_CONCAT(DISTINCT c.post_category ORDER BY c.post_category SEPARATOR ',') AS post_category_names,
COUNT(DISTINCT c.post_category) AS post_category_count
FROM fact_content AS c
JOIN dim_dates AS d
ON c.date = d.date
GROUP BY d.month_name
ORDER BY d.month_name;

## What is the percentage breakdown of total reach by post type?  The final 
## output includes the following fields: 
## • post_type 
## • total_reach 
## • reach_percentage 

SELECT c.post_type, SUM(c.reach) AS total_reach,
ROUND((SUM(c.reach) * 100.0)/(SELECT SUM(reach) FROM fact_content),2) AS reach_percentage
FROM fact_content AS c
GROUP BY c.post_type
ORDER BY total_reach DESC;

## Create a report that includes the quarter, total comments, and total saves recorded for each post category.
## Assign the following quarter groupings: (January, February, March) → “Q1” (April, May, June) → “Q2” (July, August, September) → “Q3” 
## The final output columns should consist of: post_category, quarter, total_comments, total_saves

SELECT c.post_category,
CASE
	WHEN d.month_name IN ('January', 'February', 'March') THEN 'Q1'
	WHEN d.month_name IN ('April', 'May', 'June') THEN 'Q2'
	WHEN d.month_name IN ('July', 'August', 'September') THEN 'Q3'
END AS quarter,
SUM(c.comments) AS total_comments,
SUM(c.saves) AS total_saves
FROM fact_content AS c
JOIN dim_dates AS d
ON c.date = d.date
WHERE d.month_name IN (
'January', 'February', 'March',
'April', 'May', 'June',
'July', 'August', 'September')
GROUP BY c.post_category, quarter
ORDER BY c.post_category, quarter;

## List the top three dates in each month with the highest number of new followers.
## The final output should include the following columns: month, date, new_followers

WITH ranked_followers AS (
SELECT d.month_name AS month,
c.date, c.new_followers,
ROW_NUMBER() OVER (PARTITION BY d.month_name
ORDER BY c.new_followers DESC
) AS rn
FROM fact_account AS c
JOIN dim_dates AS d
ON c.date = d.date
)
SELECT month, date, new_followers
FROM ranked_followers
WHERE rn <= 3
ORDER BY date,
new_followers DESC;

## Create a stored procedure that takes the 'Week_no' as input and 
## generates a report displaying the total shares for each 'Post_type'. The 
## output of the procedure should consist of two columns: • post_type, • total_shares

##Stored Proc:
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_total_shares_by_week`(IN p_week_no VARCHAR(5))
BEGIN
SELECT c.post_type, SUM(c.shares) AS total_shares
FROM fact_content AS c
JOIN dim_dates AS d
ON c.date = d.date
WHERE d.week_no = p_week_no
GROUP BY c.post_type
ORDER BY total_shares DESC;
END

CALL get_total_shares_by_week("W12");