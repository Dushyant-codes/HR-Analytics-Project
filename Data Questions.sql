

-- Q1. What is the gender breakdown of employees in the company?
SELECT gender, count(*) AS count
FROM Hr
WHERE age >=18 AND termdate = '0000-00-00'
GROUP BY gender;

-- Q2. What is the race/ethnicity breakdown of employees in the company?
SELECT race, count(*) AS count
FROM Hr
WHERE age >=18 AND termdate = '0000-00-00'
GROUP BY race ORDER BY count(*) DESC;

-- Q3. What is the age distribution of employees in the company?
SELECT
min(age) AS youngest,
max(age) AS oldest
FROM Hr
WHERE age >=18 AND termdate = '0000-00-00';

SELECT CASE
WHEN age >= 18 AND age <= 24 THEN '18-24'
WHEN age >= 25 AND age <= 34 THEN '25-34'
WHEN age >= 35 AND age <= 44 THEN '35-44'
WHEN age >= 45 AND age <= 54 THEN '45-54'
WHEN age >= 55 AND age <= 64 THEN '55-64'
ELSE '65+'
END AS age_group, count(*) AS count
FROM Hr
WHERE age >=18 AND termdate = '0000-00-00'
GROUP BY age_group ORDER BY age_group;


SELECT CASE
WHEN age >= 18 AND age <= 24 THEN '18-24'
WHEN age >= 25 AND age <= 34 THEN '25-34'
WHEN age >= 35 AND age <= 44 THEN '35-44'
WHEN age >= 45 AND age <= 54 THEN '45-54'
WHEN age >= 55 AND age <= 64 THEN '55-64'
ELSE '65+'
END AS age_group, gender, count(*) AS count
FROM Hr
WHERE age >=18 AND termdate = '0000-00-00'
GROUP BY age_group, gender ORDER BY age_group, gender;

-- Q4. How many employees work at headquarters versus remote locations?
SELECT location, count(*) AS count
FROM Hr
WHERE age >=18 AND termdate = '0000-00-00'
GROUP BY location;

-- Q5. What is the average length of employment for employees who have been terminated?
SELECT 
    ROUND(AVG(DATEDIFF(termdate, hire_date) / 365), 0) AS avg_length_employment
FROM Hr
WHERE 
    termdate IS NOT NULL
    AND termdate <= CURDATE();

-- Q6. How does the gender distribution vary across departments and job titles?
SELECT 
    department,
    gender,
    COUNT(*) AS employee_count
FROM Hr
GROUP BY department,  gender
ORDER BY department,  gender;

-- Q7. What is the distribution of job titles across the company?
SELECT 
    jobtitle,
    COUNT(*) AS employee_count
FROM Hr
GROUP BY jobtitle
ORDER BY employee_count DESC;

-- Q8. Which department has the highest turnover rate?
SELECT 
    department,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN termdate_clean IS NOT NULL AND termdate_clean <= CURDATE() THEN 1 ELSE 0 END) AS terminated_employees,
    ROUND(SUM(CASE WHEN termdate_clean IS NOT NULL AND termdate_clean <= CURDATE() THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS turnover_rate
FROM (
    SELECT 
        department,
        STR_TO_DATE(NULLIF(CAST(termdate AS CHAR), '0000-00-00'), '%Y-%m-%d') AS termdate_clean
    FROM Hr
) AS sub
GROUP BY department
ORDER BY turnover_rate DESC;

-- Q9. What is the distribution of employees across locations by state?
SELECT 
    location_state,
    COUNT(*) AS employee_count
FROM Hr
GROUP BY location_state
ORDER BY employee_count DESC;


-- Q10. How has the company's employee count changed over time based on hire and term dates?
WITH yearly_data AS (
    SELECT 
        year_val,
        SUM(hires) AS hires,
        SUM(terms) AS terminations
    FROM (
        -- Hires
        SELECT 
            YEAR(hire_date) AS year_val,
            COUNT(*) AS hires,
            0 AS terms
        FROM Hr
        GROUP BY YEAR(hire_date)

        UNION ALL

        -- Terminations
        SELECT 
            YEAR(STR_TO_DATE(termdate, '%Y-%m-%d')) AS year_val,
            0 AS hires,
            COUNT(*) AS terms
        FROM Hr
        WHERE termdate IS NOT NULL
          AND CAST(termdate AS CHAR) <> '0000-00-00'
          AND STR_TO_DATE(termdate, '%Y-%m-%d') <= CURDATE()
        GROUP BY YEAR(STR_TO_DATE(termdate, '%Y-%m-%d'))
    ) AS combined
    GROUP BY year_val
),
running_totals AS (
    SELECT 
        year_val,
        hires,
        terminations,
        SUM(hires - terminations) OVER (ORDER BY year_val) AS total_active
    FROM yearly_data
)
SELECT 
    year_val,
    hires,
    terminations,
    total_active,
    hires - terminations AS net_change,
    ROUND(
        CASE 
            WHEN LAG(total_active) OVER (ORDER BY year_val) = 0 THEN NULL
            ELSE ((total_active - LAG(total_active) OVER (ORDER BY year_val)) / 
                  LAG(total_active) OVER (ORDER BY year_val)) * 100
        END
    , 2) AS net_change_percent
FROM running_totals
ORDER BY year_val desc;

-- Q11. What is the tenure distribution for each department?
SELECT 
    department,
    ROUND(AVG(DATEDIFF(
        IF(CAST(termdate AS CHAR) <> '0000-00-00' AND termdate IS NOT NULL, termdate, CURDATE()), 
        hire_date
    ) / 365), 0) AS avg_tenure_years
FROM Hr
WHERE age >= 18
GROUP BY department
ORDER BY avg_tenure_years DESC;
