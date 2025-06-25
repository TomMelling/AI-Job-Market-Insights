
---------------------------------------------------------------
-- Here we'll prepare data for these questions/ visualizations:
---------------------------------------------------------------

-- What is the general distribution of salaries, by country (of employee), 
-- experience level, company size?

-- Do larger companies generally pay more?

-- Correlation between years experience and salary?

-- Do jobs with higher salaries have larger application windows?

-- Do jobs with higher salaries have more required skills?

-- Do jobs with higher salaries have longer job descriptions?

-- What is the salary spread like in different industries?
-- (maybe include number of jobs for these industries too)

-- Bubble chart of skills where size is prevalence and colour is average salary. 

--------------------------------------------------------------------------
-- What is the general distribution of salaries, by country (of employee), 
-- experience level, company size?

-- Do larger companies generally pay more?

-- Correlation between years experience and salary?

-- Do jobs with higher salaries have longer job descriptions?

-- What is the salary spread like in different industries? 
-- (maybe include number of jobs for these industries too)
----------------------------------------------------------

-- We'll get the information for these five queries in the same table:

SELECT job_id, salary_usd, experience_level, company_location, 
	company_size, employee_residence,
	years_experience, industry, job_description_length
FROM [AI Job Market]..ai_job_dataset$;

-- No correlation was found between salary and job description length.

-- Very little change in salary distribution across industries.

----------------------------------------------------------------
-- Do jobs with higher salaries have larger application windows?

-- Do jobs with higher salaries have more required skills? 
----------------------------------------------------------

WITH skills_row_wise AS ( -- CTE from other file generates a row for each skill
SELECT a.*, b.first_skill AS skill
FROM [AI Job Market]..ai_job_dataset$ as a
JOIN skills_separated AS b 
ON a.job_id = b.job_id
UNION
SELECT a.*, b.second_skill AS skill
FROM [AI Job Market]..ai_job_dataset$ as a
JOIN skills_separated AS b 
ON a.job_id = b.job_id
UNION
SELECT a.*, b.third_skill AS skill
FROM [AI Job Market]..ai_job_dataset$ as a
JOIN skills_separated AS b 
ON a.job_id = b.job_id
UNION
SELECT a.*, b.fourth_skill AS skill
FROM [AI Job Market]..ai_job_dataset$ as a
JOIN skills_separated AS b 
ON a.job_id = b.job_id
UNION
SELECT a.*, b.fifth_skill AS skill
FROM [AI Job Market]..ai_job_dataset$ as a
JOIN skills_separated AS b 
ON a.job_id = b.job_id)

SELECT a.job_id, MAX(a.salary_usd) AS salary_usd,
	DATEDIFF(d, MAX(a.posting_date), MAX(a.application_deadline)) AS application_window_length_days,
	COUNT(*) AS num_skills
FROM [AI Job Market]..ai_job_dataset$ AS a
JOIN skills_row_wise AS b
ON a.job_id = b.job_id
WHERE b.skill IS NOT NULL
GROUP BY a.job_id;

-- No relationship found between application window length and salary.

-- No relationship found between skill count and average salary.

--------------------------------------------------------------------------------
-- Bubble chart of skills where size is prevalence and colour is average salary. 
--------------------------------------------------------------------------------

WITH skills_row_wise AS (
SELECT a.*, b.first_skill AS skill
FROM [AI Job Market]..ai_job_dataset$ as a
JOIN skills_separated AS b 
ON a.job_id = b.job_id
UNION
SELECT a.*, b.second_skill AS skill
FROM [AI Job Market]..ai_job_dataset$ as a
JOIN skills_separated AS b 
ON a.job_id = b.job_id
UNION
SELECT a.*, b.third_skill AS skill
FROM [AI Job Market]..ai_job_dataset$ as a
JOIN skills_separated AS b 
ON a.job_id = b.job_id
UNION
SELECT a.*, b.fourth_skill AS skill
FROM [AI Job Market]..ai_job_dataset$ as a
JOIN skills_separated AS b 
ON a.job_id = b.job_id
UNION
SELECT a.*, b.fifth_skill AS skill
FROM [AI Job Market]..ai_job_dataset$ as a
JOIN skills_separated AS b 
ON a.job_id = b.job_id)

SELECT a.job_id, a.salary_usd, b.skill
FROM [AI Job Market]..ai_job_dataset$ AS a
JOIN skills_row_wise AS b
ON a.job_id = b.job_id
WHERE b.skill IS NOT NULL;



