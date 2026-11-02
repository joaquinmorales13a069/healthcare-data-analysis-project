-- STAGING POLLUTION INSPECTION
-- CHECK prominent_pollution CATEGORIES
	SELECT
	hpr.prominent_pollutant,
	COUNT(*)
FROM
	staging.hdhi_pollution_raw hpr
GROUP BY
	hpr.prominent_pollutant
ORDER BY
	count(*) DESC;
-- OBSERVATIONS: The whole table seems correctly distributed SO2, PM2.5, PM10, NO2 and CO
-- CHECK DATE FORMAT on date 
	SELECT
	COUNT(*)
FROM
	staging.hdhi_pollution_raw
WHERE
	SPLIT_PART("date", '/', 1)::INTEGER > 12;
-- OBSERVATION: no first part > 12, and the 184 two-digit rows match Oct-Dec (92 days x 2 years).
-- Likely a single M/D/YYYY format. Confirm in validation (737 distinct consecutive dates).
-- CHECK DATE UNIQUENESS
	SELECT
	hpr."date",
	count(*)
FROM
	staging.hdhi_pollution_raw hpr
GROUP BY
	"date"
HAVING
	count(hpr."date" ) > 1;
-- OBSERVATION: No duplicated dates in the table
-- CHECK MIN AND MAX OF aqi 
	SELECT
	MIN(hpr.aqi::INTEGER),
	MAX(hpr.aqi::INTEGER)
FROM
	staging.hdhi_pollution_raw hpr;
-- OBSERVATION: aqi value ranges from 28 to 797. India air quality goes from 1 to 500
-- CHECK HOW MANY aqi values are outside the range of 1 to 500
	SELECT
	hpr.aqi,
	count(*)
FROM
	staging.hdhi_pollution_raw hpr
WHERE
	hpr.aqi::INTEGER > 500
GROUP BY
	hpr.aqi
ORDER BY
	count(*) DESC;
-- OBSERVATIONS: There are 2 rows where the values of aqi are higher than 500 (797: 1 and 769: 1)
