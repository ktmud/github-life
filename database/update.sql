-- 
-- Clean up deleted/moved repos
--
DELETE t1 FROM g_languages AS t1 LEFT JOIN
 (SELECT CONCAT(owner_login, "/", `name`) AS repo FROM g_repo) AS t2
 ON t1.repo=t2.repo
WHERE t2.repo IS NULL;
