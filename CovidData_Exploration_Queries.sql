/*

Covid 19 Data Exploration

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select * from PortfolioProject..['CovidDeaths']
order by 3,4

--Select * from PortfolioProject..['CovidVaccinations']
--order by 3,4


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..['CovidDeaths']

-- Looking at Total Deaths vs Total Cases (Death rate)
-- Shows the likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 AS DeathPercentage
FROM PortfolioProject..['CovidDeaths']
WHERE location = 'United States'


-- Look at Total Cases vs Population
-- Shows what percentage of the population got covid
SELECT location, date, population, total_cases, (total_cases / population)*100 AS CasePopulationPercentage
FROM PortfolioProject..['CovidDeaths']
WHERE location like '%United States%'


-- Looking at Countries with the Highest Infection Count compared to Population 
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)*100) AS MaxCasePercentage
FROM PortfolioProject..['CovidDeaths']
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY MaxCasePercentage DESC


-- Showing Countries with the Highest Death Count per Population
-- Cast total_deaths column as int because it is originally as varchar
-- Filter out the continent data because we only want countries
SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..['CovidDeaths']
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Now break down by Continent
-- Showing continents with the highest death count per population
SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..['CovidDeaths']
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Global numbers

-- Global death percentage each day
SELECT date, SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS int)) AS TotalDeaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage 
FROM PortfolioProject..['CovidDeaths']
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date

-- Global death percentage
SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS int)) AS TotalDeaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage 
FROM PortfolioProject..['CovidDeaths']
WHERE continent IS NOT NULL
--GROUP BY date
--ORDER BY date

-- Looking at Total Vaccinations vs Population
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS 
(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
	FROM PortfolioProject..['CovidDeaths'] dea
	JOIN PortfolioProject..['CovidVaccinations'] vac
	ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS PeopleVaccinatedPercent
FROM PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query
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

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..['CovidDeaths'] dea
JOIN PortfolioProject..['CovidVaccinations'] vac
ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..['CovidDeaths'] dea
JOIN PortfolioProject..['CovidVaccinations'] vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is not null 
