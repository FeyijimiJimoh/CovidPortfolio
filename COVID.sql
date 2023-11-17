create database My_Portfolio_Project;
use My_Portfolio_Project;
# SELECTING ALL AND COUNT OF ROWS FROM COVID DEATH TABLE
select * from coviddeath;
select count(*) from coviddeath;

# SELECTING ALL AND COUNT OF ROWS FROM COVID VACCINATION TABLE
select * from covid_vaccination;
select count(*) from covid_vaccination;

# SELECTING ALL AND COUNT OF ROWS FROM COVID POPULATION TABLE
select * from covid_population;
select count(*) from covid_population;

select * from covid_vaccination
where location = 'ghana';
select sum(cast(total_vaccinations as unsigned)) total_vaccinations -- over (partition by location)
from covid_vaccination
where location = 'ghana';
select * from covid_vaccination
order by 3,4;
select * from coviddeath
order by 3,4;

-- select data we are going to be using 
select coviddeath.location, coviddeath.date, population, total_cases, new_cases, total_deaths, population
from coviddeath 
join covid_population 
	on coviddeath.location = covid_population.location
    and coviddeath.date = covid_population.date
order by location, date, population;

# LOOKING AT TOTAL CASE VS TOTAL DEATHS
# SHOWS THE LIKELIHOOD OF DYING IN YOUR COUNTRY
-- SELECT * FROM coviddeath;
select coviddeath.location, coviddeath.date, cast(total_cases as unsigned) total_cases, cast(total_deaths as unsigned) total_deaths, 
(cast(total_deaths as unsigned)/cast(total_cases as unsigned)) * 100 Death_Percentage
from coviddeath
where location like 'nig%'
order by location, date;

# LOOKING AT THE TOTAL CASE VS POPULATION 
select coviddeath.location, coviddeath.date, population, total_cases, (cast(total_cases as unsigned)/population) * 100 Population_Infected_Percentage
from coviddeath 
join covid_population 
	on coviddeath.location = covid_population.location
-- where coviddeath.location = 'united states'
order by Population_Infected_Percentage;

-- select * from covid_population;
# LOOKING AT THE LOCATION WITH THE HIGHEST INFECTION PERCENTAGE
select coviddeath.location, population, MAX(cast(total_cases as unsigned)) Highest_Infection_Count,
(MAX(cast(total_cases as unsigned))/population) * 100 Population_Infected_Percentage
from coviddeath 
join covid_population 
	on coviddeath.location = covid_population.location
-- where coviddeath.location = 'united states'
group by location, population
order by Population_Infected_Percentage;

# SHOWING COUNTRIES WITH THE HIGHEST DEATH COUNT VS POPULATION
-- select location, MAX(cast(total_deaths as int)) Highest_Death_Count
select location, MAX(cast(total_deaths as unsigned)) Highest_Death_Count
from coviddeath 
where continent is not null
group by location
order by Highest_Death_Count desc;

# SHOWING CONTINENT WITH THE HIGHEST DEATH COUNT
-- select location, MAX(cast(total_deaths as int)) Highest_Death_Count
select continent, MAX(cast(total_deaths as unsigned)) Highest_Death_Count
from coviddeath 
-- where continent is null
group by continent
order by Highest_Death_Count desc;

# SHOWING TOTAL CASES OF DEATH %
-- select location, MAX(cast(total_deaths as int)) Highest_Death_Count
select /*date,*/ SUM(new_cases) total_cases, SUM(new_deaths) total_deaths, SUM(new_cases)/SUM(new_deaths)*100 Global_Death_Count
from coviddeath 
where continent is not null
-- group by date
order by Global_Death_Count desc;

select * from covid_population;
# LOOKING AT TOTAL POPULATION VS VACCINATION
-- select location, MAX(cast(total_deaths as int)) Highest_Death_Count
select vac.continent, vac.location, vac.date, population, cast(new_vaccinations as unsigned) new_vaccinations
from covid_vaccination vac 
join covid_population pop
	on vac.location = pop.location
    and vac.date = pop.date
where vac.continent is not null
-- group by date
order by 1,2,3 desc;

# LOOKING AT TOTAL POPULATION VS VACCINATION PARTITIONED BY LOCATION AND DATE
select vac.continent, vac.location, vac.date, population, new_vaccinations,
SUM(cast(new_vaccinations as unsigned)) over (partition by vac.location order by vac.location, vac.date) ROLLING_PEOPLE_VACCINATED
from covid_vaccination vac 
join covid_population pop
	on vac.location = pop.location
    and vac.date = pop.date
where vac.continent is not null
-- group by date
order by 1,2,3 desc;

-- USING COMMON-TABLE-EXPRESSION(CTE) TO CREATE A NEW COLUMN FROM AN ALIASING(DERIVED COLUMN)
with CTE_Pop_VS_Vac as
(
select vac.continent, vac.location, vac.date, population, new_vaccinations,
SUM(cast(new_vaccinations as unsigned)) over (partition by vac.location order by vac.location, vac.date) ROLLING_PEOPLE_VACCINATED
from covid_vaccination vac 
join covid_population pop
	on vac.location = pop.location
    and vac.date = pop.date
where vac.continent is not null
-- group by date
-- order by 1,2,3 desc
) select *, (ROLLING_PEOPLE_VACCINATED/population) * 100 Vaccination_Percentage
from CTE_Pop_VS_Vac;
# CREATING A TEMP TABLE TO re-write the CTE codes above, 
# BUT IN TEMP TABLE YOU HAVE TO SPECIFY THE COLUMN DATATYPES
drop temporary table if exists PERCENT_POP_VACCINATED;
create temporary table PERCENT_POP_VACCINATED
(
continent nvarchar(255),
location nvarchar(255),
-- date date,
population numeric,
new_vaccinations numeric,
ROLLING_PEOPLE_VACCINATED numeric
);

INSERT INTO PERCENT_POP_VACCINATED
( select vac.continent, vac.location, /*-- vac.date,*/ population, new_vaccinations,
-- SUM(cast(new_vaccinations as unsigned)) over (partition by vac.location order by vac.location, vac.date) ROLLING_PEOPLE_VACCINATED
SUM(new_vaccinations) over (partition by vac.location order by vac.location) ROLLING_PEOPLE_VACCINATED
from covid_vaccination vac 
join covid_population pop
	on vac.location = pop.location
    -- and vac.date = pop.date
where vac.continent is not null
-- group by date
-- order by 1,2,3 desc
);
select *, (ROLLING_PEOPLE_VACCINATED/population) * 100 Vaccination_Percentage
from PERCENT_POP_VACCINATED;

# CREATING VIEWS FOR LATER VISUALIZATIONS
create view CREATE_VIEW as
(select vac.continent, vac.location, vac.date, population, new_vaccinations,
SUM(cast(new_vaccinations as unsigned)) over (partition by vac.location order by vac.location, vac.date) ROLLING_PEOPLE_VACCINATED
from covid_vaccination vac 
join covid_population pop
	on vac.location = pop.location
    and vac.date = pop.date
where vac.continent is not null
-- group by date
-- order by 1,2,3 desc
);
select * from CREATE_VIEW;
