-- Prefix "g_" means these are fresh data scraped from Github directly
-- the ID columns cannot be matched against GHTorrent data,
-- must unique names such as user.login, and projects.name instead.
DROP TABLE IF EXISTS `g_projects`;
CREATE TABLE `g_projects` (
`id` INT(11) NOT NULL,
`owner_id` INT(11) NOT NULL,
`owner_login` INT(11) NOT NULL,
`name` VARCHAR(100) NOT NULL,
`lang` VARCHAR(255) NOT NULL,
`forks_count` INT(7) NOT NULL DEFAULT 0,
`stargazers_count` INT(7) NOT NULL DEFAULT 0,
`size` INT(11) NOT NULL,
`created_at` TIMESTAMP NOT NULL DEFAULT 0,
`updated_at` TIMESTAMP NOT NULL DEFAULT 0,
`pushed_at` TIMESTAMP NOT NULL DEFAULT 0,
`parent_id` INT(11) NULL,
`source_id` INT(11) NULL,
`description` TEXT CHARACTER SET utf8mb4 NOT NULL DEFAULT '' 
) ENGINE = INNODB
ROW_FORMAT = COMPRESSED
KEY_BLOCK_SIZE = 1
DEFAULT CHARACTER SET = utf8;

DROP TABLE IF EXISTS `g_issues`;
CREATE TABLE `g_issues` (
`id` INT(11) NOT NULL,
`is_pull_request` TINYINT(1) NOT NULL DEFAULT 0,
`created_at` TIMESTAMP NOT NULL DEFAULT 0,
`user_id` INT(11) NOT NULL,
-- `user_login` is a dedundent column to make it easier to
-- reuse GHTorrent data
`user_login` VARCHAR(40) NOT NULL,
`repo` VARCHAR(141) NOT NULL,
`state` VARCHAR(10) NOT NULL,
`number` INT(10) NOT NULL,
`comments` INT(11) NOT NULL DEFAULT 0,
`closed_at` TIMESTAMP NULL,
`updated_at` TIMESTAMP NULL,
`title` TEXT CHARACTER SET utf8mb4,
`body` TEXT CHARACTER SET utf8mb4,
PRIMARY KEY (`id`)
) ENGINE = INNODB
ROW_FORMAT = COMPRESSED
KEY_BLOCK_SIZE = 1
DEFAULT CHARACTER SET = utf8;

DROP TABLE IF EXISTS `g_users`;
CREATE TABLE `g_users` (
`id` INT(11) NOT NULL,
`login` VARCHAR(40) NOT NULL,
PRIMARY KEY (`id`),
UNIQUE KEY (`login`)
) ENGINE = MyISAM
DEFAULT CHARACTER SET = utf8;

DROP TABLE IF EXISTS `g_issue_events`;
CREATE TABLE g_issue_events (
`id` INT(11) NOT NULL,
`created_at` TIMESTAMP NOT NULL DEFAULT 0,
`issue_id` INT(11) NOT NULL,
`event` VARCHAR(30) NOT NULL DEFAULT '',
`repo` VARCHAR(141) NOT NULL,
`actor_id` INT(11) NOT NULL,
`actor_login` VARCHAR(40) NOT NULL,
`commit_id` VARCHAR(40) NULL,
PRIMARY KEY (id)
) ENGINE = INNODB
ROW_FORMAT = COMPRESSED
KEY_BLOCK_SIZE = 2
DEFAULT CHARACTER SET = utf8;

DROP TABLE IF EXISTS `g_issue_comments`;
CREATE TABLE g_issue_comments (
`id` INT(11) NOT NULL,
`issue_id` INT(11) NOT NULL,
`user_id` INT(11) NOT NULL,
`user_login` VARCHAR(40) NOT NULL,
`repo` VARCHAR(141) NOT NULL,  -- extraneous column
`created_at` TIMESTAMP NOT NULL DEFAULT 0,
`updated_at` TIMESTAMP NULL,
`body` TEXT CHARACTER SET utf8mb4,
PRIMARY KEY (id)
) ENGINE = INNODB
ROW_FORMAT = COMPRESSED
KEY_BLOCK_SIZE = 1
DEFAULT CHARACTER SET = utf8;

DROP TABLE IF EXISTS `g_stargazers`;
CREATE TABLE g_stargazers (
`repo` VARCHAR(141) NOT NULL,  -- extraneous column
`user_id` INT(11) NOT NULL,
`user_login` VARCHAR(40) NOT NULL,
`starred_at` TIMESTAMP NOT NULL DEFAULT 0
) ENGINE = INNODB
ROW_FORMAT = COMPRESSED
KEY_BLOCK_SIZE = 1
DEFAULT CHARACTER SET = utf8;


-- some other useful stuff ====================
-- determine the maximum length of user login
-- select max(char_length(`login`)) from users;
-- select max(char_length(`name`)) from projects;

-- show server configuration
-- show variables;
-- show running connections;
-- show full processlist;