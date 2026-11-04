-- CREATE TABLE FOR CLEAN HEADINGS 
CREATE TABLE IF NOT EXISTS clean.table_headings_cleaned (
    column_name VARCHAR(255) PRIMARY KEY,
    column_code VARCHAR(50),
    explanatory_name VARCHAR(500)
);

-- INSERT DATA FROM STAGING TABLE INTO CLEAN TABLE
TRUNCATE clean.table_headings_cleaned; -- Allows the script to be rerun safely
INSERT INTO clean.table_headings_cleaned (column_name, column_code, explanatory_name)
SELECT 
    LOWER(REPLACE(REPLACE(TRIM(column_code), '.', ''), ' ', '_')),
    TRIM(column_code),
    TRIM(explanatory_name)
FROM staging.table_headings_raw
WHERE TRIM(column_code) <> ''
    AND TRIM(column_code) NOT IN ('Other Abbreveiations', 'DAMA'); -- Exclude empty rows and rows that are not column definitions