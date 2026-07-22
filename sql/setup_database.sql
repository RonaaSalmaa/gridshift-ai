-- GridShift AI
-- Snowflake database, schema, file format, stage, and table setup
-- Run with a role allowed to create warehouses, databases, and schemas.

CREATE WAREHOUSE IF NOT EXISTS GRIDSHIFT_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

USE WAREHOUSE GRIDSHIFT_WH;

CREATE DATABASE IF NOT EXISTS GRIDSHIFT_DB;
CREATE SCHEMA IF NOT EXISTS GRIDSHIFT_DB.CORE;

USE DATABASE GRIDSHIFT_DB;
USE SCHEMA CORE;

CREATE OR REPLACE FILE FORMAT GRIDSHIFT_CSV_FORMAT
    TYPE = CSV
    FIELD_DELIMITER = ','
    PARSE_HEADER = TRUE
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    EMPTY_FIELD_AS_NULL = TRUE
    NULL_IF = ('', 'NULL', 'null')
    ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE
    ENCODING = 'UTF8';

CREATE STAGE IF NOT EXISTS GRIDSHIFT_STAGE
    FILE_FORMAT = GRIDSHIFT_CSV_FORMAT
    DIRECTORY = (ENABLE = TRUE);

CREATE OR REPLACE TABLE AI_WORKLOADS (
    workload_id VARCHAR(20) NOT NULL,
    workload_name VARCHAR(200) NOT NULL,
    workload_type VARCHAR(50) NOT NULL,
    location_id VARCHAR(50) NOT NULL,
    submitted_at TIMESTAMP_TZ NOT NULL,
    earliest_start TIMESTAMP_TZ NOT NULL,
    baseline_start TIMESTAMP_TZ NOT NULL,
    duration_hours INTEGER NOT NULL,
    power_requirement_kw NUMBER(12,2) NOT NULL,
    deadline TIMESTAMP_TZ NOT NULL,
    priority VARCHAR(20) NOT NULL,
    priority_rank INTEGER NOT NULL,
    flexibility_level VARCHAR(20) NOT NULL,
    max_delay_hours INTEGER NOT NULL,
    interruptible VARCHAR(3) NOT NULL,
    sla_required VARCHAR(3) NOT NULL,
    status VARCHAR(30) NOT NULL,
    data_source VARCHAR(50) NOT NULL,
    CONSTRAINT pk_ai_workloads PRIMARY KEY (workload_id),
    CONSTRAINT ck_workload_duration CHECK (duration_hours > 0),
    CONSTRAINT ck_workload_power CHECK (power_requirement_kw > 0),
    CONSTRAINT ck_priority_rank CHECK (priority_rank BETWEEN 1 AND 4),
    CONSTRAINT ck_flexibility CHECK (
        flexibility_level IN ('FIXED', 'LIMITED', 'FLEXIBLE')
    )
);

CREATE OR REPLACE TABLE ELECTRICITY_TARIFFS (
    timestamp TIMESTAMP_TZ NOT NULL,
    location_id VARCHAR(50) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    tariff_per_kwh NUMBER(12,4) NOT NULL,
    tariff_category VARCHAR(40) NOT NULL,
    demand_charge_per_kw NUMBER(12,4) NOT NULL,
    data_source VARCHAR(50) NOT NULL,
    CONSTRAINT pk_electricity_tariffs PRIMARY KEY (timestamp, location_id),
    CONSTRAINT ck_tariff_nonnegative CHECK (tariff_per_kwh >= 0),
    CONSTRAINT ck_demand_charge_nonnegative CHECK (demand_charge_per_kw >= 0)
);

CREATE OR REPLACE TABLE RENEWABLE_AVAILABILITY (
    timestamp TIMESTAMP_TZ NOT NULL,
    location_id VARCHAR(50) NOT NULL,
    solar_power_kw NUMBER(12,2) NOT NULL,
    contracted_green_power_kw NUMBER(12,2) NOT NULL,
    renewable_power_kw NUMBER(12,2) NOT NULL,
    renewable_percentage NUMBER(6,2) NOT NULL,
    forecast_confidence NUMBER(5,3) NOT NULL,
    data_source VARCHAR(50) NOT NULL,
    CONSTRAINT pk_renewable_availability PRIMARY KEY (timestamp, location_id),
    CONSTRAINT ck_renewable_percentage CHECK (
        renewable_percentage BETWEEN 0 AND 100
    ),
    CONSTRAINT ck_forecast_confidence CHECK (
        forecast_confidence BETWEEN 0 AND 1
    )
);

CREATE OR REPLACE TABLE GRID_CONDITIONS (
    timestamp TIMESTAMP_TZ NOT NULL,
    location_id VARCHAR(50) NOT NULL,
    grid_load_percentage NUMBER(6,2) NOT NULL,
    carbon_intensity_gco2_per_kwh NUMBER(12,2) NOT NULL,
    grid_status VARCHAR(30) NOT NULL,
    frequency_stability_score NUMBER(8,4) NOT NULL,
    active_event VARCHAR(100),
    data_source VARCHAR(50) NOT NULL,
    CONSTRAINT pk_grid_conditions PRIMARY KEY (timestamp, location_id),
    CONSTRAINT ck_grid_load CHECK (
        grid_load_percentage BETWEEN 0 AND 100
    ),
    CONSTRAINT ck_carbon_nonnegative CHECK (
        carbon_intensity_gco2_per_kwh >= 0
    ),
    CONSTRAINT ck_frequency_stability CHECK (
        frequency_stability_score BETWEEN 0 AND 1
    ),
    CONSTRAINT ck_grid_status CHECK (
        grid_status IN ('NORMAL', 'WATCH', 'CONSTRAINED')
    )
);

CREATE OR REPLACE TABLE COMPUTE_CAPACITY (
    timestamp TIMESTAMP_TZ NOT NULL,
    location_id VARCHAR(50) NOT NULL,
    total_capacity_kw NUMBER(12,2) NOT NULL,
    reserved_capacity_kw NUMBER(12,2) NOT NULL,
    available_capacity_kw NUMBER(12,2) NOT NULL,
    utilization_percentage NUMBER(6,2) NOT NULL,
    gpu_cluster_availability_percentage NUMBER(6,2) NOT NULL,
    capacity_status VARCHAR(30) NOT NULL,
    data_source VARCHAR(50) NOT NULL,
    CONSTRAINT pk_compute_capacity PRIMARY KEY (timestamp, location_id),
    CONSTRAINT ck_total_capacity_positive CHECK (total_capacity_kw > 0),
    CONSTRAINT ck_reserved_capacity_nonnegative CHECK (reserved_capacity_kw >= 0),
    CONSTRAINT ck_available_capacity_nonnegative CHECK (available_capacity_kw >= 0),
    CONSTRAINT ck_utilization_percentage CHECK (
        utilization_percentage BETWEEN 0 AND 100
    ),
    CONSTRAINT ck_gpu_availability CHECK (
        gpu_cluster_availability_percentage BETWEEN 0 AND 100
    ),
    CONSTRAINT ck_capacity_status CHECK (
        capacity_status IN ('AVAILABLE', 'TIGHT', 'MAINTENANCE')
    )
);

CREATE OR REPLACE TABLE OPTIMIZATION_RUNS (
    optimization_run_id VARCHAR(50) NOT NULL,
    created_at TIMESTAMP_TZ DEFAULT CURRENT_TIMESTAMP(),
    created_by VARCHAR(100),
    objective_cost_weight NUMBER(8,4) DEFAULT 0.45,
    objective_carbon_weight NUMBER(8,4) DEFAULT 0.35,
    objective_grid_weight NUMBER(8,4) DEFAULT 0.20,
    run_status VARCHAR(30) DEFAULT 'DRAFT',
    approved_at TIMESTAMP_TZ,
    notes VARCHAR(1000),
    CONSTRAINT pk_optimization_runs PRIMARY KEY (optimization_run_id)
);

CREATE OR REPLACE TABLE OPTIMIZED_SCHEDULE (
    optimization_run_id VARCHAR(50) NOT NULL,
    workload_id VARCHAR(20) NOT NULL,
    baseline_start TIMESTAMP_TZ NOT NULL,
    recommended_start TIMESTAMP_TZ NOT NULL,
    duration_hours INTEGER NOT NULL,
    baseline_cost_myr NUMBER(14,2),
    optimized_cost_myr NUMBER(14,2),
    baseline_emissions_kgco2 NUMBER(14,2),
    optimized_emissions_kgco2 NUMBER(14,2),
    cost_saving_myr NUMBER(14,2),
    emissions_reduction_kgco2 NUMBER(14,2),
    deadline_met BOOLEAN,
    capacity_feasible BOOLEAN,
    recommendation_reason VARCHAR(2000),
    decision_status VARCHAR(30) DEFAULT 'PENDING',
    CONSTRAINT pk_optimized_schedule PRIMARY KEY (
        optimization_run_id, workload_id
    )
);

CREATE OR REPLACE VIEW HOURLY_ENERGY_CONTEXT AS
SELECT
    t.timestamp,
    t.location_id,
    t.currency,
    t.tariff_per_kwh,
    t.tariff_category,
    t.demand_charge_per_kw,
    r.solar_power_kw,
    r.contracted_green_power_kw,
    r.renewable_power_kw,
    r.renewable_percentage,
    r.forecast_confidence,
    g.grid_load_percentage,
    g.carbon_intensity_gco2_per_kwh,
    g.grid_status,
    g.frequency_stability_score,
    g.active_event,
    c.total_capacity_kw,
    c.reserved_capacity_kw,
    c.available_capacity_kw,
    c.utilization_percentage,
    c.gpu_cluster_availability_percentage,
    c.capacity_status
FROM ELECTRICITY_TARIFFS t
JOIN RENEWABLE_AVAILABILITY r
    ON t.timestamp = r.timestamp
   AND t.location_id = r.location_id
JOIN GRID_CONDITIONS g
    ON t.timestamp = g.timestamp
   AND t.location_id = g.location_id
JOIN COMPUTE_CAPACITY c
    ON t.timestamp = c.timestamp
   AND t.location_id = c.location_id;
