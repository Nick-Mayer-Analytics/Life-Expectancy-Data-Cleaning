
# 1st Project!!!!!!!!!!-----------------------------------------------------------------------------------------------

# Each has 2 phases: data cleaning and EDA

SELECT *
FROM 
world_life_expectancy
;

# 1.) Id'ing Duplicates - should only be 1 instance for a given country in a given year (only one Albania 2021 for example)-------------------------

SELECT Country, Year, CONCAT(Country,Year), COUNT(CONCAT(Country,Year))
FROM 
world_life_expectancy
GROUP BY Country, Year, CONCAT(Country,Year)
HAVING COUNT(CONCAT(Country,Year)) > 1
;

# 2.) Now that we have identified the duplicates we need to remove them--------------------------------------------

SELECT Row_ID,
CONCAT(Country,Year)
FROM world_life_expectancy
WHERE CONCAT(Country,Year) IN ('Ireland2022', 'Senegal2009', 'Zimbabwe2019')
;

# 3.) If we delete the 2nd instance, that means we need to delete rows 1252, 2265, and 2929

DELETE FROM world_life_expectancy
WHERE Row_ID IN (1252, 2265, 2929)
;

# Succesfully deleted those 3 rows

SELECT *
FROM 
world_life_expectancy
;

# 4.) Looks like we have some blanks in the Status column - let's see whats going on here 

SELECT *
FROM 
world_life_expectancy
WHERE Status = ''
;

# We should be be able to take the status for a country for a year where it is in fact populate and use that status for the blank instances 

SELECT DISTINCT(Status)
FROM world_life_expectancy
WHERE Status <> ''
;

# We only have 2 statuses: developed and developing

SELECT DISTINCT(Country)
FROM world_life_expectancy
WHERE Status = 'Developing'
;

# 5.) ^ all of the countries that have 'developing status' - using this as a reference to populate the country/year combinations that are missing status

UPDATE world_life_expectancy 
SET Status = 'Developing'
WHERE Country IN (
	SELECT DISTINCT(Country)
	FROM world_life_expectancy
	WHERE Status = 'Developing'
    )
;

# Getting an error because of the sub-query in the update statement - using an inner join in the update statement as a workaround

UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
SET t1.Status = 'Developing'
WHERE t1.Status = ''
AND t2.Status <> ''
AND t2.Status = 'Developing'
;

# Logic example -> When we join to itself we can filter off of the other table; If Albania is equal to Albania in line 78, if the status in t1 is blank but the status in t2 is not, and the 
# t2 status is developing, we can set the status in t1 to developing as well 

# Let's see if that worked

SELECT *
FROM 
world_life_expectancy
WHERE Country = 'United States of America'
;

# 6.) We need to do the same for "Developed"

UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
SET t1.Status = 'Developed'
WHERE t1.Status = ''
AND t2.Status <> ''
AND t2.Status = 'Developed'
;

SELECT *
FROM 
world_life_expectancy
WHERE Country = 'United States of America'
;

# 7.) Re-confirming that there are no blanks or nulls 

SELECT *
FROM 
world_life_expectancy
WHERE Status = ''
OR
Status IS NULL
;

# Nice

SELECT *
FROM 
world_life_expectancy
;

# 8.) Looks like we need to address the missing values for life expectancy as well - one way to do this would be to find the average life expectancy for each country across all of the years and use that
# as a proxy value - what would that process look like:
# 1.) Find all country and year combos with a missing life expectancy 
# 2.) For each country find the average life expectancy across all years where that data is not missing 
# 3.) Update those instances of country/year combos with missing life expectancy with average life expectancy for that country 

SELECT Country, Year, `Life expectancy`
FROM world_life_expectancy
WHERE `Life expectancy` = ''
OR  `Life expectancy` IS NULL
;

# Looks like its only Albania and Afghanistan - lets find the average life expextancy for those 2 countries in all years where the life expectancy is not blank 

SELECT Country, Year, 
AVG(`Life expectancy`) OVER(PARTITION BY Year, Country) AS avg_life_expectancy
FROM world_life_expectancy
WHERE `Life expectancy` <> ''
;

# I think we need a window function here; my first approach isn't working
# populate the missing values with the average from the year before and the year after
# For Afghanistan that would be the avg of 2017 and 2019 and for Albania it would also be the avg of those 2 years
# another self join 

SELECT t1.Country, t1.Year, t1.`Life expectancy`,
t2.Country, t2.Year, t2.`Life expectancy`,
t3.Country, t3.Year, t3.`Life expectancy`,
ROUND((t2.`Life expectancy` + t3.`Life expectancy`) / 2,1)
FROM world_life_expectancy t1
JOIN world_life_expectancy t2
ON
	t1.Country = t2.Country
    AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3
ON
	t1.Country = t3.Country
    AND t1.Year = t3.Year + 1
WHERE t1.`Life expectancy` = ''
;

# After all of that we need tp take that rounded avg value and use it to populate our missing fields

UPDATE  world_life_expectancy t1
JOIN world_life_expectancy t2
ON
	t1.Country = t2.Country
    AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3
ON
	t1.Country = t3.Country
    AND t1.Year = t3.Year + 1
SET t1.`Life expectancy` = ROUND((t2.`Life expectancy` + t3.`Life expectancy`) / 2,1)
WHERE t1.`Life expectancy` = ''
;

SELECT Country, Year, `Life expectancy`
FROM world_life_expectancy
;

# This worked!! Let's go 

# So in this phase what all did we do? we:
# - Removed duplicates
# - Updated missing status (developed v. developing)
# - Updated missing life expectancies 




















