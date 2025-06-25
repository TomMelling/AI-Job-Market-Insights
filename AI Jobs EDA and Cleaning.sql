
-------------------------------------------
-- Getting an idea of what's in each field:
-------------------------------------------

SELECT COUNT(*) AS num_rows, COUNT(DISTINCT job_id) AS distinct_ids
FROM [AI Job Market]..ai_job_dataset$;
-- No duplicates, as far as job_id is concerned

SELECT *
FROM [AI Job Market]..ai_job_dataset$
ORDER BY company_name, job_title, posting_date;
-- The same company name can be associated with multiple company locations, and multiple industries.
-- As expected, company location doesn't have to match up with employee residence.
-- Company size can also vary under the same company name (branches in different countries?)

SELECT *
FROM [AI Job Market]..ai_job_dataset$
ORDER BY salary_usd DESC;
-- Salaries range from $32,500 to nearly $400,000.

SELECT DISTINCT experience_level
FROM [AI Job Market]..ai_job_dataset$;
-- Experience categories are entry, mid, senior, executive.

SELECT DISTINCT experience_level, years_experience
FROM [AI Job Market]..ai_job_dataset$
ORDER BY experience_level;
-- Experience categories are a partition of years_experience.

SELECT DISTINCT employment_type
FROM [AI Job Market]..ai_job_dataset$;
-- CT is contract, FL is freelance.

SELECT DISTINCT company_name
FROM [AI Job Market]..ai_job_dataset$;
-- Only 16 company names

SELECT DISTINCT company_name, industry
FROM [AI Job Market]..ai_job_dataset$
ORDER BY company_name;
-- Companies have job vacancies in several industries.

SELECT *
FROM [AI Job Market]..ai_job_dataset$;

SELECT MIN(posting_date) AS earliest_posting,
	MAX(posting_date) AS latest_posting,
	MIN(application_deadline) AS earliest_deadline,
	MAX(application_deadline) AS latest_deadline
FROM [AI Job Market]..ai_job_dataset$;
-- Posting dates range from Jan 1st 2024 to April 30th 2025.
-- Deadline dates range from Jan 16th 2024 to July 11th 2025.

SELECT *
FROM [AI Job Market]..ai_job_dataset$
WHERE employee_residence <> company_location
	AND remote_ratio = 0;
-- Some non-remote jobs don't seem to make sense
-- e.g. a full-time job for a US employee at a company based in China.
-- Maybe there are unseen international subsidiaries of the 'location' company.

SELECT employee_residence, COUNT(*) AS num_jobs
FROM [AI Job Market]..ai_job_dataset$
GROUP BY employee_residence;
-- Very even spread between employee residences, again calls into question data-garthering methods.
