
SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT *
--FROM CovidVaccinations
--ORDER BY 3,4

--SELECT COUNT(*)
--FROM CovidDeaths

--SELECT COUNT(*)
--FROM CovidVaccinations



-- Select data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Looking at total cases vs total deaths
-- To find estimate of likelihood of dying if you contract covid in your country (Maybe a sample of new cases and new deaths is better)
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE location LIKE '%kingdom%' AND continent IS NOT NULL
ORDER BY 1, 2

-- Looking at total cases v population
-- Percentage of recorded Covid cases
SELECT location, date, total_cases, population, (total_cases/population)*100 AS CovidPercentage
FROM CovidDeaths
WHERE location LIKE '%kingdom%' AND continent IS NOT NULL
ORDER BY 1, 2

-- Looking at countries with highest infection rate compared to the population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS CovidPercentage
FROM CovidDeaths
--WHERE location LIKE '%kingdom%'
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC

-- Showing countries with highest death count per population
SELECT location, population, MAX(cast(total_deaths AS int)) AS HighestDeathCount --, MAX((cast(total_deaths AS int)/population))*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 3 DESC

-- LET'S BREAK THINGS DOWN BY CONTINENT

-- This gives the country with the highest death count belonging to each continent without giving the country name
-- E.g. USA from North America has a death count of 576232
SELECT continent, MAX(cast(total_deaths AS int)) AS HighestDeathCount --, MAX((cast(total_deaths AS int)/population))*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC

-- Better - Try to continue with this
SELECT location, population, MAX(cast(total_deaths AS int)) AS HighestDeathCount --, MAX((cast(total_deaths AS int)/population))*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NULL  -- i.e. per continent
GROUP BY location, population
ORDER BY 3 DESC


-- Showing continents with highest death count per population (repeat of above 2)
SELECT continent, MAX(cast(total_deaths AS int)) AS HighestDeathCount --, MAX((cast(total_deaths AS int)/population))*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC

-- Can repeat the above for other metrics!
-- INSERT HERE



-- GLOBAL

-- NOTE: This could be possible using World in the location column

-- Global new cases and deaths per day
SELECT date, SUM(new_cases) AS GlobalNewCases, SUM(CAST(new_deaths AS int)) AS GlobalNewDeaths
	, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths
--WHERE location LIKE '%states%' AND continent IS NOT NULL
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1

-- Global total cases and deaths overall
SELECT SUM(new_cases) AS GlobalNewCases, SUM(CAST(new_deaths AS int)) AS GlobalNewDeaths
	, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths
--WHERE location LIKE '%states%' AND continent IS NOT NULL
WHERE continent IS NOT NULL
ORDER BY 1


-- JOIN VACCINATIONS TABLE

-- Population vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
	--, RollingPeopleVaccinated/population*100
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

-- USE CTE
WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3
)
SELECT *, RollingPeopleVaccinated/population*100
FROM PopVsVac

-- Also; get current totals
WITH PopvVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3
)
SELECT location, population, MAX(RollingPeopleVaccinated) AS TotalVaccinated, MAX(RollingPeopleVaccinated/population*100) AS TotalPercentageVaccinated
FROM PopvVac
GROUP BY location, population
ORDER BY location

-- Use Temp Table
DROP TABLE IF EXISTS #PercentagePopulationVaccinated
CREATE TABLE #PercentagePopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentagePopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, RollingPeopleVaccinated/population*100
FROM #PercentagePopulationVaccinated
ORDER BY location, date

-- CREATE VIEWS FOR FUTURE VISUALISATIONS

CREATE VIEW RollingPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM RollingPopulationVaccinated