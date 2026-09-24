-- ====================================================================
-- WORLD ECONOMIC INDICATORS: ADVANCED ANALYTICAL QUERIES
-- Target Stack: SQLite / MySQL / PostgreSQL
-- Focus: CTEs, Window Functions, Conditional Aggregation & Segmentation
-- ====================================================================

-- 1. WINDOW FUNCTION: Rank Countries by GDP within each Region (Latest Year)
WITH RankedCountries AS (
    SELECT 
        "Country_Name",
        "Region",
        "Year",
        "GDP",
        "HDI",
        DENSE_RANK() OVER (
            PARTITION BY "Region" 
            ORDER BY "GDP" DESC
        ) AS gdp_rank_in_region
    FROM world_indicators
    WHERE "Year" = 2018 AND "GDP" IS NOT NULL AND "Region" IS NOT NULL
)
SELECT 
    "Region",
    gdp_rank_in_region,
    "Country_Name",
    "GDP",
    "HDI"
FROM RankedCountries
WHERE gdp_rank_in_region <= 3
ORDER BY "Region", gdp_rank_in_region;

-- 2. CTE & WINDOW FUNCTION: Year-over-Year (YoY) GDP Growth Rate Calculation
WITH YearlyGDP AS (
    SELECT 
        "Country_Name",
        "Year",
        "GDP",
        LAG("GDP", 1) OVER (
            PARTITION BY "Country_Name" 
            ORDER BY "Year" ASC
        ) AS prev_year_gdp
    FROM world_indicators
    WHERE "GDP" IS NOT NULL
)
SELECT 
    "Country_Name",
    "Year",
    "GDP",
    prev_year_gdp,
    ROUND((("GDP" - prev_year_gdp) / prev_year_gdp) * 100, 2) AS yoy_gdp_growth_pct
FROM YearlyGDP
WHERE prev_year_gdp IS NOT NULL AND "Year" = 2018
ORDER BY yoy_gdp_growth_pct DESC
LIMIT 10;

-- 3. CASE LOGIC: Economic Efficiency & Development Tier Segmentation
SELECT 
    "Country_Name",
    "Year",
    "GDP_per_capita",
    "HDI",
    CASE 
        WHEN "HDI" >= 0.800 AND "GDP_per_capita" >= 20000 THEN 'Very High Dev / High Income'
        WHEN "HDI" >= 0.700 AND "GDP_per_capita" < 20000 THEN 'High Dev / Emerging Income'
        WHEN "HDI" < 0.700 AND "GDP_per_capita" < 5000 THEN 'Developing Economy'
        ELSE 'Balanced Growth / Middle Tier'
    END AS development_segment
FROM world_indicators
WHERE "Year" = 2018 AND "HDI" IS NOT NULL AND "GDP_per_capita" IS NOT NULL
ORDER BY "GDP_per_capita" DESC
LIMIT 15;

-- 4. AGGREGATION: Regional Benchmarking Summary
SELECT 
    "Region",
    COUNT(DISTINCT "Country_Name") AS total_countries,
    ROUND(AVG("HDI"), 3) AS avg_regional_hdi,
    ROUND(AVG("GDP_per_capita"), 2) AS avg_gdp_per_capita,
    ROUND(SUM("GDP"), 2) AS total_regional_gdp
FROM world_indicators
WHERE "Year" = 2018 AND "Region" IS NOT NULL
GROUP BY "Region"
ORDER BY total_regional_gdp DESC;
