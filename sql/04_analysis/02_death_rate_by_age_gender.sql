-- Defining death rate = death (outcome = 'EXPIRY') / total_admissions *100
-- DAMA patients (left against medical advice) are counted as admissions, not deaths.
-- who is most at risk of dying in hospital? Death rate (`outcome = 'EXPIRY'`) by age group and gender.

-- USING CASE FOR GROUPING AGE RANGES
-- Death rate by age group.
SELECT
    CASE 
        WHEN age < 40 THEN 'Under 40'
        WHEN age < 50 THEN '40-49'
        WHEN age < 60 THEN '50-59'
        WHEN age < 70 THEN '60-69'
        ELSE  '70+'
    END AS age_group,
    count(*) as admissions,
    count(*) filter (where outcome = 'EXPIRY') as deaths,
    round(count(*) filter (where outcome = 'EXPIRY') * 100.0 / count(*), 1) as death_rate
FROM clean.hdhi_admission_cleaned
GROUP BY age_group
ORDER BY min(age);

-- Conclusion: It seems the older people have a bigger tendency of getting admitted in the hospital. Over 70 years old group is the one with a higher death rate (10%) over other groups.

-- Death rate by gender
SELECT
    gender,
    count(*) as admissions,
    count(*) filter (where outcome = 'EXPIRY') as deaths,
    round(count(*) filter (where outcome = 'EXPIRY') * 100.0 / count(*), 1) as death_rate
FROM clean.hdhi_admission_cleaned
GROUP BY gender
ORDER BY death_rate DESC;

-- Conclusion: Men account for 63% of admissions (9,990 vs 5,767), but the death rate
-- is the same for both genders (7.0%). Gender alone does not change the risk of dying.

-- Death rate by age and gender

SELECT
    gender,
    CASE 
        WHEN age < 40 THEN 'Under 40'
        WHEN age < 50 THEN '40-49'
        WHEN age < 60 THEN '50-59'
        WHEN age < 70 THEN '60-69'
        ELSE  '70+'
    END AS age_group,
    count(*) as admissions,
    count(*) filter (where outcome = 'EXPIRY') as deaths,
    round(count(*) filter (where outcome = 'EXPIRY') * 100.0 / count(*), 1) as death_rate
FROM clean.hdhi_admission_cleaned
GROUP BY gender, age_group
ORDER BY MIN(age), gender;

-- Conlusion: Confirmed by the previous 2 queries, Gender = men and Over 70 years group represen the admissions which have a higher tendency of death_rate with a 10.4%.
-- On younger age groups, Female admissions have a higher death_rate compare to men admissions.