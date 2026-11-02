-- STAGING ADMISSIONS INSPECTION
-- CHECK GENDER CATEGORY
SELECT
	gender,
	COUNT(*)
FROM
	staging.hdhi_admission_raw
GROUP BY
	gender
ORDER BY
	COUNT(*) DESC;
-- OK: Only 2 genders M and F
-- CHECK RURAL CATEGORY 
SELECT
	rural ,
	COUNT(*)
FROM
	staging.hdhi_admission_raw
GROUP BY
	rural
ORDER BY
	COUNT(*) DESC;
-- OK: Only 2 types of Rural U and R.
-- CHECK TYPE OF ADMISSION CATEGORY
SELECT
	type_of_admission ,
	COUNT(*)
FROM
	staging.hdhi_admission_raw
GROUP BY
	type_of_admission
ORDER BY
	COUNT(*) DESC;
-- OK: Only 2 types of Admission E and O
-- CHECK outcome CATEGORY
SELECT
	outcome ,
	COUNT(*)
FROM
	staging.hdhi_admission_raw
GROUP BY
	outcome
ORDER BY
	COUNT(*) DESC;
-- OK: 3 Categories for outcome: DISCHARGE, EXPIRY and DAMA
-- CHECK IF EVERY mrd (admission number) is actually a number
SELECT
	har.mrd_no ,
	COUNT(*)
FROM
	staging.hdhi_admission_raw har
WHERE
	har.mrd_no !~ '^[0-9]+$'
GROUP BY
	har.mrd_no ;
-- ISSUE: There is 1 record with NILL mrd_no
-- CHECK sno UNIQUENESS
SELECT
	har.sno,
	count(*)
FROM
	staging.hdhi_admission_raw har
GROUP BY
	har.sno
HAVING
	COUNT(*) > 1;
-- CHECK mrd_no UNIQUENESS
SELECT
	har.mrd_no,
	count(*)
FROM
	staging.hdhi_admission_raw har
GROUP BY
	har.mrd_no
HAVING
	COUNT(*) > 1;
-- OBSERVATION: SEVERAL admission_numbers are listed more than once in the whole table. MAX 3 and MIN 1
-- CHECK IF ALL admission numbers ARE THE SAME LENGTH
SELECT
	LENGTH(har.mrd_no) AS id_length,
	COUNT(*)
FROM
	staging.hdhi_admission_raw har
GROUP BY
	length(har.mrd_no)
ORDER BY
	id_length;
-- OBSERVATION: mrd_no ranges from 3 to 7 digits. Outliers likely typos, flag only.
-- CHECK IF ALL ADMISSIONS AGE ARE IN A REASONABLE FRAME
SELECT
	MIN(har.age::INTEGER) AS min_age,
	MAX(har.age::INTEGER)
FROM
	staging.hdhi_admission_raw har ;
-- OBSERVATION: MIN age is 4 years and MAX age is 110. FOLLOW UP: Check how many admissions have 110 years
-- LIST ALL ADMISSIONS WITH MORE THAN 100 YEARS
SELECT
	har.mrd_no,
	har.age
FROM
	staging.hdhi_admission_raw har
WHERE
	har.age::INTEGER > 100;
-- OK: The same patient that was 110 years was addmited twice.
-- CHECK DURATION OF STAY
SELECT
	MIN(duration_of_stay::INTEGER),
	MAX(duration_of_stay::INTEGER)
FROM
	staging.hdhi_admission_raw;
-- OK: Normal range from 1 day up to 98 days.
-- doa FORMAT CHECK
SELECT
	COUNT(*) FILTER (
	WHERE SPLIT_PART(doa, '/', 1)::INTEGER > 12) AS day_first,
	COUNT(*) FILTER (
	WHERE SPLIT_PART(doa, '/', 2)::INTEGER > 12) AS month_first,
	COUNT(*) AS total
FROM
	staging.hdhi_admission_raw;
-- ISSUE: doa has two formats (D/M/YYYY and M/D/YYYY). Rows where both parts are <= 12
-- can't be identified by this test alone. Solve in Phase 3.
