-- GridShift AI
-- Basic integrity and scenario validation queries

USE WAREHOUSE GRIDSHIFT_WH;
USE DATABASE GRIDSHIFT_DB;
USE SCHEMA CORE;

-- Expected row counts: 30 workloads and 168 hourly rows in each energy table
SELECT 'AI_WORKLOADS' AS table_name, COUNT(*) AS row_count FROM AI_WORKLOADS
UNION ALL
SELECT 'ELECTRICITY_TARIFFS', COUNT(*) FROM ELECTRICITY_TARIFFS
UNION ALL
SELECT 'RENEWABLE_AVAILABILITY', COUNT(*) FROM RENEWABLE_AVAILABILITY
UNION ALL
SELECT 'GRID_CONDITIONS', COUNT(*) FROM GRID_CONDITIONS
UNION ALL
SELECT 'COMPUTE_CAPACITY', COUNT(*) FROM COMPUTE_CAPACITY;

-- Every hourly timestamp should join across all four context tables
SELECT COUNT(*) AS joined_hourly_rows
FROM HOURLY_ENERGY_CONTEXT;

-- Flexible workloads that are initially placed during peak tariff windows
SELECT
    w.workload_id,
    w.workload_name,
    w.flexibility_level,
    w.baseline_start,
    w.deadline,
    t.tariff_category,
    t.tariff_per_kwh,
    g.grid_status,
    g.grid_load_percentage,
    g.carbon_intensity_gco2_per_kwh
FROM AI_WORKLOADS w
JOIN ELECTRICITY_TARIFFS t
    ON w.baseline_start = t.timestamp
   AND w.location_id = t.location_id
JOIN GRID_CONDITIONS g
    ON w.baseline_start = g.timestamp
   AND w.location_id = g.location_id
WHERE w.flexibility_level <> 'FIXED'
  AND t.tariff_category = 'PEAK'
ORDER BY t.tariff_per_kwh DESC, g.grid_load_percentage DESC;

-- Lowest cost and lower carbon candidate hours
SELECT
    timestamp,
    location_id,
    tariff_per_kwh,
    renewable_percentage,
    grid_load_percentage,
    carbon_intensity_gco2_per_kwh,
    available_capacity_kw,
    capacity_status
FROM HOURLY_ENERGY_CONTEXT
WHERE capacity_status = 'AVAILABLE'
ORDER BY
    tariff_per_kwh ASC,
    carbon_intensity_gco2_per_kwh ASC,
    grid_load_percentage ASC
LIMIT 20;
