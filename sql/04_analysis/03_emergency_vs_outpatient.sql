-- Do emergency admissions stay longer or die more often than outpatient admissions?
-- For reading porpuses: CASE used to better understand E = Emergency and O = Outpatient.

SELECT
    CASE type_of_admission
        WHEN 'E' THEN 'Emergency'
        WHEN 'O' THEN 'Outpatient'
    END as admission_type,
    count(*) as admissions_count,
    round(avg(duration_of_stay), 1 ) as average_duration_of_stay,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY duration_of_stay) as median_duration_of_stay,
    round(avg(duration_of_intensive_unit_stay), 1) as avg_icu_days,
    round(count(*) FILTER (WHERE outcome = 'EXPIRY') * 100.0 / count(*), 1) as death_rate
FROM clean.hdhi_admission_cleaned
GROUP BY admission_type;

-- Conclusion: Emergency admissions stay longer (median 6 vs 4 days), spend more than twice as long in intensive care (4.6 vs 2.0 days) and have a much higher death rate(9.9% vs 0.6%). This likely reflects that emergency patients arrive in a more severe condition, not that the type of admission itself causes the difference.