  DROP DATABASE IF EXISTS hhIT cascade;
CREATE DATABASE hhIT;

USE hhIT;

  DROP TABLE IF EXISTS hh_it_spark;
CREATE EXTERNAL TABLE IF NOT EXISTS hh_it_spark (
                `_id` INT,
                title STRING,
        vacancy_group ARRAY<STRING>,
        prog_language ARRAY<STRING>,
          vacancy_url STRING,
           experience STRING,
        work_schedule STRING,
    work_schedule_add STRING,
               salary STRING,
          salary_type STRING,
             employer STRING,
          description STRING,
        strong_fields ARRAY<STRING>,
           key_skills ARRAY<STRING>,
        employer_page STRING,
      employer_rating DOUBLE,
  emp_feedback_number INT,
    work_var_contract STRING,
    work_var_parttime STRING,
         vacancy_date STRING,
        city_from_url STRING,
        employer_city STRING,
             currency STRING,
 low_level_salary_NET INT,
high_level_salary_NET INT,
  month_for_partition INT
  )
--   PRIMARY KEY(_id) disable novalidate
STORED AS PARQUET
LOCATION '/user/hive/results';

   DESC formatted hh_it_spark;
 SELECT *, TO_DATE(vacancy_date)  FROM hh_it_spark;

 SELECT COUNT(*) FROM hh_it_spark;

-- самые востребованные вакансии
 SELECT title, COUNT(title) AS amount
   FROM hh_it_spark
  GROUP BY title
 HAVING amount > 10
  ORDER BY amount DESC;

-- самые востребованные вакансии сгруппированные 2023 Россия
 SELECT vacancy, COUNT(vacancy) AS amount
   FROM hh_it_spark
LATERAL view explode(vacancy_group) stock_tble AS vacancy
  GROUP BY vacancy
  ORDER BY amount DESC;
 
 -- самые востребованные вакансии сгруппированные 2023 Москва
 SELECT vacancy, COUNT(vacancy) AS amount
   FROM hh_it_spark
LATERAL view explode(vacancy_group) stock_tble AS vacancy
  WHERE city_from_url = "Москва"
  GROUP BY vacancy
  ORDER BY amount DESC;
 
-- рейтинг языков программирования Россия
 SELECT programming_language, COUNT(programming_language) AS amount
   FROM hh_it_spark
LATERAL view explode(prog_language) stock_tble AS programming_language
  GROUP BY programming_language
  ORDER BY amount DESC;
 
 -- рейтинг языков программирования Москва
 SELECT programming_language, COUNT(programming_language) AS amount
   FROM hh_it_spark
LATERAL view explode(prog_language) stock_tble AS programming_language
  WHERE city_from_url = "Москва"
  GROUP BY programming_language
  ORDER BY amount DESC;

-- доля вакансиий с указанием зп
 SELECT COUNT(*) AS total_count,
        COUNT(CASE WHEN high_level_salary_net IS NOT NULL AND low_level_salary_net IS NULL THEN 1 END) AS high_level_specified,
        COUNT(CASE WHEN low_level_salary_net IS NOT NULL AND high_level_salary_net IS NULL THEN 1 END) AS low_level_specified,
        COUNT(CASE WHEN low_level_salary_net IS NOT NULL OR high_level_salary_net IS NOT NULL THEN 1 END) AS low_or_high_level_specified,
        COUNT(CASE WHEN low_level_salary_net IS NOT NULL AND high_level_salary_net IS NOT NULL THEN 1 END) AS both_levels_specified
   FROM hh_it_spark;

 
--Зароботная плата по городам России AVG
SELECT city_from_url,
	   COUNT(city_from_url) AS amount,
	   ROUND(AVG(low_level_salary_net), 0) AS low,
	   ROUND(AVG(high_level_salary_net), 0) AS high
  FROM hh_it_spark
 WHERE low_level_salary_net > 1000 OR high_level_salary_net <1000000
 GROUP BY city_from_url
 ORDER BY high DESC;

--Зароботная плата по городам России Median
SELECT city_from_url,
	   COUNT(city_from_url) AS amount,
	   ROUND(percentile_approx(low_level_salary_net, 0.5), 0) AS low,
	   ROUND(percentile_approx(high_level_salary_net, 0.5), 0) AS high
  FROM hh_it_spark
 WHERE low_level_salary_net IS NOT NULL OR high_level_salary_net IS NOT NULL
 GROUP BY city_from_url
 ORDER BY high DESC;

--Заработная плата по специальностям Россия AVG
 SELECT vacancy,
	    COUNT(vacancy) AS amount,
	    ROUND(AVG(low_level_salary_net), 0) AS low,
	    ROUND(AVG(high_level_salary_net), 0) AS high
   FROM hh_it_spark
LATERAL view explode(vacancy_group) stock_tble AS vacancy
  WHERE low_level_salary_net > 10000 OR high_level_salary_net <1000000
  GROUP BY vacancy
  ORDER BY high DESC;

 --Заработная плата по специальностям Россия Median
 SELECT vacancy,
	    COUNT(vacancy) AS amount,
	    ROUND(percentile_approx(low_level_salary_net, 0.5), 0) AS low,
	    ROUND(percentile_approx(high_level_salary_net, 0.5), 0) AS high
   FROM hh_it_spark
LATERAL view explode(vacancy_group) stock_tble AS vacancy
  WHERE (low_level_salary_net IS NOT NULL OR high_level_salary_net IS NOT NULL)
  GROUP BY vacancy
  ORDER BY high DESC;

--Заработная плата по специальностям Москва AVG
 SELECT vacancy,
	    COUNT(vacancy) AS amount,
	    ROUND(AVG(low_level_salary_net), 0) AS low,
	    ROUND(AVG(high_level_salary_net), 0) AS high
   FROM hh_it_spark
LATERAL view explode(vacancy_group) stock_tble AS vacancy
  WHERE (low_level_salary_net > 10000 OR high_level_salary_net <1000000) AND city_from_url = "Москва"
  GROUP BY vacancy
  ORDER BY high DESC;
 
 --Заработная плата по специальностям Москва Median
 SELECT vacancy,
	    COUNT(vacancy) AS amount,
	    ROUND(percentile_approx(low_level_salary_net, 0.5), 0) AS low,
	    ROUND(percentile_approx(high_level_salary_net, 0.5), 0) AS high
   FROM hh_it_spark
LATERAL view explode(vacancy_group) stock_tble AS vacancy
  WHERE (low_level_salary_net IS NOT NULL OR high_level_salary_net IS NOT NULL) AND city_from_url = "Москва"
  GROUP BY vacancy
  ORDER BY high DESC;
  
-- Зароботная плата по языкам программирования Россия AVG
 SELECT programming_language,
        COUNT(programming_language) AS amount,
        ROUND(AVG(low_level_salary_net), 0) AS low,
	    ROUND(AVG(high_level_salary_net), 0) AS high
   FROM hh_it_spark
LATERAL view explode(prog_language) stock_tble AS programming_language
  WHERE (low_level_salary_net > 10000 OR high_level_salary_net <1000000) AND programming_language <> ".NET"
  GROUP BY programming_language
 HAVING amount > 10
  ORDER BY high DESC;
 
-- Зароботная плата по языкам программирования Россия Median
 SELECT programming_language,
        COUNT(programming_language) AS amount,
	    ROUND(percentile_approx(low_level_salary_net, 0.5), 0) AS low,
	    ROUND(percentile_approx(high_level_salary_net, 0.5), 0) AS high
   FROM hh_it_spark
LATERAL view explode(prog_language) stock_tble AS programming_language
  WHERE (low_level_salary_net IS NOT NULL OR high_level_salary_net IS NOT NULL) AND programming_language <> ".NET"
  GROUP BY programming_language
 HAVING amount > 10
  ORDER BY high DESC;
 
 -- Зароботная плата по языкам программирования Москва AVG
 SELECT programming_language,
        COUNT(programming_language) AS amount,
        ROUND(AVG(low_level_salary_net), 0) AS low,
	    ROUND(AVG(high_level_salary_net), 0) AS high
   FROM hh_it_spark
LATERAL view explode(prog_language) stock_tble AS programming_language
  WHERE (low_level_salary_net > 10000 OR high_level_salary_net <1000000) AND programming_language <> ".NET" AND city_from_url = "Москва"
  GROUP BY programming_language
 HAVING amount > 10
  ORDER BY high DESC;
 
 -- Зароботная плата по языкам программирования Москва Median
 SELECT programming_language,
        COUNT(programming_language) AS amount,
	    ROUND(percentile_approx(low_level_salary_net, 0.5), 0) AS low,
	    ROUND(percentile_approx(high_level_salary_net, 0.5), 0) AS high
   FROM hh_it_spark
LATERAL view explode(prog_language) stock_tble AS programming_language
  WHERE (low_level_salary_net IS NOT NULL OR high_level_salary_net IS NOT NULL) AND programming_language <> ".NET" AND city_from_url = "Москва"
  GROUP BY programming_language
 HAVING amount > 10
  ORDER BY high DESC;
 
  -- Зароботная плата от требуемого опыта Россия AVG
 SELECT experience,
        COUNT(experience) AS amount,
        ROUND(AVG(low_level_salary_net), 0) AS low,
	    ROUND(AVG(high_level_salary_net), 0) AS high
   FROM hh_it_spark
  WHERE (low_level_salary_net > 10000 OR high_level_salary_net <1000000)
  GROUP BY experience
  ORDER BY high DESC;
 
   -- Зароботная плата от требуемого опыта Россия Median
 SELECT experience,
        COUNT(experience) AS amount,
	    ROUND(percentile_approx(low_level_salary_net, 0.5), 0) AS low,
	    ROUND(percentile_approx(high_level_salary_net, 0.5), 0) AS high
   FROM hh_it_spark
  WHERE (low_level_salary_net IS NOT NULL OR high_level_salary_net IS NOT NULL)
  GROUP BY experience
  ORDER BY high DESC;
 
  -- Зароботная плата от требуемого опыта Москва AVG
 SELECT experience,
        COUNT(experience) AS amount,
        ROUND(AVG(low_level_salary_net), 0) AS low,
	    ROUND(AVG(high_level_salary_net), 0) AS high
   FROM hh_it_spark
  WHERE (low_level_salary_net > 10000 OR high_level_salary_net <1000000) AND city_from_url = "Москва"
  GROUP BY experience
  ORDER BY high DESC;
 
   -- Зароботная плата от требуемого опыта Москва Median
 SELECT experience,
        COUNT(experience) AS amount,
	    ROUND(percentile_approx(low_level_salary_net, 0.5), 0) AS low,
	    ROUND(percentile_approx(high_level_salary_net, 0.5), 0) AS high
   FROM hh_it_spark
  WHERE (low_level_salary_net IS NOT NULL OR high_level_salary_net IS NOT NULL) AND city_from_url = "Москва"
  GROUP BY experience
  ORDER BY high DESC;
 
 --Заработная плата от уровня Россия AVG
 SELECT COUNT(experience) AS amount,
        ROUND(AVG(low_level_salary_net), 0) AS low,
	    ROUND(AVG(high_level_salary_net), 0) AS high,
 		(CASE
			WHEN title LIKE "%junior%" THEN "junior"
			WHEN title LIKE "%middle%" THEN "middle"
			WHEN title LIKE "%senior%" THEN "senior"
			WHEN title LIKE "%teamlead%" THEN "teamlead"
			WHEN title LIKE "%team lead%" THEN "teamlead"
		END)
			AS experience
  FROM hh_it_spark
 WHERE (low_level_salary_net > 10000 OR high_level_salary_net <1000000)
 GROUP BY
 		(CASE
			WHEN title LIKE "%junior%" THEN "junior"
			WHEN title LIKE "%middle%" THEN "middle"
			WHEN title LIKE "%senior%" THEN "senior"
			WHEN title LIKE "%teamlead%" THEN "teamlead"
			WHEN title LIKE "%team lead%" THEN "teamlead"
		END)
HAVING experience IS NOT NULL
 ORDER BY high DESC;

--Заработная плата от уровня Москва AVG
 SELECT COUNT(experience) AS amount,
        ROUND(AVG(low_level_salary_net), 0) AS low,
	    ROUND(AVG(high_level_salary_net), 0) AS high,
 		(CASE
			WHEN title LIKE "%junior%" THEN "junior"
			WHEN title LIKE "%middle%" THEN "middle"
			WHEN title LIKE "%senior%" THEN "senior"
			WHEN title LIKE "%teamlead%" THEN "teamlead"
			WHEN title LIKE "%team lead%" THEN "teamlead"
		END)
			AS experience
   FROM hh_it_spark
  WHERE city_from_url = "Москва" AND (low_level_salary_net > 10000 OR high_level_salary_net <1000000)
  GROUP BY
 		(CASE
			WHEN title LIKE "%junior%" THEN "junior"
			WHEN title LIKE "%middle%" THEN "middle"
			WHEN title LIKE "%senior%" THEN "senior"
			WHEN title LIKE "%teamlead%" THEN "teamlead"
			WHEN title LIKE "%team lead%" THEN "teamlead"
		END)
 HAVING experience IS NOT NULL
  ORDER BY high DESC;

 --Заработная плата Data Scientist от уровня Россия AVG
 SELECT COUNT(experience) AS amount,
        ROUND(AVG(low_level_salary_net), 0) AS low,
	    ROUND(AVG(high_level_salary_net), 0) AS high,
 		(CASE
			WHEN title LIKE "%junior%" THEN "junior"
			WHEN title LIKE "%middle%" THEN "middle"
			WHEN title LIKE "%senior%" THEN "senior"
			WHEN title LIKE "%teamlead%" THEN "teamlead"
			WHEN title LIKE "%team lead%" THEN "teamlead"
		END)
			AS experience
   FROM hh_it_spark
LATERAL view explode(vacancy_group) stock_tble AS vacancy
  WHERE (low_level_salary_net > 10000 OR high_level_salary_net <1000000) AND vacancy = "Data scientist"
  GROUP BY
 		(CASE
			WHEN title LIKE "%junior%" THEN "junior"
			WHEN title LIKE "%middle%" THEN "middle"
			WHEN title LIKE "%senior%" THEN "senior"
			WHEN title LIKE "%teamlead%" THEN "teamlead"
			WHEN title LIKE "%team lead%" THEN "teamlead"
		END)
 HAVING experience IS NOT NULL
  ORDER BY high DESC;

 --Заработная плата Data Scientist от уровня Москва AVG
 SELECT COUNT(experience) AS amount,
        ROUND(AVG(low_level_salary_net), 0) AS low,
	    ROUND(AVG(high_level_salary_net), 0) AS high,
 		(CASE
			WHEN title LIKE "%junior%" THEN "junior"
			WHEN title LIKE "%middle%" THEN "middle"
			WHEN title LIKE "%senior%" THEN "senior"
			WHEN title LIKE "%teamlead%" THEN "teamlead"
			WHEN title LIKE "%team lead%" THEN "teamlead"
		END)
			AS experience
   FROM hh_it_spark
LATERAL view explode(vacancy_group) stock_tble AS vacancy
  WHERE (low_level_salary_net > 10000 OR high_level_salary_net <1000000) and vacancy = "Data scientist" AND city_from_url = "Москва"
  GROUP BY
 		(CASE
			WHEN title LIKE "%junior%" THEN "junior"
			WHEN title LIKE "%middle%" THEN "middle"
			WHEN title LIKE "%senior%" THEN "senior"
			WHEN title LIKE "%teamlead%" THEN "teamlead"
			WHEN title LIKE "%team lead%" THEN "teamlead"
		END)
 HAVING experience IS NOT NULL
  ORDER BY high DESC;

  --Заработная плата Data Scientist от лет опыта Россия AVG
 SELECT 
 		experience,
 		COUNT(experience) AS amount,
        ROUND(AVG(low_level_salary_net), 0) AS low,
	    ROUND(AVG(high_level_salary_net), 0) AS high
   FROM hh_it_spark
LATERAL view explode(vacancy_group) stock_tble AS vacancy
  WHERE (low_level_salary_net > 10000 OR high_level_salary_net <1000000) and vacancy = "Data scientist"
  GROUP BY experience
  ORDER BY high DESC;
 
 --Заработная плата Data Scientist от лет опыта Москва AVG
 SELECT 
 		experience,
 		COUNT(experience) AS amount,
        ROUND(AVG(low_level_salary_net), 0) AS low,
	    ROUND(AVG(high_level_salary_net), 0) AS high
   FROM hh_it_spark
LATERAL view explode(vacancy_group) stock_tble AS vacancy
  WHERE (low_level_salary_net > 10000 OR high_level_salary_net <1000000) and vacancy = "Data scientist" AND city_from_url = "Москва"
  GROUP BY experience
  ORDER BY high DESC;
 
  --Заработная плата Data Engineer от лет опыта Россия AVG
 SELECT 
 		experience,
 		COUNT(experience) AS amount,
        ROUND(AVG(low_level_salary_net), 0) AS low,
	    ROUND(AVG(high_level_salary_net), 0) AS high
   FROM hh_it_spark
LATERAL view explode(vacancy_group) stock_tble AS vacancy
  WHERE (low_level_salary_net > 10000 OR high_level_salary_net <1000000) and vacancy = "Data Engineer"
  GROUP BY experience
  ORDER BY high DESC;
 
 --Заработная плата Data Engineer от лет опыта Москва AVG
 SELECT 
 		experience,
 		COUNT(experience) AS amount,
        ROUND(AVG(low_level_salary_net), 0) AS low,
	    ROUND(AVG(high_level_salary_net), 0) AS high
   FROM hh_it_spark
LATERAL view explode(vacancy_group) stock_tble AS vacancy
  WHERE (low_level_salary_net > 10000 OR high_level_salary_net <1000000) and vacancy = "Data Engineer" AND city_from_url = "Москва"
  GROUP BY experience
  ORDER BY high DESC;
 
  --Топ работодателей в ИТ, Россия
 SELECT DISTINCT(employer),
        COUNT(employer) OVER w AS amount,
        FIRST_VALUE(employer_rating) OVER w AS RATING
   FROM hh_it_spark
 WINDOW w AS (PARTITION BY employer)
  ORDER BY amount DESC
        LIMIT 20;
       
--Топ работодателей в ИТ, Москва
CREATE TEMPORARY TABLE IF NOT EXISTS tmp_emp11 AS
 SELECT DISTINCT(employer),
        COUNT(employer) OVER w AS amount,
        FIRST_VALUE(employer_rating) OVER w AS RATING
   FROM hh_it_spark
  WHERE city_from_url = "Москва"
 WINDOW w AS (PARTITION BY employer)
  ORDER BY amount DESC
        LIMIT 20;
       
CREATE TEMPORARY TABLE IF NOT EXISTS tmp_emp22 AS
 SELECT employer,
        COUNT(employer) AS amount
   FROM hh_it_spark
  WHERE city_from_url = "Москва" AND (low_level_salary_net IS NOT NULL OR high_level_salary_net IS NOT NULL)
  GROUP BY employer;

SELECT * FROM tmp_emp11 t1
		 LEFT JOIN tmp_emp22 t2
		 ON t1.employer = t2.employer;