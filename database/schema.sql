-- Prefix "g_" means these are fresh data scraped from Github directly
-- the ID columns cannot be matched against GHTorrent data,
-- must unique names such as user.login, and projects.name instead.

DROP TABLE IF EXISTS `g_repo`;
CREATE TABLE `g_repo` (
`id` INT(11) UNSIGNED NOT NULL,
`owner_id` INT(11) UNSIGNED NOT NULL,
`owner_login` INT(11) UNSIGNED NOT NULL,
`name` VARCHAR(100) NOT NULL,
`lang` VARCHAR(255) NOT NULL,
`forks_count` MEDIUMINT(7) UNSIGNED NOT NULL DEFAULT 0,
`stargazers_count` INT(7) UNSIGNED NOT NULL DEFAULT 0,
`size` INT(11) UNSIGNED NOT NULL,
`created_at` TIMESTAMP NOT NULL DEFAULT 0,
`updated_at` TIMESTAMP NOT NULL DEFAULT 0,
`pushed_at` TIMESTAMP NOT NULL DEFAULT 0,
`parent_id` INT(11) UNSIGNED NULL,
`source_id` INT(11) UNSIGNED NULL,
`description` TEXT CHARACTER SET utf8mb4
) ENGINE = INNODB
ROW_FORMAT = COMPRESSED
KEY_BLOCK_SIZE = 1
DEFAULT CHARACTER SET = utf8;

DROP TABLE IF EXISTS `g_languages`;
CREATE TABLE `g_languages` (
`repo` VARCHAR(100) NOT NULL,
`lang` VARCHAR(255) NOT NULL,
`size` INT(11) UNSIGNED NOT NULL
) ENGINE = INNODB
ROW_FORMAT = COMPRESSED
KEY_BLOCK_SIZE = 1
DEFAULT CHARACTER SET = utf8;

DROP TABLE IF EXISTS `g_contributors`;
CREATE TABLE g_contributors (
`repo` VARCHAR(141) NOT NULL,
`week` TIMESTAMP NOT NULL DEFAULT 0,
`author` VARCHAR(40) NOT NULL,
`additions` SMALLINT(8) UNSIGNED NOT NULL,
`deletions` SMALLINT(8) UNSIGNED NOT NULL,
`commits` SMALLINT(8) UNSIGNED NOT NULL
) ENGINE = INNODB
ROW_FORMAT = COMPRESSED
KEY_BLOCK_SIZE = 1
DEFAULT CHARACTER SET = utf8;

DROP TABLE IF EXISTS `g_punch_card`;
CREATE TABLE `g_punch_card` (
`repo` VARCHAR(100) NOT NULL,
`day` TINYINT(2) ZEROFILL NOT NULL,
`hour` TINYINT(2) ZEROFILL NOT NULL,
`commits` SMALLINT(11) UNSIGNED NOT NULL
) ENGINE = INNODB
ROW_FORMAT = COMPRESSED
KEY_BLOCK_SIZE = 1
DEFAULT CHARACTER SET = utf8;

DROP TABLE IF EXISTS `g_issues`;
CREATE TABLE `g_issues` (
`id` INT(11) UNSIGNED NOT NULL,
`is_pull_request` TINYINT(1) NOT NULL DEFAULT 0,
`repo` VARCHAR(141) NOT NULL,
`user_id` INT(11) UNSIGNED NOT NULL,
-- `user_login` is a dedundent column to make it easier to
-- reuse GHTorrent data
`user_login` VARCHAR(40) NOT NULL,
`number` MEDIUMINT(10) UNSIGNED NOT NULL,
`state` VARCHAR(10) NOT NULL,
`comments` SMALLINT(11) UNSIGNED NOT NULL DEFAULT 0,
`created_at` TIMESTAMP NOT NULL DEFAULT 0,
`updated_at` TIMESTAMP NULL,
`closed_at` TIMESTAMP NULL,
`title` TEXT CHARACTER SET utf8mb4,
`body` TEXT CHARACTER SET utf8mb4,
PRIMARY KEY (`id`)
) ENGINE = INNODB
ROW_FORMAT = COMPRESSED
KEY_BLOCK_SIZE = 1
DEFAULT CHARACTER SET = utf8;

DROP TABLE IF EXISTS `g_users`;
CREATE TABLE `g_users` (
`id` INT(11) UNSIGNED NOT NULL,
`login` VARCHAR(40) NOT NULL,
PRIMARY KEY (`id`)
) ENGINE = MyISAM
DEFAULT CHARACTER SET = utf8;

DROP TABLE IF EXISTS `g_issue_events`;
CREATE TABLE g_issue_events (
`id` INT(11) UNSIGNED NOT NULL,
`repo` VARCHAR(141) NOT NULL,
`issue_id` INT(11) UNSIGNED NOT NULL,
`actor_id` INT(11) UNSIGNED NOT NULL,
`actor_login` VARCHAR(40) NOT NULL,
`event` VARCHAR(30) NOT NULL DEFAULT '',
`commit_id` VARCHAR(40) NULL,
`created_at` TIMESTAMP NOT NULL DEFAULT 0,
PRIMARY KEY (id)
) ENGINE = INNODB
ROW_FORMAT = COMPRESSED
KEY_BLOCK_SIZE = 2
DEFAULT CHARACTER SET = utf8;

DROP TABLE IF EXISTS `g_issue_comments`;
CREATE TABLE g_issue_comments (
`id` INT(11) UNSIGNED NOT NULL,
`issue_id` INT(11) UNSIGNED NOT NULL,
`user_id` INT(11) UNSIGNED NOT NULL,
`created_at` TIMESTAMP NOT NULL DEFAULT 0,
`repo` VARCHAR(141) NOT NULL,  -- extraneous column
`user_login` VARCHAR(40) NOT NULL,
`updated_at` TIMESTAMP NULL,
`body` TEXT CHARACTER SET utf8mb4,
PRIMARY KEY (id)
) ENGINE = INNODB
ROW_FORMAT = COMPRESSED
KEY_BLOCK_SIZE = 1
DEFAULT CHARACTER SET = utf8;

DROP TABLE IF EXISTS `g_stargazers`;
CREATE TABLE g_stargazers (
`repo` VARCHAR(141) NOT NULL,
`starred_at` TIMESTAMP NOT NULL DEFAULT 0
`user_id` INT(11) UNSIGNED NOT NULL,
`user_login` VARCHAR(40) NOT NULL,
) ENGINE = INNODB
ROW_FORMAT = COMPRESSED
KEY_BLOCK_SIZE = 1
DEFAULT CHARACTER SET = utf8;

-- some other useful stuff ====================

-- the length of the `repo` is defined by these two
-- numbers adding together, plus a "/" character
-- select max(char_length(`login`)) from users;
-- select max(char_length(`name`)) from projects;

-- show server configuration
-- show variables;
-- show running connections;
-- show full processlist;
