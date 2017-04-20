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
# DROP TABLE IF EXISTS `pop_projects`;


-- Prefix "g_" means these are fresh data scraped from Github directly
-- the ID columns cannot be matched against GHTorrent data,
-- must unique names such as user.login, and projects.name instead.
DROP TABLE IF EXISTS `g_issues`;
CREATE TABLE IF NOT EXISTS `g_issues` (
`id` INT(11) NOT NULL,
`repo` VARCHAR(255) NOT NULL,
`state` VARCHAR(255) NOT NULL,
`created_at` TIMESTAMP NOT NULL,
`is_pull_request` TINYINT(1) NOT NULL DEFAULT '0',
`reporter_id` INT(11) NOT NULL,
-- `reporter_login` is a dedundent column to make it easier to
-- reuse GHTorrent data
`reporter_login` VARCHAR(255) NOT NULL,
`number` INT(10) NOT NULL,
`comments` INT(11) NOT NULL DEFAULT '0',
`closed_at` TIMESTAMP NULL,
`updated_at` TIMESTAMP NULL,
`title` TEXT CHARACTER SET 'utf8mb4',
PRIMARY KEY (`id`)  COMMENT '',
KEY `repo` (`repo`),
KEY `state` (`state`),
KEY `is_pull_request` (`is_pull_request`),
KEY `created_at` (`created_at`),
KEY `closed_at` (`closed_at`)
) ENGINE = INNODB
DEFAULT CHARACTER SET = ANSI;


DROP TABLE IF EXISTS `g_users`;
CREATE TABLE IF NOT EXISTS `g_users` (
`id` INT(11) NOT NULL,
`login` VARCHAR(255) NOT NULL,
PRIMARY KEY (`id`),
UNIQUE KEY (`login`)
) ENGINE = MyISAM
DEFAULT CHARACTER SET = utf8;

DROP TABLE IF EXISTS `g_issue_events`;
CREATE TABLE g_issue_events (
`id` INT(11) NOT NULL,
`repo` VARCHAR(255) NOT NULL,
`event` VARCHAR(255) NOT NULL DEFAULT '',
-- allow NULL just in case GitHub error is broken
`created_at` TIMESTAMP NULL,
`issue_id` INT(11) NOT NULL,
`actor_id` INT(11) NOT NULL,
`actor_login` VARCHAR(255) NOT NULL,
`commit_id` VARCHAR(255) NULL,
PRIMARY KEY (id),
KEY `issue_id` (`issue_id`),
KEY `actor_id` (`actor_id`),
KEY `actor_login` (`actor_login`),
KEY `repo__event__created_at` (`repo`, `event`, `created_at`)
) ENGINE = INNODB
KEY_BLOCK_SIZE = 16
DEFAULT CHARACTER SET = utf8;