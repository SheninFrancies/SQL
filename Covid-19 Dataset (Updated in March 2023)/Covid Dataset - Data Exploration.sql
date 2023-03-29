SELECT * FROM CovidDeaths
ORDER BY location, date;

SELECT * FROM CovidVaccinations
ORDER BY location, date;

SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Total Cases vs Total Deaths (Ratio)
	-- Likelihood of dying if a person is Covid-positive in a particular country
	-- There is a 4% chance of dying if you live in Afghanistan, for example.
SELECT location, date, total_cases, total_deaths, 
CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT)*100 AS DeathRatio
FROM CovidDeaths
WHERE location LIKE '%states%' AND continent IS NOT NULL
ORDER BY location, date

-- Total Cases vs Population
	-- What percentage of population is Covid-positive?
SELECT location, date, population, total_cases,
CAST(total_cases AS FLOAT)/CAST(population AS FLOAT)*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL
--WHERE location LIKE '%states%'
ORDER BY location, date;

-- Countries with Highest Infection Rate against Population
	-- What percentage of the population has Covid and is the highest?
SELECT location, population, MAX(total_cases) AS HighestInfectionCount,
MAX(CAST(total_cases AS FLOAT)/CAST(population AS FLOAT))*100 AS PercentPopulationHighestInfected
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
--WHERE location LIKE '%states%'
ORDER BY PercentPopulationHighestInfected DESC;

-- Countries with the Highest Death Count Per Population
SELECT location, MAX(CAST(total_deaths AS BIGINT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
--WHERE location LIKE '%states%'
ORDER BY TotalDeathCount DESC

-- Continents with Highest death count
SELECT continent, MAX(CAST(total_deaths AS BIGINT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
--WHERE location LIKE '%states%'
ORDER BY TotalDeathCount DESC

-- Breaking down by location: Is this more accurate?
SELECT location, MAX(CAST(total_deaths AS BIGINT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
--WHERE location LIKE '%states%'
ORDER BY TotalDeathCount DESC


-- GLOBAL NUMBERS

SELECT date, SUM(new_cases) AS Total_New_Cases, 
SUM(new_deaths) AS Total_New_Deaths,
SUM(new_deaths)/NULLIF(SUM(new_cases), 0)*100 AS DeathRatio
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date, Total_New_Cases
	-- Another way to get the same result
SELECT date, SUM(new_cases) AS Total_New_Cases, 
SUM(CAST(new_deaths AS BIGINT)) AS Total_New_Deaths,
CASE
	WHEN SUM(new_cases) = 0 THEN 0
	ELSE SUM(new_deaths)/SUM(new_cases)*100
END AS DeathRatio 
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date, Total_New_Cases

-- Across the world, the death percentage:
SELECT SUM(new_cases) AS Total_New_Cases, 
SUM(CAST(new_deaths AS BIGINT)) AS Total_New_Deaths,
CASE
	WHEN SUM(new_cases) = 0 THEN 0
	ELSE SUM(new_deaths)/SUM(new_cases)*100
END AS DeathRatio 
FROM CovidDeaths
WHERE continent IS NOT NULL

------------------------------------------------------------
----------------- JOIN THE TWO TABLES ----------------------
------------------------------------------------------------

SELECT	Deaths.continent, Deaths.location, Deaths.date, 
		Deaths.population, Vaxs.new_vaccinations,
		SUM(CONVERT(BIGINT, Vaxs.new_vaccinations)) 
			OVER (PARTITION BY Deaths.location 
			ORDER BY Deaths.location, Deaths.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS Deaths
	JOIN CovidVaccinations AS Vaxs ON 
		Deaths.location = Vaxs.location AND
		Deaths.date = Vaxs.date
	WHERE Deaths.continent IS NOT NULL
	ORDER BY continent, location, date


-- USING CTE
WITH PopulationVsVaxs (Continent, Location, Date, Population, New_Vaccinations, 
RollingPeopleVaccinated) AS
(
	SELECT	Deaths.continent, Deaths.location, Deaths.date, 
			Deaths.population, Vaxs.new_vaccinations,
			SUM(CONVERT(BIGINT, Vaxs.new_vaccinations)) 
				OVER (PARTITION BY Deaths.location 
				ORDER BY Deaths.location, Deaths.date) AS RollingPeopleVaccinated
	FROM CovidDeaths AS Deaths
		JOIN CovidVaccinations AS Vaxs ON 
			Deaths.location = Vaxs.location AND
			Deaths.date = Vaxs.date
	WHERE Deaths.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentPopulationVaccinated
FROM PopulationVsVaxs

-- Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated (
	Continent NVARCHAR(255), Location NVARCHAR(255), Date DATETIME,
	Population FLOAT, New_Vaccinations NVARCHAR(255), 
	RollingPeopleVaccinated NVARCHAR(255)
	)
INSERT INTO #PercentPopulationVaccinated 
SELECT	Deaths.continent, Deaths.location, Deaths.date, 
			Deaths.population, Vaxs.new_vaccinations,
			SUM(CONVERT(BIGINT, Vaxs.new_vaccinations)) 
				OVER (PARTITION BY Deaths.location 
				ORDER BY Deaths.location, Deaths.date) AS RollingPeopleVaccinated
	FROM CovidDeaths AS Deaths
		JOIN CovidVaccinations AS Vaxs ON 
			Deaths.location = Vaxs.location AND
			Deaths.date = Vaxs.date
	--WHERE Deaths.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated

-- STORE DATA FOR VISUALIZATION USING VIEWS

CREATE VIEW PercentPopulationVaccinated AS
	SELECT	Deaths.continent, Deaths.location, Deaths.date, 
			Deaths.population, Vaxs.new_vaccinations,
			SUM(CONVERT(BIGINT, Vaxs.new_vaccinations)) 
				OVER (PARTITION BY Deaths.location 
				ORDER BY Deaths.location, Deaths.date) AS RollingPeopleVaccinated
	FROM CovidDeaths AS Deaths
		JOIN CovidVaccinations AS Vaxs ON 
			Deaths.location = Vaxs.location AND
			Deaths.date = Vaxs.date
		WHERE Deaths.continent IS NOT NULL

SELECT * FROM PercentPopulationVaccinated


-----------------------------------------------------------
--------------- TABLEAU VISUALIZATION CODE ----------------
-----------------------------------------------------------
-- Table 01
SELECT	SUM(new_cases) AS Total_Cases, 
		SUM(new_deaths) AS Total_Deaths,
		SUM(new_deaths)/SUM(new_cases)*100 AS DeathRatio
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Table 02
Select location, SUM(cast(new_deaths AS BIGINT)) AS TotalDeathCount
FROM CovidDeaths
WHERE	continent IS NULL AND 
		location NOT IN ('World', 'European Union', 'International', 
		'Lower middle income', 'Low income', 'High income', 'Upper middle income', 
		'Upper middle income')
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Table 03
SELECT	location, population, MAX(CAST(total_cases AS BIGINT)) AS HighestInfectionCount,  
		Max((CAST(total_cases AS BIGINT)/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Table 04
SELECT	location, population,date, MAX(total_cases) as HighestInfectionCount,  
		MAX((total_cases/population))*100 as PercentPopulationInfected
FROM CovidDeaths
GROUP BY Location, Population, date
ORDER BY PercentPopulationInfected DESC

-- Table 05
SELECT	Deaths.continent, Deaths.location, Deaths.date, Deaths.population, 
		COALESCE(MAX(CAST(Vaxs.total_vaccinations AS BIGINT)), 0) AS RollingPeopleVaccinated
FROM CovidDeaths Deaths
JOIN CovidVaccinations Vaxs
	ON Deaths.location = Vaxs.location
	AND Deaths.date = Vaxs.date
WHERE Deaths.continent IS NOT NULL 
GROUP BY Deaths.continent, Deaths.location, Deaths.date, Deaths.population
ORDER BY 1,2,3

-- Table 06
WITH PopulationVsVaxs (Continent, Location, Date, Population, New_Vaccinations, 
RollingPeopleVaccinated) AS
(
	SELECT	Deaths.continent, Deaths.location, Deaths.date, 
			Deaths.population, Vaxs.new_vaccinations,
			SUM(CONVERT(BIGINT, Vaxs.new_vaccinations)) 
				OVER (PARTITION BY Deaths.location 
				ORDER BY Deaths.location, Deaths.date) AS RollingPeopleVaccinated
	FROM CovidDeaths AS Deaths
		JOIN CovidVaccinations AS Vaxs ON 
			Deaths.location = Vaxs.location AND
			Deaths.date = Vaxs.date
	WHERE Deaths.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentPopulationVaccinated
FROM PopulationVsVaxs