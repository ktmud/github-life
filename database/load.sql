SET foreign_key_checks = 0;
LOAD DATA INFILE '/tmp/github__contributors.csv'
IGNORE INTO TABLE `g_contributors` CHARACTER SET utf8mb4;

LOAD DATA INFILE '/tmp/github__issue_comments.csv'
IGNORE INTO TABLE `g_issue_comments` CHARACTER SET utf8mb4;

LOAD DATA INFILE '/tmp/github__issue_events.csv'
IGNORE INTO TABLE `g_issue_events` CHARACTER SET utf8mb4;

LOAD DATA INFILE '/tmp/github__issues.csv'
IGNORE INTO TABLE `g_issues` CHARACTER SET utf8mb4;

LOAD DATA INFILE '/tmp/github__languages.csv'
IGNORE INTO TABLE `g_languages` CHARACTER SET utf8mb4;

LOAD DATA INFILE '/tmp/github__punch_card.csv'
IGNORE INTO TABLE `g_punch_card` CHARACTER SET utf8mb4;

LOAD DATA INFILE '/tmp/github__repo.csv'
IGNORE INTO TABLE `g_repo` CHARACTER SET utf8mb4;

LOAD DATA INFILE '/tmp/github__stargazers.csv'
IGNORE INTO TABLE `g_stargazers` CHARACTER SET utf8mb4;
