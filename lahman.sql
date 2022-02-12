/*## Lahman Baseball Database Exercise
- this data has been made available [online](http://www.seanlahman.com/baseball-archive/statistics/) by Sean Lahman
- you can find a data dictionary [here](http://www.seanlahman.com/files/database/readme2016.txt)
*/

--1. Find all players in the database who played at Vanderbilt University. Create a list showing each player's first
--and last names as well as the total salary they earned in the major leagues. Sort this list in descending order 
--by the total salary earned. Which Vanderbilt player earned the most money in the majors?
SELECT 
	namefirst, 
	namelast,
	SUM(salary)
FROM people
LEFT JOIN (
	SELECT playerid, schoolid
	FROM collegeplaying
	WHERE schoolid = 'vandy'
	UNION
	SELECT playerid, schoolid
	FROM collegeplaying
	WHERE schoolid = 'vandy'
) AS collegeplaying
USING (playerid)
LEFT JOIN salaries
USING (playerid)
WHERE schoolid = 'vandy'
	AND salary IS NOT NULL
GROUP BY namefirst, namelast, playerid
ORDER BY 3 DESC
LIMIT 1;
-- David Price, 81851296

-- Vamsi
SELECT
	name,
	SUM(salary) AS salary
FROM
	(SELECT 
		DISTINCT namefirst || ' ' || namelast AS name,
		salary
	FROM people
	JOIN salaries
	USING(playerid)
	JOIN collegeplaying
	USING(playerid)
	WHERE schoolid = 'vandy' AND salary IS NOT null
	ORDER BY salary DESC) AS sub
GROUP BY name
ORDER BY salary DESC;

--Joshua
SELECT 
	namefirst, 
	namelast, 
	SUM(salary)::numeric::money AS total_salary
FROM people
INNER JOIN salaries
	USING (playerid)
WHERE playerid IN
	(
	SELECT playerid
	FROM collegeplaying
	WHERE schoolid = 'vandy'
	)
GROUP BY namefirst, namelast
ORDER BY total_salary DESC;

--Bryan


--2. Using the fielding table, group players into three groups based on their position: label players with position 
--OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" 
--as "Battery". Determine the number of putouts made by each of these three groups in 2016.
SELECT 
	CASE   
		WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
		WHEN pos IN ('P', 'C') THEN 'Battery'
		ELSE 'Outfield' END AS position_group,
	SUM(PO)
FROM fielding
WHERE yearid = 2016
GROUP BY position_group
ORDER BY 2 DESC;

--Ross
WITH cteOutfield AS
(
	SELECT 'Outfield' AS position_group, 
		SUM(po) AS putouts
	FROM fielding
	WHERE pos = 'OF'
		AND yearid = 2016
),
cteInfield AS
(
	SELECT 'Infield' AS position_group, 
		SUM(po) AS putouts
	FROM fielding
	WHERE pos IN
	('SS', '1B', '2B', '3B')
		AND yearid = 2016	
),
cteBattery AS 
(
	SELECT 'Battery' AS position_group, 
		SUM(po) AS putouts
	FROM fielding
	WHERE pos IN
	('P', 'C')
		AND yearid = 2016	
)
SELECT *
FROM cteOutfield
UNION
SELECT *
FROM cteInfield
UNION
SELECT *
FROM cteBattery
ORDER BY putouts DESC;

--3. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal 
--places. Do the same for home runs per game. Do you see any trends? (Hint: For this question, you might find it 
--helpful to look at the **generate_series** function (https://www.postgresql.org/docs/9.1/functions-srf.html). 
--If you want to see an example of this in action, check out this DataCamp video: https://campus.datacamp.com/courses/exploratory-data-analysis-in-sql/summarizing-and-aggregating-numeric-data?ex=6)
WITH 
	bins AS(
	SELECT generate_series(1920,2019, 10) AS lower,
		   generate_series(1929, 2019, 10) AS upper),
		   
	strikeouts AS (
	SELECT 
	yearid,
	SUM(so)/SUM(g)::numeric AS strikeouts_per_game
	FROM teams
	WHERE yearid >= 1920
	GROUP BY 1
	ORDER BY 1 desc)
SELECT 
	lower,
	upper, 
	ROUND(AVG(strikeouts_per_game)*2, 2) AS strikeouts_per_game
FROM bins 
LEFT JOIN strikeouts
	ON strikeouts.yearid >= lower
	AND strikeouts.yearid <= upper
GROUP BY lower, upper
ORDER BY lower DESC
;
--increase

--Bryan
select round(avg(so / g), 2)                                                avg_so_per_g,
       extract(decade from concat(yearid, '-01-01 00:00:00')::timestamp) * 10 as decade
from teams
where yearid >= 1920
group by decade
order by decade;
--

--Joshua
WITH so_hr_decades AS (
	SELECT 
		yearid,
		teamid,
		g,
		FLOOR(yearid/10)*10 AS decade,
		so,
		hr
	FROM teams
)
SELECT
	decade,
	ROUND(SUM(so)*2.0/(SUM(g)), 2) AS so_per_game,
	ROUND(SUM(hr)*2.0/(SUM(g)), 2) AS hr_per_game
FROM so_hr_decades
GROUP BY decade
ORDER BY decade;

--Habee
SELECT TRUNC(YEARID, -1) AS DECADE,
	ROUND(SUM(SO) * 2.0 / SUM(G), 2) AS STRIKEOUTS_PER_GAME,
	ROUND(SUM(HR) * 2.0 / SUM(G), 2) AS HOMERUNS_PER_GAME
FROM TEAMS
WHERE YEARID >= 1920
GROUP BY DECADE
ORDER BY DECADE;


WITH 
	bins AS(
	SELECT generate_series(1920,2019, 10) AS lower,
		   generate_series(1929, 2019, 10) AS upper),
		   
	homeruns AS (
	SELECT 
	yearid,
	SUM(hr)/SUM(g)::numeric AS homeruns_per_game
	FROM teams
	WHERE yearid >= 1920
	GROUP BY 1
	ORDER BY 1 desc)
SELECT 
	lower,
	upper, 
	ROUND(AVG(homeruns_per_game), 2) AS homeruns_per_game
FROM bins 
LEFT JOIN homeruns
	ON homeruns.yearid >= lower
	AND homeruns.yearid <= upper
GROUP BY lower, upper
ORDER BY lower DESC
;
--increase

/* 4. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the 
percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or 
being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases. Report the players' names, 
number of stolen bases, number of attempts, and stolen base percentage.
*/

SELECT 
	namefirst||' '||namelast AS name,
	sb, 
	sb+cs AS num_attempts,
	ROUND(sb*100.00/(sb+cs),2) AS sb_pct
FROM Batting
LEFT JOIN people
USING (playerid)
WHERE yearid = 2016
	AND (sb+cs)>=20
ORDER BY sb_pct DESC
LIMIT 1;
-- Chris Owings 91.3%

--Vamsi
SELECT 
	namefirst || ' ' || namelast AS name,
	sb AS stolen_bases,
	sb + cs AS attempts,
	ROUND(sb::numeric / (sb::numeric + cs::numeric), 2) AS stolen_base_pct
FROM batting
LEFT JOIN people
USING(playerid)
WHERE yearid = 2016 AND sb >= 20
ORDER BY stolen_base_pct DESC;

/*5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? 
What is the smallest number of wins for a team that did win the world series? Doing this will probably result in 
an unusually small number of wins for a world series champion; determine why this is the case. Then redo your query,
excluding the problem year. How often from 1970 to 2016 was it the case that a team with the most wins also won 
the world series? What percentage of the time?
*/
WITH 
	ws_champion AS (
	SELECT *
	FROM seriespost
	WHERE yearid BETWEEN 1970 AND 2016
	 AND round = 'WS'
),
	wins AS (
	SELECT *
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016
	)
SELECT wins.yearid, teamid, w
FROM wins
LEFT JOIN ws_champion
ON ws_champion.yearid = wins.yearid
	AND ws_champion.teamidwinner = wins.teamid
WHERE ws_champion.teamidwinner IS NULL
ORDER BY w DESC
LIMIT 1;
--2001,SEA, 116 WINS

WITH 
	ws_champion AS (
	SELECT *
	FROM seriespost
	WHERE yearid BETWEEN 1970 AND 2016
	 AND round = 'WS'
),
	wins AS (
	SELECT *
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016
	)
SELECT wins.yearid, teamid, w
FROM wins
INNER JOIN ws_champion
ON ws_champion.yearid = wins.yearid
	AND ws_champion.teamidwinner = wins.teamid
ORDER BY w
LIMIT 1;
-- 1981, LAN, 63 wins due to strike-shortened season

WITH 
	ws_champion AS (
	SELECT *
	FROM seriespost
	WHERE yearid BETWEEN 1970 AND 2016
	 AND round = 'WS'
),
	wins AS (
	SELECT *
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016
	)
SELECT wins.yearid, teamid, w
FROM wins
INNER JOIN ws_champion
ON ws_champion.yearid = wins.yearid
	AND ws_champion.teamidwinner = wins.teamid
WHERE wins.yearid <>1981
ORDER BY w 
LIMIT 1;
-- 2006, SLN, 83 wins

WITH 
	ws_champion AS (
	SELECT *
	FROM seriespost
	WHERE yearid BETWEEN 1970 AND 2016
	 AND round = 'WS'
	),
	most_wins_per_year AS (
	SELECT yearid, teamid, w
	FROM teams
	INNER JOIN (
		SELECT yearid, MAX(w) w
		FROM teams
		WHERE yearid BETWEEN 1970 AND 2016
		GROUP BY yearid
		ORDER BY 1) AS most_wins_per_year
	USING (yearid, w)
	)
SELECT 
	COUNT(round) AS most_win_champion,
	ROUND(COUNT(round)*100.00/COUNT(m.yearid),2) AS most_win_champion_pct
FROM most_wins_per_year AS m
LEFT JOIN ws_champion AS w
ON m.yearid = w.yearid
	AND m.teamid = w.teamidwinner
--12 teams with most wins in a season won WS champion. pct 22.64%

--Ross
WITH cteYearWins AS
(
	SELECT DISTINCT yearid,
		MAX(W) AS maxwins,
		COUNT(*) OVER() AS maxwin_row_cnt
	FROM teams
	WHERE (yearid >= 1970
			AND yearid <= 2016)	
		AND yearid <> 1981	
	GROUP BY yearid
),
cteWSWins AS
(
	SELECT DISTINCT t.yearid,
		t.name,
		t.W,
		t.WSWin,
		cyw.maxwin_row_cnt AS maxwin_rows
	--	, cyw.maxwins
	FROM teams t
		INNER JOIN cteYearWins cyw
			ON t.yearid = cyw.yearid
			AND t.W = cyw.maxwins
	WHERE (t.yearid >= 1970
			AND t.yearid <= 2016)
		AND t.yearid <> 1981
		AND t.WSWin = 'Y'
--	GROUP BY 1, 2, 3, 4
	ORDER BY t.yearid
)
SELECT yearid,
	name,
	W,
	(100.00 * COUNT(*) OVER() / maxwin_rows) AS pct
FROM cteWSWins;

/*6. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American 
League (AL)? Give their full name and the teams that they were managing when they won the award.
*/
WITH
	manager_award_nl AS(
	SELECT *
	FROM AwardsManagers
	WHERE awardid = 'TSN Manager of the Year'
		AND lgid = 'NL'
	),
	manager_award_al AS (
	SELECT *
	FROM AwardsManagers
	WHERE awardid = 'TSN Manager of the Year'
		AND lgid = 'AL'
	)
SELECT 
	namefirst ||' '|| namelast AS name,
	m.yearid,
	m.teamid
FROM manager_award_nl nl
INNER JOIN manager_award_al al
USING (playerid)
LEFT JOIN people p
USING(playerid)
LEFT JOIN managers m
ON  nl.yearid = m.yearid AND nl.playerid = m.playerid OR
	al.yearid = m.yearid AND al.playerid = m.playerid
UNION
SELECT 
	namefirst ||' '|| namelast AS name,
	m.yearid,
	m.teamid
FROM manager_award_nl nl
INNER JOIN manager_award_al al
USING (playerid)
LEFT JOIN people p
USING(playerid)
LEFT JOIN managers m
ON  nl.yearid = m.yearid AND nl.playerid = m.playerid OR
	al.yearid = m.yearid AND al.playerid = m.playerid
ORDER BY name

/*7. Which pitcher was the least efficient in 2016 in terms of salary / strikeouts? Only consider pitchers who 
started at least 10 games (across all teams). Note that pitchers often play for more than one team in a season, 
so be sure that you are counting all stats for each player.
*/
SELECT 
	namefirst||' '||namelast name,
	ROUND((AVG(salary)/SUM(so))::numeric,2) salary_per_so
FROM pitching p
INNER JOIN people pl
USING (playerid)
INNER JOIN salaries s
USING (playerid)
WHERE p.yearid = 2016
	AND gs>=10
GROUP BY name, p.yearid, p.playerid
ORDER BY 2 DESC;
--

/*8. Find all players who have had at least 3000 career hits. Report those players' names, total number of hits, 
and the year they were inducted into the hall of fame (If they were not inducted into the hall of fame, put a null 
in that column.) Note that a player being inducted into the hall of fame is indicated by a 'Y' in the **inducted** 
column of the halloffame table.
*/
WITH 
	career_hits AS (
	SELECT playerid, SUM(h) AS career_hits
	FROM batting
	LEFT JOIN halloffame
	USING (playerid)
	GROUP BY playerid
	HAVING SUM(h) >=3000
),
	hof_inducted AS (
	SELECT*
	FROM halloffame
	WHERE inducted = 'Y')
SELECT
	namefirst||' '||namelast name,
	career_hits,
	h.yearid hof_year
FROM career_hits 
LEFT JOIN people 
USING (playerid)
LEFT JOIN hof_inducted h
USING (playerid) 
ORDER BY career_hits DESC

--9. Find all players who had at least 1,000 hits for two different teams. Report those players' full names.
WITH 
	above_1000_hits AS (
	SELECT playerid, teamid, SUM(h)
	FROM batting
	GROUP BY playerid, teamid
	HAVING SUM(h) >=1000
	ORDER BY 1
	)
SELECT 
	playerid,
	COUNT(playerid) team_count,
	 namefirst||' '||namelast name
FROM above_1000_hits
LEFT JOIN people
USING(playerid)
GROUP BY playerid, 3
HAVING  COUNT(playerid) = 2

/*10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have 
played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first 
and last names and the number of home runs they hit in 2016.
*/
WITH 
	player_10y_plus AS(
	SELECT
		playerid,
		yearid,
		namefirst||' '||namelast name,
		hr,
		TO_DATE(debut, 'YYYY-MM-DD') debut,
		TO_DATE(finalgame, 'YYYY-MM-DD') finalgame,
		TO_DATE(finalgame, 'YYYY-MM-DD')-TO_DATE(debut, 'YYYY-MM-DD') career_length
	FROM people p
	INNER JOIN batting b
	USING (playerid)
	WHERE finalgame >= '2016-01-01'
		AND TO_DATE(finalgame, 'YYYY-MM-DD')-TO_DATE(debut, 'YYYY-MM-DD')>=3650
		AND b.hr >=1
		AND b.yearid = 2016
	ORDER BY career_length
	), 
	career_high_hr AS(
	SELECT playerid,MAX(hr) hr
	FROM batting
	GROUP BY playerid
	)
SELECT 
	name, 
	yearid,
	player_10y_plus.hr,
	debut, 
	finalgame, 
	career_length
FROM player_10y_plus 
INNER JOIN career_high_hr 
ON player_10y_plus.playerid = career_high_hr.playerid
	AND player_10y_plus.hr = career_high_hr.hr
ORDER BY 3

After finishing the above questions, here are some open-ended questions to consider.