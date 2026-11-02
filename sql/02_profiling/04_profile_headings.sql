-- STAGING TABLE HEADINGS INSPECTION
-- CHECK CODE AND EXPLANATORY NAME FOR ALL APPLICABLE ROWS
SELECT
	'[' || column_code || ']' AS code,
	explanatory_name
FROM
	staging.table_headings_raw
WHERE
	column_code <> '';
---- OBSERVATIONS:
-- 58 rows with content: 56 column definitions + 2 extra rows.
-- 'SMOKING ' has a trailing space. Fix: TRIM().
-- 'Other Abbreveiations' is a section label, not a column. Remove.
-- 'DAMA' is not a column, it's a value of admissions.outcome
--   (Discharged Against Medical Advice). Keep as a note for question 2.


-- CHECK FOR UNIQUENESS IN TABLE column_code
SELECT
	column_code,
	COUNT(*)
FROM
	staging.table_headings_raw
WHERE
	column_code != ''
GROUP BY
	column_code
HAVING
	COUNT(*) > 1;
-- OBSERVATION: all column_codes are unique
-- CHECK FOR UNIQUENESS IN TABLE explanatory_name
SELECT
	explanatory_name ,
	COUNT(*)
FROM
	staging.table_headings_raw
WHERE
	explanatory_name != ''
GROUP BY
	explanatory_name
HAVING
	COUNT(*) > 1;
-- CHECK AND COUNT HOW MANY EMPTY VALUES THERE ARE IN HEADING TABLE
SELECT
	COUNT(*)
FROM
	staging.table_headings_raw
WHERE
	column_code = '';
-- OBSERVATIONS: the table has 16326 rows with empty column_code
-- CHECK AND COUNT HOW MANY EMPTY VALUES THERE ARE IN HEADING TABLE
SELECT
	COUNT(*)
FROM
	staging.table_headings_raw
WHERE
	explanatory_name = '';
-- OBSERVATIONS: the table has 16327 rows with empty explanatory_name
-- FINDING THE DIFFERENCE BETWEEN EMPTY column_code AND explanatory_name
SELECT
	*
FROM
	staging.table_headings_raw
WHERE
	column_code <> ''
	AND explanatory_name = '';
-- OBSERVATIONS: The column_code without explanatory_name is Other Abbreveiations.
