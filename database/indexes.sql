-- Add indexes =================================
-- do this only after all data were inserted!
ALTER TABLE `g_users`
  ADD UNIQUE INDEX (`login`);

ALTER TABLE `g_contributors`
  ADD UNIQUE INDEX (`repo`, `week`, `author`);

ALTER TABLE `g_languages`
  ADD UNIQUE INDEX (`repo`, `lang`),
  ADD INDEX ALGORITHM = INPLACE;

ALTER TABLE `g_stargazers`
  ADD INDEX (`user_id`),
  ADD INDEX (`user_login`),
  ADD INDEX (`repo`),
  ALGORITHM = INPLACE;
  
ALTER TABLE `g_issue_comments`
  ADD INDEX (`issue_id`),
  ADD INDEX (`user_id`),
  ADD INDEX (`repo`),
  ADD INDEX (`user_login`),
  ALGORITHM = INPLACE;
  
ALTER TABLE `g_issue_events`
  ADD INDEX (`issue_id`),
  ADD INDEX (`actor_id`),
  ADD INDEX (`actor_login`),
  ADD INDEX (`repo`, `event`),
  ALGORITHM = INPLACE;
  
ALTER TABLE `g_issues`
  ADD INDEX (`repo`),
  ADD INDEX (`state`),
  ADD INDEX (`created_at`),
  ADD INDEX (`closed_at`),
  ADD INDEX (`user_id`),
  ADD INDEX (`is_pull_request`),
  ADD INDEX ALGORITHM = INPLACE;

