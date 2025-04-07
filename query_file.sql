-- Create Database student_grade;
USE student_grade;
-- DROP table students_grade;
 
CREATE Table students_grade (
	Student_ID varchar(10) primary key,	
    First_Name varchar(10),
	Last_Name varchar(10),
	Email varchar(30),
	Gender varchar(10),	
    Age int,
	Department varchar(20),	
    Attendance varchar(10), -- decimal(5,2)
	Midterm_Score decimal(5,2) ,	
    Final_Score decimal(5,2) ,	
    Assignments_Avg	varchar(10), -- decimal(5,2)
    Quizzes_Avg	decimal(5,2) ,
    Participation_Score decimal(5,2) ,	
    Projects_Score decimal(5,2) ,
    Total_Score	decimal(5,2) ,
    Grade varchar(10),
    Study_Hours_per_Week decimal(5,2) ,	
    Extracurricular_Activities varchar(5) ,
    Internet_Access_at_Home	varchar(5) ,
    Parent_Education_Level varchar(20) ,
    Family_Income_Level	varchar(10) ,
    Stress_Level int,
	Sleep_Hours_per_Night decimal(5,2)
);
-- Check assignment_avg and attendance column (contian empty value)
Update students_grade
SET Attendance = 0 WHERE Attendance = '';
Update students_grade
SET Assignments_Avg = 0 WHERE Assignments_Avg = '';

ALTER TABLE students_grade
MODIFY Column Attendance float;
ALTER Table students_grade
MODIFY Column Assignments_Avg decimal(5,2);

Update students_grade
SET Attendance = Attendance / 100;

Update students_grade
SET Parent_Education_Level = 'Unknown' WHERE Parent_Education_Level = '';

/* ---------------- QUERY PROCESSING ----------------*/
-- Count total the number of students in this dataset
SELECT DISTINCT FORMAT(COUNT(*),'#,##0') Number_student FROM Students_grade;

-- Count number student by Gender and calculate the study hour and sleep hour and average score for each gender
SELECT 
	Gender,
    FORMAT(COUNT(*), '#,##') Number_students,
    FORMAT(SUM(Study_Hours_per_Week), '#,##') Study_Hours_per_week,
    FORMAT(SUM(Sleep_Hours_per_Night), '#,##') Sleep_Hours_per_night,
    CONVERT(AVG(Total_Score), DECIMAL(5,2)) Average_score
FROM Students_grade 
GROUP BY Gender;

-- Classify by Extracurricular activities and Internet access at home
SELECT 
	Extracurricular_Activities,
    FORMAT(COUNT(*), '#,##0') Number
FROM students_grade
GROUP BY Extracurricular_Activities;
--
SELECT
	Internet_Access_at_Home,
    FORMAT(COUNT(*), '#,##0') Number
FROM students_grade
GROUP BY Internet_Access_at_Home;

-- Classify by Stress level
SELECT 
	Stress_level,
    COUNT(*) Number,
    CONCAT(ROUND(COUNT(*) / (SELECT COUNT(*) FROM students_grade) * 100,2),'%') Number
FROM students_grade
GROUP BY stress_level
ORDER BY Stress_level;

-- Compare study hour and sleep between male and female
WITH first_table AS
(SELECT
	Gender,
    COUNT(*) Number_student,
    SUM(study_hours_per_week) Study_hours,
    SUM(sleep_hours_per_night) Sleep_hours
FROM Students_grade
GROUP BY Gender)
--
SELECT 
	Gender, 
    CONVERT(Study_hours / Number_student, DECIMAL(5,2)) 'Study_hour/student/Week',
    CONVERT(Sleep_hours / Number_student, DECIMAL(5,2)) 'Sleep_hour/student/Night'
FROM first_table;

-- Classify by age
WITH first_table AS
(SELECT 
	Age,
    COUNT(*) Number_student,
	SUM(study_hours_per_week) Study_hours,
    SUM(sleep_hours_per_night) Sleep_hours,
    CONVERT(AVG(Total_Score), DECIMAL(5,2)) Average_score
FROM Students_grade
GROUP BY Age )
--
SELECT 
	Age,
    CONCAT(ROUND(Number_student / (SELECT COUNT(*) FROM Students_grade) *100,2), '%') '% Contribute by Age',
    CONVERT(Study_hours / Number_student, DECIMAL(5,2)) 'Study_hour/student/Week',
    CONVERT(Sleep_hours / Number_student, DECIMAL(5,2)) 'Sleep_hour/student/Night',
    Average_score
FROM first_table
ORDER BY Average_score DESC;

-- Classify by Department
SELECT 
	Department,
    FORMAT(Number_student, '#,##0') Number_student,
    ROUND(Study_hour / Number_student,2) Study_hour,
    ROUND(Sleep_hour / Number_student,2) Sleep_hour,
    Avg_score
FROM 
(SELECT 
	Department,
    COUNT(*) Number_student,
    ROUND(AVG(total_score),2) Avg_score,
    SUM(Study_Hours_per_Week) Study_hour,
    SUM(Sleep_Hours_per_Night) Sleep_hour
FROM students_grade
GROUP BY Department) as table1
ORDER BY avg_score DESC


-- Classify by parent education and family income
WITH main_table as
(SELECT DISTINCT
	Parent_Education_Level,
    COUNT(*) OVER (PARTITION BY Parent_Education_Level) Number_student_edu,
    ROUND(AVG(total_score) OVER (PARTITION BY Parent_Education_Level),2) Avg_score_edu,
    SUM(Study_Hours_per_Week) OVER (PARTITION BY Parent_Education_Level) Study_hours_edu,
    SUM(Sleep_Hours_per_Night) OVER (PARTITION BY Parent_Education_Level) Sleep_hours_edu,
    Family_Income_Level,
    COUNT(*) OVER (PARTITION BY Parent_Education_Level, Family_Income_Level) Number_student_incom,
    ROUND(AVG(total_score) OVER (PARTITION BY Parent_Education_Level, Family_Income_Level),2) Avg_score_incom,
    SUM(Study_Hours_per_Week) OVER (PARTITION BY Parent_Education_Level, Family_Income_Level) Study_hours_incom,
    SUM(Sleep_Hours_per_Night) OVER (PARTITION BY Parent_Education_Level, Family_Income_Level) Sleep_hours_incom
FROM students_grade)
--
SELECT 
	Parent_Education_Level,
    CONCAT(ROUND(Number_student_edu / (SELECT COUNT(*) FROM students_grade) *100,2), '%') '%Contribution(edu)',
    ROUND(Study_hours_edu / Number_student_edu,2) 'Study_hour per week (edu)',
    ROUND(Sleep_hours_edu / Number_student_edu,2) 'Sleep_hour per night (edu)',
    Avg_score_edu,
    Family_Income_Level,
    CONCAT(ROUND(Number_student_incom / Number_student_edu *100,2), '%') '%Contribution(income)',
    ROUND(Study_hours_incom / Number_student_incom,2) 'Study_hour per week (edu)',
    ROUND(Sleep_hours_incom / Number_student_incom,2) 'Sleep_hour per night (edu)',
    Avg_score_incom
FROM main_table;

-- Cacculate correlation between study hour and total score
WITH avg_score as
(SELECT AVG(Total_score) FROM Students_grade),
avg_study_hour as
(SELECT AVG(Study_hours_per_week) FROM Students_grade),
calculate_table as
(SELECT
	Student_Id,
    (Total_score - (SELECT * FROM avg_score)) as x1,
    (Study_hours_per_week - (SELECT * FROM avg_study_hour)) as x2
FROM students_grade)
--
SELECT 
	SUM(`x1*x2`) Numerator,
    SUM(`(X1-X)^2`) * SUM(`(X2-X)^2`) Denorminator,
	SUM(`x1*x2`) / POWER(SUM(`(X1-X)^2`) * SUM(`(X2-X)^2`),0.5) R 
FROM
(SELECT 
	Student_Id,
    x1 * x2 'x1*x2',
    POWER(x1,2) '(X1-X)^2', 
    POWER(x2,2) '(X2-X)^2'
FROM calculate_table) final_table

-- Cacculate correlation between sleep hour and total score
WITH avg_score as
(SELECT AVG(Total_score) FROM Students_grade),
avg_sleep_hour as
(SELECT AVG(Sleep_Hours_per_Night) FROM Students_grade),
calculate_table as
(
SELECT
	Student_id,
    (Total_score - (SELECT * FROM avg_score)) x1,
    (Sleep_Hours_per_Night - (SELECT * FROM avg_sleep_hour)) x2
FROM students_grade
)
--
SELECT
	SUM(`x1*x2`) Numerator,
    POWER(SUM(`x1^2`) * SUM(`x2^2`),0.5) Denorminator,
    SUM(`x1*x2`) / POWER(SUM(`x1^2`) * SUM(`x2^2`),0.5) R
FROM
(SELECT 
	Student_id,
    (x1 * x2) 'x1*x2',
    POWER(x1,2) 'x1^2',
    POWER(x2,2) 'x2^2'
FROM calculate_table) as table1

-- Calculate correlation between study hour and sleep hour
WITH avg_study_hour as
(SELECT AVG(Study_hours_per_week) FROM Students_grade),
avg_sleep_hour as
(SELECT AVG(Sleep_Hours_per_Night) FROM Students_grade),
calculate_table as
(SELECT 
	Student_id,
    (Study_hours_per_week - (SELECT * FROM avg_study_hour)) as x1,
    (Sleep_Hours_per_Night - (SELECT * FROM avg_sleep_hour)) as x2
FROM Students_grade)
--
SELECT 
	SUM(`x1*x2`) Numerator,
    POWER(SUM(`x1^2`) * SUM(`x2^2`),0.5) Denorminator,
    SUM(`x1*x2`) / POWER(SUM(`x1^2`) * SUM(`x2^2`),0.5) R
FROM
(SELECT 
	Student_id,
    (x1 * x2) 'X1*X2',
    POWER(x1,2) 'x1^2',
    POWER(x2,2) 'x2^2'
FROM Calculate_table) table1

-- Calculate correlation between study hour and stress
WITH main_table as
(SELECT 
	Stress_level,
    AVG(Study_Hours_per_Week) Study_hour
FROM students_grade
GROUP BY stress_level),
stress_table as 
(SELECT AVG(Stress_level) FROM main_table),
study_table as 
(SELECT AVG(Study_hour) FROM main_table),
calculate_table as
(SELECT 
	stress_level,
	(stress_level - (SELECT * FROM stress_table)) x1,
    (study_hour - (SELECT * FROM study_table)) x2,
    POWER((stress_level - (SELECT * FROM stress_table)),2) 'x1^2',
    POWER((study_hour - (SELECT * FROM study_table)),2) 'x2^2'
FROM main_table)
--
SELECT 
	SUM(x1*x2) Numerator,
	(SUM(`x1^2`) * SUM(`x2^2`)) Denorminator,
    SUM(x1*x2) / POWER((SUM(`x1^2`) * SUM(`x2^2`)),0.5) R
FROM calculate_table;

-- Calculate correlation between total score and stress 
WITH main_table as
(SELECT 
	Stress_level,
    AVG(total_score) score
FROM students_grade
GROUP BY stress_level),
stress_table as 
(SELECT AVG(Stress_level) FROM main_table),
score_table as 
(SELECT AVG(score) FROM main_table)
--
SELECT 
	SUM(x1*x2) Numerator,
    POWER((SUM(`x1^2`) * SUM(`x2^2`)),0.5) Denorminator,
    SUM(x1*x2) / POWER((SUM(`x1^2`) * SUM(`x2^2`)),0.5) R
FROM
(SELECT 
	stress_level,
	(stress_level - (SELECT * FROM stress_table)) x1,
    (score - (SELECT * FROM score_table)) x2,
    POWER((stress_level - (SELECT * FROM stress_table)),2) 'x1^2',
    POWER((score - (SELECT * FROM score_table)),2) 'x2^2'
FROM main_table) as calculate_table

-- Find the median of total_score in the dataset and return all information
WITH main_table as
(SELECT 
	ROW_NUMBER() OVER (ORDER BY Score ASC) Row_num,
    Score
FROM 
(SELECT DISTINCT
	total_score Score
FROM students_grade) as table1),
median_value as
(SELECT 
	CASE
		WHEN COUNT(*) % 2 <> 0 THEN (COUNT(*) + 1) / 2
		ELSE COUNT(*) / 2
	END Value1,
	CASE
		WHEN COUNT(*) % 2 <> 0 THEN (COUNT(*) +1) /2
		ELSE (COUNT(*) + 2) / 2
	END Value2
FROM main_table),
final_table as
(
SELECT * FROM main_table 
WHERE Row_num BETWEEN (SELECT Value1 FROM median_value) AND (SELECT Value2 FROM median_value)
)
--
SELECT COUNT(*) Number_student FROM Students_grade
WHERE total_score = (SELECT score FROM final_table)
