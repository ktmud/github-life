-- Add indexes =================================
-- do this only after all data were inserted!
INSERT IGNORE INTO g_users (id, login)
SELECT distinct(user_id), user_login FROM `g_issues`;

INSERT IGNORE INTO g_users (id, login)
SELECT distinct(user_id), user_login FROM `g_issue_comments`;

INSERT IGNORE INTO g_users (id, login)
SELECT distinct(actor_id), actor_login FROM `g_issue_events`;

ALTER TABLE `g_repo`
  ADD UNIQUE INDEX (`owner_login`, `name`),
  ADD INDEX (`size`),
  ADD INDEX (`stargazers_count`),
  ADD INDEX (`lang`),
  ALGORITHM = INPLACE,
  LOCK = NONE;

ALTER TABLE `g_stargazers`
  ADD INDEX (`repo`),
  ADD INDEX (`user_id`),
  ALGORITHM = INPLACE,
  LOCK = NONE;

ALTER TABLE `g_issues`
  ADD INDEX (`user_id`),
  ADD INDEX (`repo`, `created_at`),
  ADD INDEX (`repo`, `number`),
  ALGORITHM = INPLACE,
  LOCK = NONE;
  
ALTER TABLE `g_issue_events`
  ADD INDEX (`repo`, `event`, `created_at`),
  ADD INDEX (`issue_id`),
  ADD INDEX (`actor_id`),
  ALGORITHM = INPLACE,
  LOCK = NONE;
  
ALTER TABLE `g_issue_comments`
  ADD INDEX (`repo`, `issue_number`),
  ALGORITHM = INPLACE,
  LOCK = NONE; 