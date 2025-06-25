
------------------------
-- Queries in this file:
------------------------

-- Which words in job titles are associated with the highest salaries? 

-- Which countries/ companies draw their workforce from other countries the most? 

-- Which required skills are associated with the highest salaries? 

	-- How could we visualize the above? 

-- Which required skills are paired together the most? 

	-- Is there a more comparable way this could be presented? 
	-- Which are the most popular skills in general, and can these presented in the same table? 

-- Which industries have the most postings? 

----------------------------------------------------------------------
-- Which words in job titles are associated with the highest salaries?
----------------------------------------------------------------------

-- We'll split each job title into its composite words and aggregate based on these words.
-- These words will be listed on the same row at first, and then in the final query they will be
-- given their own rows for easy aggregation.
-- We'll confirm that job titles have at most three words.

WITH first_words AS ( -- CTE splits job title after first word
SELECT job_id, job_title,
	SUBSTRING(job_title, 1, CHARINDEX(' ', job_title) -1) AS first_word,
	SUBSTRING(job_title, CHARINDEX(' ', job_title) + 1, LEN(job_title)) AS rest_of_title
FROM [AI Job Market]..ai_job_dataset$),

all_words AS ( -- CTE splits remaining title, leaving second and third word
SELECT job_id, job_title, first_word,
	CASE WHEN rest_of_title LIKE '% %' THEN
	SUBSTRING(rest_of_title, 1, CHARINDEX(' ', rest_of_title)) 
	ELSE rest_of_title END AS second_word,
	CASE WHEN rest_of_title LIKE '% %' THEN 
	SUBSTRING(rest_of_title, CHARINDEX(' ', rest_of_title) + 1, LEN(rest_of_title))
	ELSE NULL END AS third_word
FROM first_words)

SELECT * -- this query returns nothing, confirming no job title is more than three words
FROM all_words
WHERE third_word LIKE '% %';

-- After checking the job title split is correct we can proceed writing the query:
-- (the two CTEs are the same as the ones above)

WITH first_words AS (
SELECT job_id, job_title,
	SUBSTRING(job_title, 1, CHARINDEX(' ', job_title) -1) AS first_word,
	SUBSTRING(job_title, CHARINDEX(' ', job_title) + 1, LEN(job_title)) AS rest_of_title
FROM [AI Job Market]..ai_job_dataset$),

all_words AS (
SELECT job_id, job_title, first_word,
	CASE WHEN rest_of_title LIKE '% %' THEN -- if no more spaces then must be dealt with separately
	SUBSTRING(rest_of_title, 1, CHARINDEX(' ', rest_of_title)) 
	ELSE rest_of_title END AS second_word,
	CASE WHEN rest_of_title LIKE '% %' THEN 
	SUBSTRING(rest_of_title, CHARINDEX(' ', rest_of_title) + 1, LEN(rest_of_title))
	ELSE NULL END AS third_word
FROM first_words)

SELECT word, CONCAT('$', ROUND(AVG(salary_usd),2)) AS avg_salary,
	COUNT(*) AS num_jobs 
FROM (
	SELECT a.*, first_word AS word -- each word is given its own row here
	FROM [AI Job Market]..ai_job_dataset$ AS a
	JOIN all_words AS b
	ON a.job_id = b.job_id
	UNION
	SELECT a.*, second_word AS word
	FROM [AI Job Market]..ai_job_dataset$ AS a
	JOIN all_words AS b
	ON a.job_id = b.job_id
	UNION
	SELECT a.*, third_word AS word
	FROM [AI Job Market]..ai_job_dataset$ AS a
	JOIN all_words AS b
	ON a.job_id = b.job_id) AS words
WHERE word <> 'of' -- gets rid of NULLS too
GROUP BY word
ORDER BY avg_salary DESC;

------------------------------------------------------------------
-- Which required skills are associated with the highest salaries?
------------------------------------------------------------------

-- This query will follow the same structure as the previous one.
-- This time we'll split up the required_skills field, with the comma as the delimiter.

WITH first_skill AS (
SELECT job_id, required_skills,
	SUBSTRING(required_skills, 1, CHARINDEX(',', required_skills) -1) AS first_skill,
	SUBSTRING(required_skills, CHARINDEX(',', required_skills) + 1, LEN(required_skills)) AS rest_of_skills
FROM [AI Job Market]..ai_job_dataset$),

second_skill AS (
SELECT job_id, required_skills, first_skill,
	SUBSTRING(rest_of_skills, 1, CHARINDEX(',', rest_of_skills) -1) AS second_skill,
	SUBSTRING(rest_of_skills, CHARINDEX(',', rest_of_skills) + 1, LEN(rest_of_skills)) AS rest_of_skills
FROM first_skill),

third_skill AS (
SELECT job_id, required_skills, first_skill, second_skill,
	CASE WHEN rest_of_skills NOT LIKE '%,%' THEN rest_of_skills
	ELSE SUBSTRING(rest_of_skills, 1, CHARINDEX(',', rest_of_skills) -1) END AS third_skill,
	CASE WHEN rest_of_skills NOT LIKE '%,%' THEN NULL
	ELSE SUBSTRING(rest_of_skills, CHARINDEX(',', rest_of_skills) + 1, LEN(rest_of_skills)) END AS rest_of_skills
FROM second_skill),

all_skills AS (
SELECT job_id, required_skills, first_skill, second_skill, third_skill,
	CASE WHEN rest_of_skills NOT LIKE '%,%' THEN rest_of_skills
	ELSE SUBSTRING(rest_of_skills, 1, CHARINDEX(',', rest_of_skills) -1) END AS fourth_skill,
	CASE WHEN rest_of_skills NOT LIKE '%,%' THEN NULL
	ELSE SUBSTRING(rest_of_skills, CHARINDEX(',', rest_of_skills) + 1, LEN(rest_of_skills)) END AS fifth_skill
FROM third_skill)

SELECT * -- this query returns nothing, confirming no job has more than five skills
FROM all_skills
WHERE fifth_skill LIKE '%,%';

-- Each job having between 3 and 5 skills is strange and perhaps indicates some cherry picking
-- in the skills that are listed. 

-- Since these separated skills will be useful for other queries later on, we'll create
-- a view of them here:
-- (this is the same as above, just in subquery form)

DROP VIEW IF EXISTS skills_separated

CREATE VIEW skills_separated AS (
SELECT job_id, required_skills, TRIM(first_skill) AS first_skill, TRIM(second_skill) AS second_skill, TRIM(third_skill) AS third_skill,
	CASE WHEN rest_of_skills NOT LIKE '%,%' THEN TRIM(rest_of_skills)
	ELSE TRIM(SUBSTRING(rest_of_skills, 1, CHARINDEX(',', rest_of_skills) -1)) END AS fourth_skill,
	CASE WHEN rest_of_skills NOT LIKE '%,%' THEN NULL
	ELSE TRIM(SUBSTRING(rest_of_skills, CHARINDEX(',', rest_of_skills) + 1, LEN(rest_of_skills))) END AS fifth_skill
FROM (SELECT job_id, required_skills, first_skill, second_skill,
		CASE WHEN rest_of_skills NOT LIKE '%,%' THEN rest_of_skills
		ELSE SUBSTRING(rest_of_skills, 1, CHARINDEX(',', rest_of_skills) -1) END AS third_skill,
		CASE WHEN rest_of_skills NOT LIKE '%,%' THEN NULL
		ELSE SUBSTRING(rest_of_skills, CHARINDEX(',', rest_of_skills) + 1, LEN(rest_of_skills)) END AS rest_of_skills
		FROM (SELECT job_id, required_skills, first_skill,
			SUBSTRING(rest_of_skills, 1, CHARINDEX(',', rest_of_skills) -1) AS second_skill,
			SUBSTRING(rest_of_skills, CHARINDEX(',', rest_of_skills) + 1, LEN(rest_of_skills)) AS rest_of_skills
			FROM (SELECT job_id, required_skills,
				SUBSTRING(required_skills, 1, CHARINDEX(',', required_skills) -1) AS first_skill,
				SUBSTRING(required_skills, CHARINDEX(',', required_skills) + 1, LEN(required_skills)) AS rest_of_skills
			FROM [AI Job Market]..ai_job_dataset$) AS first_skills) AS second_skills) AS third_skills)

-- Now we can proceed with the actual query:

SELECT skill, CONCAT('$', ROUND(AVG(salary_usd),2)) AS avg_salary, 
	COUNT(*) AS num_jobs
FROM(SELECT a.*, b.first_skill AS skill
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
	ON a.job_id = b.job_id) AS skills
WHERE skill IS NOT NULL
GROUP BY skill
ORDER BY avg_salary DESC;

------------------------------------------------------
-- Which required skills are paired together the most?
------------------------------------------------------

-- We'll make a row for each skill that a job has (as we did in the previous query)
-- and then do a self-join to count the pairs

WITH skills_row_wise AS ( -- CTE creates a row for each skill that a job has
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

SELECT a.skill AS skill_1, b.skill AS skill_2,
	COUNT(*) AS num_occurences
FROM skills_row_wise AS a
JOIN skills_row_wise AS b
ON a.job_id = b.job_id
	AND a.skill <> b.skill -- isolates pairs of different skills
	AND a.skill < b.skill -- removes duplicates that arise from re-orderings of the same pair
GROUP BY a.skill, b.skill
ORDER BY num_occurences DESC;

-- For better comparison we'll look at which two skills have the biggest intersections
-- when compared to all jobs that are associated with either of them.
-- This measure is called Intersection Over Union (IOU.)

WITH skills_row_wise AS ( -- first CTE is same
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
ON a.job_id = b.job_id),

skill_counts AS ( -- CTE counts number of jobs associated with each skill separately
SELECT skill, COUNT(*) AS num_jobs
FROM skills_row_wise
WHERE skill IS NOT NULL
GROUP BY skill)

SELECT a.skill AS skill_1, b.skill AS skill_2,
	COUNT(*) AS skills_intersection, 
	MAX(c.num_jobs) + MAX(d.num_jobs) - COUNT(*) AS skills_union, -- uses inclusion-exclusion principle
	ROUND(CAST(COUNT(*) AS FLOAT)/ (MAX(c.num_jobs) + MAX(d.num_jobs) - COUNT(*)), 3) AS skills_IOU
FROM skills_row_wise AS a
JOIN skills_row_wise AS b
ON a.job_id = b.job_id
	AND a.skill <> b.skill -- isolates pairs of different skills
	AND a.skill < b.skill -- removes duplicates that arise from re-orderings of the same pair
JOIN skill_counts AS c
ON a.skill = c.skill
JOIN skill_counts AS d
ON b.skill = d.skill
GROUP BY a.skill, b.skill
ORDER BY skills_IOU DESC;

-- 276 = 24C2 rows, therefore this is correct.

-- We could also query which skills are used the most, and which other skill they
-- are most often paired with:

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

SELECT skill, COUNT(*) AS num_jobs,
	MAX(skill_combinations.skill_2) AS most_commonly_paired_with,
	MAX(skill_combinations.num_occurences) AS num_occurences
FROM skills_row_wise AS a
JOIN (SELECT b.skill AS skill_1, c.skill AS skill_2,
		COUNT(*) AS num_occurences,
		ROW_NUMBER() OVER(PARTITION BY b.skill ORDER BY COUNT(*) DESC) AS within_skill_1_rank
	FROM skills_row_wise AS b
	JOIN skills_row_wise AS c
	ON b.job_id = c.job_id
		AND b.skill <> c.skill
	GROUP BY b.skill, c.skill) AS skill_combinations
ON a.skill = skill_combinations.skill_1
WHERE a.skill IS NOT NULL AND skill_combinations.within_skill_1_rank = 1
GROUP BY skill;
-- The most common pairings are biased towards Python (as it's the most common 
-- skill by far) and therefore not very insightful.

---------------------------------------------------------------------------------
-- Which countries/ companies draw their workforce from other countries the most?
---------------------------------------------------------------------------------

-- We'll get a count of the number of overseas jobs, as well as this count
-- expressed as a percentage of that company's total posting count.
-- Here we are assuming that no postings are for the same role at different times, and
-- that a company's vacancy postings are roughly representative of their workforce.

WITH company_location_job_count AS ( -- CTE counts how many job postings each company-location has posted
SELECT company_name, company_location,
	COUNT(*) AS num_jobs
FROM [AI Job Market]..ai_job_dataset$
GROUP BY company_name, company_location)

SELECT a.company_name, a.company_location, COUNT(*) AS international_jobs,
	MAX(b.num_jobs) AS total_jobs,
	ROUND(100*CAST(COUNT(*) AS FLOAT)/MAX(b.num_jobs), 3) AS perc_international
FROM [AI Job Market]..ai_job_dataset$ AS a
JOIN company_location_job_count AS b
ON a.company_location = b.company_location
	AND a.company_name = b.company_name
WHERE a.company_location <> a.employee_residence
GROUP BY a.company_name, a.company_location
ORDER BY perc_international DESC;

-- Interestingly, in most companies the overseas workforce seems to be spread quite evenly
-- across many countries, with no more than three (and usually one) roles available to people
-- in each country. 

-----------------------------------------------
-- Which industries have the most job postings? 
-----------------------------------------------

SELECT industry, COUNT(*) AS job_postings
FROM [AI Job Market]..ai_job_dataset$
GROUP BY industry
ORDER BY job_postings DESC;
-- very evenly spread (don't know if this comes from collection method)