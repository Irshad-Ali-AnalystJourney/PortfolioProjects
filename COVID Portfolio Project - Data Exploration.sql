/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases, total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location ='India'
and continent is not null 
Order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location = 'India'
Order by 1,2

 
-- Countries with Highest Infection Rate compared to Population

Select Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location = 'India'
Group by location,population
Order by PercentPopulationInfected DESC


-- Countries with Highest Death Count per Population

Select Location, MAX(total_deaths) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location = 'India'
Where continent is not null
Group by location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

SELECT location, MAX(total_deaths) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE 
    location NOT LIKE '%Income%' 
    AND location NOT LIKE '%union%' 
    AND location NOT LIKE '%World%'
    AND continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;



-- GLOBAL NUMBERS

Select date,SUM(new_cases) as Total_Cases,SUM(new_deaths) as Total_Deaths ,
CASE
	WHEN SUM(new_cases)=0 or SUM(new_deaths)=0 THEN null
	ELSE SUM(new_deaths)/SUM(new_cases)*100 
END as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
Group by date
order by 1,2



-- Total Cases vs Total Deaths

Select SUM(new_cases) as Total_Cases,SUM(new_deaths) as Total_Deaths ,
CASE
	WHEN SUM(new_cases)=0 or SUM(new_deaths)=0 THEN null
	ELSE SUM(new_deaths)/SUM(new_cases)*100 
END as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
order by 1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
		, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,
		dea.date) as RollingPeopleVaccinated
		--,(RollingPeopleVaccinated/dea.population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
		On dea.location=vac.location
		and dea.date=vac.date
Where dea.continent is not null
Group by dea.location,dea.continent,dea.date,dea.population,vac.new_vaccinations
order by 2,3;


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
    Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
		   --, (RollingPeopleVaccinated/population)*100
    From PortfolioProject..CovidDeaths dea
	Join PortfolioProject..CovidVaccinations vac
			On dea.location = vac.location
			and dea.date = vac.date
    Where dea.continent is not null
	Group by dea.location,dea.continent,dea.date,dea.population,vac.new_vaccinations
)
Select *,(RollingPeopleVaccinated/Population)*100 as PercentPeopleVaccinated
From PopvsVac
order by 2,3



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population Numeric,
New_Vaccination Numeric,
RollingPeopleVaccinated Numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
		   --, (RollingPeopleVaccinated/population)*100
    From PortfolioProject..CovidDeaths dea
    Join PortfolioProject..CovidVaccinations vac
    On dea.location = vac.location
    and dea.date = vac.date
    --Where dea.continent is not null
	--order by 2,3
	Group by dea.location,dea.continent,dea.date,dea.population,vac.new_vaccinations
	

Select *,(RollingPeopleVaccinated/Population)*100 as PercentPeopleVaccinated
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
		On dea.location = vac.location
		and dea.date = vac.date
Where dea.continent is not null
Group by dea.location,dea.continent,dea.date,dea.population,vac.new_vaccinations


