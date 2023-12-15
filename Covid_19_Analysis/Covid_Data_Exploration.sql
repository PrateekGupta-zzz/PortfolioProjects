-- Here we'll try to explore data and get some inerences from the data.
-- Our field of interest are analysis on country level for India, on continent level for Asia and on the world level

-- This is the sample table for CovidDeaths and CovidVaccine
		select *
		from PortfolioProjects..CovidDeaths	
		order by 3,4;


		select *
		from PortfolioProjects..CovidVaccinations
		order by 3, 4;

-- Analysing Things on Single Region
	-- And for now we're interested in the region called 'India'
		select location, date, population, total_cases, total_deaths
		from PortfolioProjects..CovidDeaths
		where location = 'India'
		order by date
		-- The above query shows the increment of the total_cases and total_deaths on daily basis.

	-- Looking at the Death to cases ratio increment with time
			-- Shows likelihood of dying if you contract covid in India
				drop table if exists DeathToCase_Ratio -- Using this before temp table so that alteration can be possible without re-wrinting table name
				create table DeathToCase_Ratio
				(
					location nvarchar(255),
					population numeric,
					TotalInfectioCount numeric,
					TotalDeathCount numeric,
					case_fatality_rate float
				)
					select location, population, max(cast(total_cases as float)) as TotalInfectionCount, max(cast(total_deaths as float)) as TotalDeathCount,  max(cast(total_deaths as float))/max(cast(total_cases as float))*100 as  case_fatality_rate
					from PortfolioProjects..CovidDeaths
					--where location not in ('Asia', 'European Union', 'Upper middle income', 'High income', 'Europe', 'Low income', 'Oceania', 'North America', 'South America', 'World', 'Africa', 'Lower middle income')
					where location = 'India'
					group by location, population
					order by TotalDeathCount desc;

	-- Death count v/s Population
		select location, population, max(cast(total_deaths as float)) as TotalDeathCount
		from PortfolioProjects..CovidDeaths 
		where location = 'India'
		group by location, population
		order by TotalDeathCount desc

-- Analysing things on Global Level
	-- TotalDeaths per Continent
		select continent, max((cast(total_deaths as float))) as TotalDeaths
		from PortfolioProjects..CovidDeaths
		where (continent is not null) and (new_cases is not null)
		group by continent
		order by TotalDeaths desc;

	-- Death Percentage increasing on Daily Basis
		select date, sum(new_cases) as WorldwideCases, sum(cast(new_deaths as int)) as WorldwideDeaths into worldwide
		from PortfolioProjects..CovidDeaths
		where continent is not null
		group by date
		order by date;

		select date, WorldwideCases, WorldwideDeaths, WorldwideDeaths/WorldwideCases*100 as DeathPercentage
		from worldwide
		where WorldwideCases != 0
		order by date

	-- Overall Death Percentage globally
		select sum(new_cases) as WorldwideCases, sum(cast(new_deaths as int)) as WorldwideDeath, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
		from PortfolioProjects..CovidDeaths
		where continent is not null

--------------------------------------------------------------------------------------------------------------------------------------

-- Vaccination Report

	-- Joining our both the tables to get the data on death and vaccination
		select *
		from PortfolioProjects..CovidDeaths dea
		join PortfolioProjects..CovidVaccinations vac
			on dea.location = vac.location
			and dea.date = vac.date
		order by 3, 4
	
		-- Looking at Total population, cases per day and vaccinations per day region wise
		select  dea.continent, dea.location, dea.date, dea.population, dea.new_cases, vac.new_vaccinations, sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
		from PortfolioProjects..CovidDeaths dea
		join PortfolioProjects..CovidVaccinations vac
			on dea.location = vac.location
			and dea.date = vac.date
		where dea.location not in ('Asia', 'European Union', 'Upper middle income', 'High income', 'Europe', 'Low income', 'Oceania', 'North America', 'South America', 'World', 'Africa', 'Lower middle income')
		order by 2, 3


	-- Using CTE
	-- CTE is Common Table Expression which allows you to do multilevel aggregation. Suppose if we want to aggregate over the column 
	-- which we recently are calculating, so with CTE we can aggregate over that as well.
		with POPvsVAC (continent, location, date, population, new_cases, RollingNewCases, new_vaccinations, RollingPeopleVaccinated)
		as
		(
			select  dea.continent, dea.location, dea.date, dea.population, dea.new_cases,
			sum(cast(dea.new_cases as bigint)) over (partition by dea.location order by dea.location, dea.date) as RollingNewCases, 
			vac.new_vaccinations, 
			sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
			from PortfolioProjects..CovidDeaths dea
			join PortfolioProjects..CovidVaccinations vac
				on dea.location = vac.location
				and dea.date = vac.date
			where dea.continent is not null
			--where dea.location = 'Afghanistan'
			--order by 3
		)
		select *, (RollingPeopleVaccinated/population)*100
		from POPvsVAC
		where location = 'Afghanistan'
		order by location, date
	-- People Vaccinated region wise
		drop table if exists #PercentPoplulationVaccinated -- USE this table before temp table so that alteration can be possible without re-wrinting table name
		create table #PercentPoplulationVaccinated
		(
			continent nvarchar(255),
			Location nvarchar(255),
			Date datetime,
			Population numeric,
			--new_cases numeric,
			--RollingNewCases bigint,
			new_vaccinations numeric,
			RollingPeopleVaccinated bigint
		)

		insert into #PercentPoplulationVaccinated
		select  dea.continent, dea.location, dea.date, dea.population, --dea.new_cases,
		--sum(cast(dea.new_cases as bigint)) over (partition by dea.location order by dea.location, dea.date) as RollingNewCases, 
		vac.new_vaccinations, 
		sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
		from PortfolioProjects..CovidDeaths dea
		join PortfolioProjects..CovidVaccinations vac
			on dea.location = vac.location
			and dea.date = vac.date
		where dea.continent is not null
		--where dea.location = 'Canada'
		--order by 2, 3

		select * from #PercentPoplulationVaccinated
		order by location, date