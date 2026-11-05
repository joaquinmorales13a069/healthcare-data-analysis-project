-- how do admissions change month by month? Is there a seasonal pattern?

-- By each year and month
SELECT
    date_trunc('month', doa)::DATE as admission_month,
    count(*) as admissions
FROM clean.hdhi_admission_cleaned
GROUP BY admission_month
ORDER BY admission_month;

/*
Analising the data from the 2 years without combining their months I can confirm:
1. The month with the highest admissions is January 2019 with 870 admissions
2. The month with the lowest admissions is April 2017 with 490 admissions
3. It seeks there's a spike in admissions from November to February
*/

-- By month only
SELECT
    extract(MONTH FROM doa) as month_number,
    to_char(doa, 'Mon') as month_name,
    count(*) as admissions
FROM clean.hdhi_admission_cleaned
GROUP BY month_number, month_name
ORDER BY admissions DESC;

/*
Analising the data from the 2017-2019 years combining their months I can confirm:
1. The month with the highest admissions is January with 1643
2. The month with the lowest admissions is April with 996 admissions
3. It seems that there is a seasonal admissions spike on the months from November to February
*/
