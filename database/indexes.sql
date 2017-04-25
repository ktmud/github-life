-- Add indexes =================================
-- do this only after all data were inserted!
INSERT IGNORE INTO g_users (id, login)
SELECT distinct(user_id), user_login FROM `g_issues`;

INSERT IGNORE INTO g_users (id, login)
SELECT distinct(user_id), user_login FROM `g_issue_comments`;

INSERT IGNORE INTO g_users (id, login)
SELECT distinct(actor_id), actor_login FROM `g_issue_events`;

ALTER TABLE `g_stargazers`
  ADD INDEX (`repo`, `starred_at`),
  ADD INDEX (`user_id`),
  ALGORITHM = INPLACE,
  LOCK = NONE;

ALTER TABLE `g_issues`
  ADD INDEX (`repo`, `number`),
  ADD INDEX (`repo`, `state`, `created_at`),
  ADD INDEX (`created_at`),
  ADD INDEX (`closed_at`),
  ADD INDEX (`user_id`),
  ADD INDEX (`is_pull_request`),
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
  