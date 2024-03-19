--Football culture is perhaps the greatest in Brazil. Hardly could you find a nation as dedicated to the round leather game as Brazil.
--A country of over 200 million inhabitants, Brazil is home to many football legends both past and present and this is reflected in its rich history within the very roots of the sport.
-- With a record 5 world cups and numerous continental titles, the extent of Brazilian footballing culture cannot be overemphasized.
--This is reflected not only in their national teams but in their first division league known as Brasileirao or simply Brazil Serie A.
--A fairly strong league, perhaps the strongest in South American football. It is home to many top clubs that have achieved various successes at different levels of football.
--This dataset outlines a brief run-through of past football matches of the Brazilian Serie A since 2003
--There are 7 columns in this dataset each representing vital information that could be used during proper analysis
--Represented in this dataset are the various gameweeks denoted as 'round', the home stadium serving as the venue of the corresponding match, the home and away team, two columns denoting the score of the game and a column reporting on the particular serie A season
--This dataset could be used in different ways. Proper analysis can be done to fish out various facts regarding teams, home support, away performances, season with most goals scored etc.

select * from football.dbo.jogos_brasileirao_af;

--First i altered the home and away goals scored column to real numbers to allow flexibility during analysis. This is evident in the set of commands below
alter table Football.dbo.jogos_brasileirao_af
alter column away_score real

--Next the year column must be altered from the varchar data type to date type to also allow flexibility.

alter table football.dbo.jogos_brasileirao_af
alter column year year

--Next, i found the total goals scored by both teams in each individual games. This parameter could later be used during general analysis by season of brazilian clubs.
--First i created the column using the following set of codes
alter table football.dbo.jogos_brasileirao_af
add total_goals_scored real;

--Then i filled the column with data obtained from what was already present in the table.
update Football.dbo.jogos_brasileirao_af
set total_goals_scored = home_score + away_score;

--For further in-depth analysis, i am creating a new column to show the outcome of each match more conspiciously.
--This new column;named Outcome tells the straightforward results of matches i.e home win, away win or draw.
--I'll start by creating the column
alter table Football.dbo.jogos_brasileirao_af 
add outcome varchar (20)
--The followimg set of commands are used to fill up the 'Outcome' column with derived data.
update Football.dbo.jogos_brasileirao_af
set outcome = 'home win' where home_score > away_score
	 'away win' where away_score > home_score
	else 'draw';

--Alternatively, case statements may be used to first visualize the new column with wanted result, this could then be made into a view.
select *, 
	CASE
	  when home_score > away_score then 'home win'
	  when away_score > home_score then 'away win' 
	else 'draw' 
	end as Result
	from Football.dbo.jogos_brasileirao_af;

--Creating the view
create view outcome as 
 select *, 
	CASE
	  when home_score > away_score then 'home win'
	  when away_score > home_score then 'away win' 
	else 'draw' 
	end as Result
	from Football.dbo.jogos_brasileirao_af;

--Data from the Outcome view is used to update the real table.
update Football.dbo.jogos_brasileirao_af 
set Football.dbo.jogos_brasileirao_af.outcome = outcome.result
	from Football.dbo.jogos_brasileirao_af inner join outcome
	on Football.dbo.jogos_brasileirao_af.stadium = outcome.stadium

--Now, lets dive into the dataset for deeper anaysis. Having obtained the outcome column, we can split the results of each year into count of results to visualize the performances of serie a teams over the years.
 select year,outcome, count(outcome) as result_type --over (partition by outcome)
 from Football.dbo.jogos_brasileirao_af
 group by outcome, year
 order by year
 -- Let's make that data into a temp table
 create table #temp_results_type (
 Year real,
 Outcome varchar (255),
 results_type real
 )
 select * from #temp_results_type;

 insert into #temp_results_type
 select year,outcome, count(outcome) as result_type --over (partition by outcome)
 from Football.dbo.jogos_brasileirao_af
 group by outcome, year
 order by year

--Say the difficulty of the league is represented by the amount of draws. Which season would you say was the moost keenly contested?
Select  Year, count(outcome) as toughest_season
	from Football.dbo.jogos_brasileirao_af
	where outcome = 'draw'
	 group by year order by toughest_season desc
	offset 0 rows fetch first 1 row only

--Performances of each clubs with relations to draws by season?
Select  Year, count(outcome) as Number_of_draws
	from Football.dbo.jogos_brasileirao_af
	where away_score = home_score
	 group by year
	 order by year

--Next, let us dive into the specifics. Which are the top 5 best performing clubs on away grounds?
select away_team, count(outcome) as total_away_wins 
from Football.dbo.jogos_brasileirao_af 
where away_score > home_score
group by away_team with rollup
order by count(outcome) desc
offset 0 rows fetch first 5 row only

--Similarly, the process could be repeated for home wins. 
select home_team, count(outcome) as total_home_wins 
from Football.dbo.jogos_brasileirao_af 
where away_score < home_score
group by home_team with rollup
order by count(outcome) desc
offset 0 rows fetch first 5 row only

--And Draws. This is made into a temp table for usage later.
create table #temp_draws (
team varchar (50),
total_draws real
) 
insert into #temp_draws
select home_team, count(outcome) as total_draws
from Football.dbo.jogos_brasileirao_af
where away_score = home_score
group by home_team
order by total_draws desc 
--How many goals were scored each year in the league?
select year, sum(total_goals_scored) as goals_by_year
from Football.dbo.jogos_brasileirao_af
group by year
order by year 
--Which stadium has hosted the most matches since 2003?
select stadium, count(stadium) as matches_hosted
from Football.dbo.jogos_brasileirao_af
group by stadium
order by matches_hosted desc
--Lets check out the usage of stadiums by year. 
--The next lines of commands was used to check the number of games hosted in each stadiums by year.
select stadium, count(stadium) over (partition by year), year
from Football.dbo.jogos_brasileirao_af
group by stadium, year 
--How many teams appeared or participated in 20 seasons of the Serie A since 2023?
--As a team cannot compete without having a stadium to play at home, the home team column can be used to select each and every of the teams to have played in the league within the last 20 years.
select count(distinct home_team) from Football.dbo.jogos_brasileirao_af
--In terms off appearances, which teams are the mainstay in the league? 
--Given that the league has 20 teams. We can use the top ten teams by appearances/games played to show their availability/longetivity.
--This is also made into a temp table
create table #temp_matches (
team varchar (50),
matches_played real
) 
insert into #temp_matches
select home_team, count(home_team) + count(away_team) as matches_played
from Football.dbo.jogos_brasileirao_af
group by home_team
order by matches_played desc
offset 0 rows fetch first 10 rows only
--Of all the teams to have played in the Serie A, which teams at the zenith of results. 
--This could be represented by finding the teams with the most wins.
--i created two tables for this.The home wins and the away wins tables. First is the table with the home team wins. 
--The extracted data is made into a temp table for further use.
create table #temp_home_wins (
home_team varchar (50),
home_wins real
) 
insert into #temp_home_wins
select home_team, count(outcome) as home_wins
from Football.dbo.jogos_brasileirao_af
where home_score > away_score
group by home_team
order by home_wins desc

--Next, for away wins; making it into a temp table
create table #temp_away_wins (
away_team varchar (50),
away_wins real
) 
insert into #temp_away_wins
select away_team, count(outcome) as away_win
from Football.dbo.jogos_brasileirao_af
where away_score > home_score 
group by away_team
order by away_win desc;

--Both of them can be made to;
create table #temp_total_wins (
team varchar (50),
total_wins real
) 
insert into #temp_total_wins
select home_team,a.home_wins +  b.away_wins as total_wins 
	from #temp_home_wins a
	join
	#temp_away_wins b
	on a.home_team = b.away_team
	order by total_wins desc
--Summary of results
--Recall that several temp tables have been made to show total draws and appearances as matches played
--Therefore, using these tables, results of each team can be calculated.
select a.team, a.total_wins, b.total_draws, c.matches_played- (a.total_wins + b.total_draws) as total_loss, c.matches_played  
from #temp_total_wins a
join #temp_draws b on a.team = b.team
join #temp_matches c on a.team = c.team
order by a.total_wins desc
--Lets make this into a final temp table
create table #temp_full_results (
Team varchar (50),
Wins real, 
Draws real,
Loss real,
Matches_Played real
)
insert into #temp_full_results
select a.team, a.total_wins, b.total_draws, c.matches_played- (a.total_wins + b.total_draws) as total_loss, c.matches_played  
from #temp_total_wins a
join #temp_draws b on a.team = b.team
join #temp_matches c on a.team = c.team

--Thus, we arrive at a detailed result of each team showing their performances over 20 years.
--We can see that Sao Paulo has been the best team in that period; with the highest number of wins and lowest number of draws.
--This can be verified as Sao Paulo has won Serie A 3 times in this period as well as Flamengo who came close second.

select * from #temp_full_results

select * from Football.dbo.jogos_brasileirao_af