-- REVIEW TOTAL NUMBER OF IMPORTED ROWS FOR EACH TABLE
SELECT
	'admissions' AS table_name,
	COUNT(*)
FROM
	staging.hdhi_admission_raw
UNION ALL
SELECT
	'mortality',
	COUNT(*)
FROM
	staging.hdhi_mortality_raw
UNION ALL
SELECT
	'pollution',
	COUNT(*)
FROM
	staging.hdhi_pollution_raw hpr
UNION ALL
SELECT
	'headings',
	COUNT(*)
FROM
	staging.table_headings_raw thr ;
-- STAGING MORTALITY INSPECTION
-- REVIEW CATEGORIES IN THE TABLE
SELECT
	gender,
	COUNT(*)
FROM
	staging.hdhi_mortality_raw
GROUP BY
	gender
ORDER BY
	COUNT(*) DESC;
-- OK: only M and F, no issues
-- CHECK THE CATEGORIES DISPLAYED FOR rural_urban COLUMN
SELECT
	rural_urban,
	COUNT(*)
FROM
	staging.hdhi_mortality_raw
GROUP BY
	rural_urban
ORDER BY
	COUNT(*) DESC;
-- ISSUE: rural_urban = R seems to be repeated twice, same as U. Probably not grouped correctly or something affecting the group by.
-- CHECK IF EVERY mrd (admission number) is actually a number
SELECT
	mrd,
	COUNT(*)
FROM
	staging.hdhi_mortality_raw
WHERE
	mrd !~ '^[0-9]+$'
GROUP BY
	mrd;
-- ISSUE: It seems there is one row that contains '***' as mrd.
-- CHECK IF ANY admission number (mrd) is repeated 
SELECT
	mrd,
	COUNT(*)
FROM
	staging.hdhi_mortality_raw
GROUP BY
	mrd
HAVING
	COUNT(*) > 1;
-- ISSUE: There are 6 mrd numbers that appear twice in the table.
-- CHECK IF ALL admission numbers ARE THE SAME LENGTH
SELECT
	LENGTH(mrd) AS id_length,
	COUNT(*)
FROM
	staging.hdhi_mortality_raw
GROUP BY
	length(mrd)
ORDER BY
	id_length;
-- OBSERVATION: mrd goes from 3 up to 7 digits in lenght
-- STAGING MORTALITY INSPECTION
