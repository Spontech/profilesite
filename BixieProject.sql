/*
Bixi Project - Part 1 - Data Analysis in SQL
Tanisha Batra
jsm.batra@outlook.com
*/

USE bixi;

-- QUESTION 1
-- 1.1 The total number of trips for the year of 2016.
SELECT 
    COUNT(*) as num_trips_2016
FROM
    trips
WHERE
    start_date < '2016-12-31 00:00:00.000'
        AND end_date > '2016-01-01 00:00:00.000'
;

-- 1.2 The total number of trips for the year of 2017.

SELECT 
    COUNT(*) as num_trips_2017
FROM
    trips
WHERE
    start_date < '2017-12-31 00:00:00.000'
        AND end_date > '2017-01-01 00:00:00.000'
;

-- 1.3 The total number of trips for the year of 2016 broken down by month
-- assuming the month is the start month of april, since no data is available for Jan, Feb and March

SELECT 
    MONTH(start_date) as Month, count(*) as num_trips_2016
FROM
    trips
WHERE
    start_date < '2016-12-31 00:00:00.000'
        AND end_date > '2015-01-01 00:00:00.000'
GROUP BY MONTH(start_date)
;

-- 1.4 The total number of trips for the year of 2017 broken down by month.

SELECT 
    MONTH(start_date) as Month, count(*) as num_trips_2017
FROM
    trips
WHERE
    start_date < '2017-12-31 00:00:00.000'
        AND end_date > '2017-01-01 00:00:00.000'
GROUP BY MONTH(start_date)
;

--  1.5 The average number of trips a day for each year-month combination in the dataset.
-- the average spread across time, with time displayed as year and month
SELECT 
    DATE_FORMAT(start_date, '%Y-%m %M') AS time_ym,
    count(*) AS trips
FROM
    trips
GROUP BY time_ym
ORDER BY time_ym ASC
;

-- 1.6 Save your query results from the previous question (Q1.5) by creating a table called working_table1.
DROP TABLE IF EXISTS working_table1;
CREATE TABLE working_table1 AS 
SELECT 
    DATE_FORMAT(start_date, '%Y-%m %M') AS time_ym,
    COUNT(*) AS trips
FROM
    trips
GROUP BY time_ym
ORDER BY time_ym ASC
LIMIT 100
;

-- QUESTION 2
-- Unsurprisingly, the number of trips varies greatly throughout the year. 
-- How about membership status? Should we expect member and non-member to behave differently? To start investigating that, calculate:

-- 2.1 The total number of trips in the year 2017 broken down by membership status (member/non-member).
SELECT 
    is_member as membership_status, count(*) as num_trips_2017
FROM
    trips
WHERE -- condition for the year 2017
    start_date < '2017-12-31 00:00:00.000'
        AND end_date > '2017-01-01 00:00:00.000'
GROUP BY membership_status
;

-- 2.2 The percentage of total trips by members for the year 2017 broken down by month.

SELECT 
    (COUNT(*) / (SELECT 
            COUNT(*)
        FROM
            trips)) * 100 AS percent -- multiply by 100 to see as a %
FROM
    trips
GROUP BY MONTH(start_date)
LIMIT 200;

-- QUESTION 3
-- Question 3 is answered in more detail on the report document

-- QUESTION 4
-- 1. What are the names of the 5 most popular starting stations? Determine the answer without using a subquery.

-- joining with the common key
SELECT 
    name, COUNT(*) AS num_trips
FROM
    stations
        INNER JOIN
    trips ON stations.code = trips.start_station_code
GROUP BY name
ORDER BY num_trips DESC
LIMIT 5;

-- 2. Solve the same question as Q 4.1, but now use a subquery. Is there a difference in query run time between 4.1 and 4.2? Why or why not?

SELECT 
    trips_sub.name
FROM
    trips
        INNER JOIN
    (SELECT 
        *
    FROM
        stations) AS trips_sub ON trips.start_station_code = trips_sub.code
GROUP BY name
ORDER BY trips_sub.name DESC
;

-- subquery got executed way faster!
/*
 Using a subquery lead to a much faster execution time. 
 This is because the all the grouping by name and ordering happens on a subset of the data, 
 which is much smaller than the overall dataset. Less data to parse through means faster results!
*/

-- QUESTION 5

-- 5.1 How is the number of starts and ends distributed for the station Mackay / de Maisonneuve throughout the day?
-- my interpretation is from 2016 - 2017, not the average per day

SELECT 
    name,
    COUNT(start_date),
    COUNT(end_date),
    CASE
        WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN 'morning'
        WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN 'afternoon'
        WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN 'evening'
        ELSE 'night'
    END AS 'time_of_day'
FROM
    trips
        LEFT JOIN
    stations ON trips.start_station_code
        AND stations.code
WHERE
    name = 'Mackay / de Maisonneuve'
GROUP BY time_of_day
;


-- QUESTION 6
/*
List all stations for which at least 10% of trips are round trips. 
Round trips are those that start and end in the same station. 
This time we will only consider stations with at least 500 starting trips. (Please include answers for all steps outlined here)
*/

-- 6.1 First, write a query that counts the number of starting trips per station.
SET GLOBAL interactive_timeout=90;
SELECT 
    stations.name, COUNT(start_date)
FROM
    trips
        INNER JOIN
    stations ON stations.code = trips.start_station_code
GROUP BY stations.name
;

-- 6.2 Second, write a query that counts, for each station, the number of round trips.
select stations.name, count(start_date)
from trips
INNER JOIN stations on
stations.code =  trips.start_station_code
WHERE start_station_code = end_station_code
GROUP BY stations.name
;


-- 6.3 Combine the above queries and calculate the fraction of round trips to the total number of starting trips for each station.
USE bixi;

select name, b.rtrips / c.atrips as percent
from stations
join (select count(start_date) as rtrips, start_station_code as ssc
from trips
WHERE start_station_code = end_station_code
GROUP BY start_station_code) as b on stations.code = b.ssc
join (select count(start_date) as atrips, start_station_code as nrt
from trips
GROUP BY start_station_code) as c on stations.code = c.nrt
group by stations.name
;

-- 6.4 Filter down to stations with at least 500 trips originating from them and having at least 10% of their trips as round trips.

SELECT 
    name, b.rtrips / c.atrips AS fraction
FROM
    stations
        JOIN
    (SELECT 
        COUNT(start_date) AS rtrips, start_station_code AS ssc
    FROM
        trips
    WHERE
        start_station_code = end_station_code
    GROUP BY start_station_code) AS b ON stations.code = b.ssc
        JOIN
    (SELECT 
        COUNT(start_date) AS atrips, start_station_code AS nrt
    FROM
        trips
    GROUP BY start_station_code) AS c ON stations.code = c.nrt
WHERE
    c.atrips > 500
        AND b.rtrips / c.atrips > 0.1
GROUP BY stations.name
ORDER BY fraction DESC
;

-- 6.5 Where would you expect to find stations with a high fraction of round trips? Describe why and justify your reasoning.

SELECT 
    name,
    AVG(latitude),
    AVG(longitude),
    b.rtrips / c.atrips AS percent
FROM
    stations
        JOIN
    (SELECT 
        COUNT(start_date) AS rtrips, start_station_code AS ssc
    FROM
        trips
    WHERE
        start_station_code = end_station_code
    GROUP BY start_station_code) AS b ON stations.code = b.ssc
        JOIN
    (SELECT 
        COUNT(start_date) AS atrips, start_station_code AS nrt
    FROM
        trips
    GROUP BY start_station_code) AS c ON stations.code = c.nrt
GROUP BY stations.name
ORDER BY percent DESC
LIMIT 10
;

-- References
-- Learning datetime data type https://stackoverflow.com/questions/1947436/datetime-in-where-clause
-- syntax of month function https://stackoverflow.com/questions/14565788/how-to-group-by-month-from-date-field-using-sql
-- year month combo https://stackoverflow.com/questions/1781946/getting-only-month-and-year-from-sql-date