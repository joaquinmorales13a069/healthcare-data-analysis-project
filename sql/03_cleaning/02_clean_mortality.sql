-- CREATE TABLE FOR CLEAN MORTALITY DATA
CREATE TABLE IF NOT EXISTS clean.hdhi_mortality_cleaned (
    sno INTEGER PRIMARY KEY,
    mrd INTEGER,
    age INTEGER,
    gender VARCHAR(10),
    rural_urban VARCHAR(5),
    date_brought_dead DATE
);

-- INSERT DATA FROM STAGING TABLE INTO CLEAN TABLE
TRUNCATE clean.hdhi_mortality_cleaned; -- Allows the script to be rerun safely
INSERT INTO clean.hdhi_mortality_cleaned (
    sno,
    mrd,
    age,
    gender,
    rural_urban,
    date_brought_dead
)
SELECT DISTINCT ON (mrd, age, gender, rural_urban, date_brought_dead)
    sno::INTEGER,
    NULLIF(mrd, '***')::INTEGER,
    age::INTEGER,
    gender,
    CASE WHEN TRIM(rural_urban) IN ('R', 'U') THEN TRIM(rural_urban) ELSE NULL END, -- Ensure only valid values ('R' or 'U') are inserted, otherwise set to NULL
    TO_DATE(date_brought_dead, 'MM/DD/YYYY')
FROM staging.hdhi_mortality_raw
ORDER BY mrd, age, gender, rural_urban, date_brought_dead, sno; -- Order by the same columns used in DISTINCT ON to ensure consistent results

-- REVIEW IMPORT AND CLEANING OF MORTALITY DATA
SELECT COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE mrd is NULL) AS missing_mrd,
    COUNT(*) FILTER (WHERE rural_urban is NULL) as invalid_rural_urban
FROM clean.hdhi_mortality_cleaned;