-- CREATE TABLE FOR CLEAN POLLUTION DATA
CREATE TABLE IF NOT EXISTS clean.hdhi_pollution_cleaned (
    reading_date DATE PRIMARY KEY,
    aqi INTEGER,
    prominent_pollutant VARCHAR(50),
    max_temperature INTEGER,
    min_temperature INTEGER,
    humidity INTEGER
);

-- INSERT DATA FROM STAGING TABLE INTO CLEAN TABLE
TRUNCATE clean.hdhi_pollution_cleaned; -- Clear existing data before inserting new data, this avoids duplicates and ensures the table is up-to-date with the latest readings.
INSERT INTO clean.hdhi_pollution_cleaned (
    reading_date,
    aqi,
    prominent_pollutant,
    max_temperature,
    min_temperature,
    humidity
)
SELECT 
    TO_DATE("date", 'MM/DD/YYYY'),
    aqi::INTEGER,
    prominent_pollutant,
    max_temp::INTEGER,
    min_temp::INTEGER,
    NULLIF(humidity, '')::INTEGER
FROM staging.hdhi_pollution_raw;