/* 
COVID 19 Data Exploration

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT *
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 3,4

--Select Data that we are going to be starting with 

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 1,2

-- Total Cases vs Total Deaths
--Shows likelihood of dying if you contract Covid in your country

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)* 100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE Location like '%states%'
AND continent is not null
ORDER BY 1,2

--Total Cases vs Population
--Shows what percentage of population infected with Covid

SELECT Location, date, Population, total_cases, (total_cases/Population)* 100 AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
--WHERE Location like '%states%'
ORDER BY 1,2

--Countries with Highest Infection Rate compared to Population

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/Population))* 100 AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
--WHERE Location like '%states%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

--Countries with Highest Death Count per Population

SELECT Location, MAX(cast(Total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
--WHERE Location like '%states%'
WHERE continent is not null
GROUP BY Location
ORDER BY TotalDeathCount DESC



--BREAKING THINGS DOWN BY CONTINENT


--Showing continents with the highest death count per population

SELECT continent, MAX(cast(Total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
--WHERE Location like '%states%'
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

--GLOBAL NUMBERS total per day

SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)* 100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
--WHERE Location like '%states%'
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

--GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)* 100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
--WHERE Location like '%states%'
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2

--Total Population vs Vaccinations
--Shows Percentage of Population that has received at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


--Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100 
FROM PopvsVac


--Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100 
FROM #PercentPopulationVaccinated


--Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null


