-- **********************************************
-- Generate a seed of top 1% popular repositoris
-- **********************************************

-- count number of watchers for each project
DROP TABLE IF EXISTS count_project_watchers;
CREATE TABLE count_project_watchers
SELECT id, n_watchers, LANGUAGE, created_at FROM
(SELECT * FROM
  (SELECT repo_id, count(*) AS n_watchers FROM watchers
   GROUP BY repo_id) project_watchers
INNER JOIN projects
ON projects.id = project_watchers.repo_id) project_watchers
WHERE forked_from IS NULL AND deleted = 0;

-- NULL cannot be used for grouping
UPDATE count_project_watchers
SET `language` = ''
WHERE `language` IS NULL;

DROP TABLE count_lang_projects;
CREATE TABLE count_lang_projects
SELECT COUNT(1) n_projects, LANGUAGE FROM count_project_watchers
GROUP BY LANGUAGE
ORDER BY n_projects DESC;

-- find the top 1% popular projects
DROP TABLE IF EXISTS pop_projects;
CREATE TABLE pop_projects
SELECT id, n_watchers, `language`, percentile FROM
  (SELECT t3.*,
    IF(@prev_lang = `language`,
       @i_projects := @i_projects + 1,
       @i_projects := 1) lc,
    @prev_lang := `language` pl,
    @i_projects / n_projects percentile
  FROM
    (SELECT id, n_watchers, t1.language AS `language`, n_projects FROM
      (SELECT * FROM count_lang_projects
        WHERE n_projects > 100 ORDER BY n_projects 
       -- if we want to select only a subset for testing purpose:
       -- LIMIT 5
      ) AS t1
    CROSS JOIN
     count_project_watchers AS t2
    ON t1.language = t2.language
    ORDER BY `language`, n_watchers, created_at)  AS t3)
  AS t4
WHERE percentile >= 0.99;

-- popular projects with more details
DROP TABLE IF EXISTS `popular_projects`;
CREATE TABLE `popular_projects`
SELECT p.`id`          AS `id`,
       pp.`n_watchers` AS `n_watchers`,
       -- note that this id is not from github
       -- therefore we give it a suffix `_l` meaning `local`
       u.`login`       AS `owner_login`,
       p.`name`        AS `name`,
       CONCAT(u.`login`, "/", p.`name`) AS `repo`,
       u.`type`        AS `user_type`,
       p.`owner_id`    AS `owner_id_l`,
       p.`description` AS `description`,
       p.`language`    AS `language`,
       pp.`percentile`  AS `percentile`
FROM  `pop_projects` AS pp
INNER JOIN `projects` AS p ON p.`id` = pp.`id`
INNER JOIN `users` AS u ON p.`owner_id` = u.`id`;

ALTER TABLE `popular_projects`
  ADD PRIMARY KEY (`id`),
  ADD INDEX (`n_watchers`),
  ADD INDEX (`repo`);
-- remove the intermediate table
-- DROP TABLE IF EXISTS `pop_projects`;