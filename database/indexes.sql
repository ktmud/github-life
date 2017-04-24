-- Add indexes =================================
-- do this only after all data were inserted!

INSERT IGNORE INTO g_users (id, login)
SELECT distinct(user_id), user_login FROM `g_issues`;

INSERT IGNORE INTO g_users (id, login)
SELECT distinct(user_id), user_login FROM `g_issue_comments`;

INSERT IGNORE INTO g_users (id, login)
SELECT distinct(actor_id), actor_login FROM `g_issue_events`;

ALTER TABLE `g_users`
  ADD UNIQUE INDEX (`login`),
  ALGORITHM = INPLACE,
  LOCK = NONE;

ALTER TABLE `g_stargazers`
  ADD INDEX (`repo`, `starred_at`),
  ADD INDEX (`user_id`),
  ALGORITHM = INPLACE,
  LOCK = NONE;

ALTER TABLE `g_punch_card`
  ADD INDEX (`repo`),
  ALGORITHM = INPLACE,
  LOCK = NONE;

ALTER TABLE `g_languages`
  ADD UNIQUE INDEX (`repo`, `lang`),
  ALGORITHM = INPLACE,
  LOCK = NONE;
  
ALTER TABLE `g_contributors`
  ADD UNIQUE INDEX (`repo`, `week`, `author`),
  ALGORITHM = INPLACE,
  LOCK = NONE;


ALTER TABLE `g_issues`
  ADD INDEX (`repo`, `number`),
  ADD INDEX (`state`),
  ADD INDEX (`created_at`),
  ADD INDEX (`closed_at`),
  ADD INDEX (`user_id`),
  ADD INDEX (`is_pull_request`),
  ALGORITHM = INPLACE,
  LOCK = NONE;
  
ALTER TABLE `g_issue_events`
  ADD INDEX (`repo`, `event`),
  ADD INDEX (`issue_id`),
  ADD INDEX (`actor_id`),
  ALGORITHM = INPLACE,
  LOCK = NONE;
  
ALTER TABLE `g_issue_comments`
  ADD INDEX (`repo`, `issue_number`),
  ALGORITHM = INPLACE,
  LOCK = NONE;
  