SET foreign_key_checks = 0;

LOAD DATA LOCAL INFILE '/tmp/github__contributors.csv'
IGNORE INTO TABLE `g_contributors` 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '/tmp/github__issue_comments.csv'
IGNORE INTO TABLE `g_issue_comments` CHARACTER SET UTF8MB4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '/tmp/github__issue_events.csv'
IGNORE INTO TABLE `g_issue_events` 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '/tmp/github__issues.csv'
IGNORE INTO TABLE `g_issues` CHARACTER SET UTF8MB4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '/tmp/github__languages.csv'
IGNORE INTO TABLE `g_languages` 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '/tmp/github__punch_card.csv'
IGNORE INTO TABLE `g_punch_card` 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '/tmp/github__repo.csv'
IGNORE INTO TABLE `g_repo` CHARACTER SET UTF8MB4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '/tmp/github__stargazers.csv'
IGNORE INTO TABLE `g_stargazers` 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
