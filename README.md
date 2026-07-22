# GridShift AI

**A Compute Flexibility and Energy Finance Copilot for the 2030 AI Infrastructure Era**

**Team:** MiawGlory

**Tagline:** Run AI when power is cleaner, cheaper, and available.

## Overview

GridShift AI is an intelligent workflow automation application for AI infrastructure operators. It analyzes AI workload requirements, electricity prices, renewable energy availability, grid conditions, and compute capacity. It then recommends a lower cost and lower carbon execution schedule while preserving workload deadlines and service level requirements.

## Problem

AI training and batch inference workloads are often scheduled without considering hourly electricity prices, renewable energy availability, grid congestion, carbon intensity, and operational deadlines. This can increase operating costs, emissions, and pressure on electricity networks.

## Solution

GridShift AI combines operational and energy data in Snowflake, evaluates feasible execution windows, recommends an optimized workload schedule, quantifies the financial and carbon impact, and allows an operator to approve the proposed plan.

## Primary Hackathon Track

**Intelligent Workflow Automation Agent**

## Target Users

1. Data center operators
2. AI infrastructure managers
3. Energy managers
4. Finance and sustainability teams

## MVP Features

1. Workload Overview
2. Energy Condition Analysis
3. Schedule Optimizer
4. Financial and Carbon Comparison
5. Approve Plan Workflow

## Decision Logic

The first MVP uses transparent rule based optimization. Each feasible execution slot receives a scheduling score based on:

1. Electricity cost
2. Carbon intensity
3. Grid congestion
4. Deadline compliance
5. Compute capacity

Real time workloads remain fixed. Flexible batch inference and model training workloads may be rescheduled only when capacity and deadlines are satisfied.

## Technology Stack

| Component | Technology |
|---|---|
| Data platform | Snowflake |
| Development assistant | Snowflake CoCo CLI |
| Data processing | Python and SQL |
| Application | Streamlit |
| AI explanation | Snowflake Cortex |
| Version control | GitHub |

## Dataset

The MVP uses a clearly labelled simulated dataset covering seven days of hourly energy conditions and a portfolio of AI workloads.

1. `ai_workloads.csv`
2. `electricity_tariffs.csv`
3. `renewable_availability.csv`
4. `grid_conditions.csv`
5. `compute_capacity.csv`

## Example Recommendation

> Move the flexible model training workload from 19:00 to 01:00. The revised schedule reduces estimated electricity cost and carbon emissions while maintaining the required completion deadline.

## Current Status

Project foundation and simulated dataset preparation are in progress.

## License

MIT License