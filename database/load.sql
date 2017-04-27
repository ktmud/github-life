SET foreign_key_checks = 0;

DELETE t1
FROM g_contributions AS t1
LEFT JOIN (
  SELECT CONCAT(owner_login, '/', `name`) AS repo FROM g_repo
) AS t2
ON t1.repo=t2.repo
WHERE t2.repo IS NULL;
                
LOAD DATA LOCAL INFILE '/tmp/github__contributions.csv'
REPLACE INTO TABLE `g_contributions` 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

DELETE t1
FROM g_contributors AS t1
LEFT JOIN (
  SELECT CONCAT(owner_login, '/', `name`) AS repo FROM g_repo
) AS t2
ON t1.repo=t2.repo
WHERE t2.repo IS NULL;
                
LOAD DATA LOCAL INFILE '/tmp/github__contributors.csv'
REPLACE INTO TABLE `g_contributors` 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

DELETE t1
FROM g_issue_comments AS t1
LEFT JOIN (
  SELECT CONCAT(owner_login, '/', `name`) AS repo FROM g_repo
) AS t2
ON t1.repo=t2.repo
WHERE t2.repo IS NULL;
                
LOAD DATA LOCAL INFILE '/tmp/github__issue_comments.csv'
REPLACE INTO TABLE `g_issue_comments` CHARACTER SET UTF8MB4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

DELETE t1
FROM g_issue_events AS t1
LEFT JOIN (
  SELECT CONCAT(owner_login, '/', `name`) AS repo FROM g_repo
) AS t2
ON t1.repo=t2.repo
WHERE t2.repo IS NULL;
                
LOAD DATA LOCAL INFILE '/tmp/github__issue_events.csv'
REPLACE INTO TABLE `g_issue_events` 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

DELETE t1
FROM g_issues AS t1
LEFT JOIN (
  SELECT CONCAT(owner_login, '/', `name`) AS repo FROM g_repo
) AS t2
ON t1.repo=t2.repo
WHERE t2.repo IS NULL;
                
LOAD DATA LOCAL INFILE '/tmp/github__issues.csv'
REPLACE INTO TABLE `g_issues` CHARACTER SET UTF8MB4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

DELETE t1
FROM g_languages AS t1
LEFT JOIN (
  SELECT CONCAT(owner_login, '/', `name`) AS repo FROM g_repo
) AS t2
ON t1.repo=t2.repo
WHERE t2.repo IS NULL;
                
LOAD DATA LOCAL INFILE '/tmp/github__languages.csv'
REPLACE INTO TABLE `g_languages` 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

DELETE t1
FROM g_punch_card AS t1
LEFT JOIN (
  SELECT CONCAT(owner_login, '/', `name`) AS repo FROM g_repo
) AS t2
ON t1.repo=t2.repo
WHERE t2.repo IS NULL;
                
LOAD DATA LOCAL INFILE '/tmp/github__punch_card.csv'
REPLACE INTO TABLE `g_punch_card` 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

DELETE t1
FROM g_repo AS t1
LEFT JOIN (
  SELECT CONCAT(owner_login, '/', `name`) AS repo FROM g_repo
) AS t2
ON t1.repo=t2.repo
WHERE t2.repo IS NULL;
                
LOAD DATA LOCAL INFILE '/tmp/github__repo.csv'
REPLACE INTO TABLE `g_repo` CHARACTER SET UTF8MB4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

DELETE t1
FROM g_stargazers AS t1
LEFT JOIN (
  SELECT CONCAT(owner_login, '/', `name`) AS repo FROM g_repo
) AS t2
ON t1.repo=t2.repo
WHERE t2.repo IS NULL;
                
LOAD DATA LOCAL INFILE '/tmp/github__stargazers.csv'
REPLACE INTO TABLE `g_stargazers` 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
