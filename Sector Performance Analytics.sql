-- ============================================================
-- Sector Performance Analytics
-- Part of the SectorPulse project
-- Dataset: sector_returns (180 rows - 15 years of monthly
-- sector ETF returns)
-- ============================================================

----------------------------------------------------------------
-- Q1: Which sector had the best risk-adjusted performance
-- over 15 years?
-- FINDING: Technology had the best risk/reward - highest
-- average return (1.57), lowest volatility (5.50). Energy
-- was worst - lowest average return (0.86), highest
-- volatility (7.79).
----------------------------------------------------------------

SELECT 
    AVG(technology) AS avg_technology, STDEV(technology) AS vol_technology,
    AVG(energy)     AS avg_energy,     STDEV(energy)     AS vol_energy,
    AVG(financials) AS avg_financials, STDEV(financials) AS vol_financials
FROM sector_returns;

----------------------------------------------------------------
-- Q2: In which year did Technology perform best, and worst?
-- FINDING: Technology peaked in 2020 - tied to the COVID-19
-- remote-work and cloud-computing demand surge.
----------------------------------------------------------------

-- Best year
SELECT TOP 1 YEAR(date) AS year, AVG(technology) AS avg_technology
FROM sector_returns
GROUP BY YEAR(date)
ORDER BY avg_technology DESC;

-- Worst year
SELECT TOP 1 YEAR(date) AS year, AVG(technology) AS avg_technology
FROM sector_returns
GROUP BY YEAR(date)
ORDER BY avg_technology ASC;

----------------------------------------------------------------
-- Q3: Which sector performed best in each individual year
-- (not just overall)?
-- Reshapes sector columns into rows (technology/energy/
-- financials as separate rows per year) using UNION ALL,
-- then ranks sectors within each year using
-- RANK() OVER (PARTITION BY year ORDER BY avg_return DESC).
-- FINDING: Sector leadership rotates over time rather than
-- staying fixed. Energy and Financials led in the early
-- 2010s; Technology dominated 2014-2019 and peaked again in
-- 2020 (COVID digital shift). Energy then surged back to #1
-- in 2021-2022 (5.30 avg return in 2022 - likely tied to the
-- post-COVID inflation/energy price shock), before Technology
-- and Financials retook the lead in 2023-2024.
----------------------------------------------------------------

WITH yearly_sector_returns AS (
    SELECT YEAR(date) AS year, 'technology' AS sector, AVG(technology) AS avg_return
    FROM sector_returns GROUP BY YEAR(date)

    UNION ALL

    SELECT YEAR(date) AS year, 'energy' AS sector, AVG(energy) AS avg_return
    FROM sector_returns GROUP BY YEAR(date)

    UNION ALL

    SELECT YEAR(date) AS year, 'financials' AS sector, AVG(financials) AS avg_return
    FROM sector_returns GROUP BY YEAR(date)
)
SELECT year, sector, avg_return,
    RANK() OVER (PARTITION BY year ORDER BY avg_return DESC) AS rank_in_year
FROM yearly_sector_returns
ORDER BY year, rank_in_year;

----------------------------------------------------------------
-- Q4: How much did each sector's average return change year
-- over year?
-- Reuses the same UNION ALL reshape as Q3, then adds a second
-- CTE that uses LAG() OVER (PARTITION BY sector ORDER BY year)
-- to pull each row's previous-year return, and subtracts it
-- to get the actual change.
-- FINDING: Energy's YoY change shows a boom-bust pattern -
-- huge gains in 2021-2022 followed by a sharp -5.43 drop in
-- 2023. Technology also saw a steep -3.83 swing from 2021 to
-- 2022 (tech selloff), while Financials shows the most
-- frequent large swings year to year across the dataset.
----------------------------------------------------------------

WITH yearly_sector_returns AS (
    SELECT YEAR(date) AS year, 'technology' AS sector, AVG(technology) AS avg_return
    FROM sector_returns GROUP BY YEAR(date)

    UNION ALL

    SELECT YEAR(date) AS year, 'energy' AS sector, AVG(energy) AS avg_return
    FROM sector_returns GROUP BY YEAR(date)

    UNION ALL

    SELECT YEAR(date) AS year, 'financials' AS sector, AVG(financials) AS avg_return
    FROM sector_returns GROUP BY YEAR(date)
),
with_prev_year AS (
    SELECT year, sector, avg_return,
        LAG(avg_return) OVER (PARTITION BY sector ORDER BY year) AS prev_year_return
    FROM yearly_sector_returns
)
SELECT year, sector, avg_return, prev_year_return,
    avg_return - prev_year_return AS yoy_change
FROM with_prev_year
ORDER BY sector, year;

----------------------------------------------------------------
-- Q5: How would you classify each (year, sector) row's
-- performance level?
-- Adds a CASE WHEN on top of the same reshaped
-- yearly_sector_returns data, turning raw avg_return numbers
-- into readable categories (Strong/Moderate/Weak year)
-- instead of leaving the reader to interpret raw decimals.
-- FINDING: Technology had the most "Strong" years (6 of 15),
-- reflecting consistent outperformance (2019-2021, 2023-2024)
-- with only one weak year (the 2022 selloff). Financials was
-- the most stable sector, landing in "Moderate" 10 of 15
-- years and rarely hitting an extreme. Energy was the most
-- volatile, swinging between "Weak" (6 years) and sharp
-- "Strong" spikes (2021-2022), consistent with its boom-bust
-- commodity cycle pattern seen in the year-over-year analysis.
----------------------------------------------------------------

WITH yearly_sector_returns AS (
    SELECT YEAR(date) AS year, 'technology' AS sector, AVG(technology) AS avg_return
    FROM sector_returns GROUP BY YEAR(date)

    UNION ALL

    SELECT YEAR(date) AS year, 'energy' AS sector, AVG(energy) AS avg_return
    FROM sector_returns GROUP BY YEAR(date)

    UNION ALL

    SELECT YEAR(date) AS year, 'financials' AS sector, AVG(financials) AS avg_return
    FROM sector_returns GROUP BY YEAR(date)
)
SELECT year, sector, avg_return,
    CASE
        WHEN avg_return > 2 THEN 'strong year'
        WHEN avg_return BETWEEN 0 AND 2 THEN 'moderate year'
        ELSE 'weak year'
    END AS performance_tier
FROM yearly_sector_returns
ORDER BY sector, year;



