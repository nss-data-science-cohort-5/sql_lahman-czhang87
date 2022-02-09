/*## Lahman Baseball Database Exercise
- this data has been made available [online](http://www.seanlahman.com/baseball-archive/statistics/) by Sean Lahman
- you can find a data dictionary [here](http://www.seanlahman.com/files/database/readme2016.txt)
*/
SELECT * 
FROM people
LIMIT 5;

SELECT * 
FROM collegeplaying
WHERE schoolid LIKE '%van%';

SELECT * 
FROM schools
where schoolid = 'vandy';


--1. Find all players in the database who played at Vanderbilt University. Create a list showing each player's first
--and last names as well as the total salary they earned in the major leagues. Sort this list in descending order 
--by the total salary earned. Which Vanderbilt player earned the most money in the majors?
SELECT 
	namefirst, 
	namelast,
	SUM(salary)
FROM people
LEFT JOIN collegeplaying
USING (playerid)
LEFT JOIN salaries
USING (playerid)
WHERE schoolid = 'vandy'
	AND salary IS NOT NULL
GROUP BY namefirst, namelast, playerid
ORDER BY 3 DESC
LIMIT 1;

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
	ROUND(AVG(so/g)::numeric,2) AS strikeouts_per_game
	FROM teams
	WHERE yearid >= 1920
	GROUP BY 1
	ORDER BY 1 desc)
SELECT 
	lower,
	upper, 
	ROUND(AVG(strikeouts_per_game), 2) AS strikeouts_per_game
FROM bins 
LEFT JOIN strikeouts
	ON strikeouts.yearid >= lower
	AND strikeouts.yearid <= upper
GROUP BY lower, upper
ORDER BY lower DESC
;

4. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases. Report the players' names, number of stolen bases, number of attempts, and stolen base percentage.

5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion; determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 to 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

6. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

7. Which pitcher was the least efficient in 2016 in terms of salary / strikeouts? Only consider pitchers who started at least 10 games (across all teams). Note that pitchers often play for more than one team in a season, so be sure that you are counting all stats for each player.

8. Find all players who have had at least 3000 career hits. Report those players' names, total number of hits, and the year they were inducted into the hall of fame (If they were not inducted into the hall of fame, put a null in that column.) Note that a player being inducted into the hall of fame is indicated by a 'Y' in the **inducted** column of the halloffame table.

9. Find all players who had at least 1,000 hits for two different teams. Report those players' full names.

10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

After finishing the above questions, here are some open-ended questions to consider.