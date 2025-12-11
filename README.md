# Puffy Marketing Analytics – Take-Home Assignment

This repository contains my solution for Puffy’s **Head of Data Infrastructure & Analytics** skills test. It implements a small but realistic analytics stack for DTC marketing performance using sampled, anonymized event data.

The project is built around a **layered dbt modeling approach** (staging → intermediate → star → marts) to support robust, maintainable marketing analytics.

> **Note on Emphasis:**  
> Because the job posting strongly emphasized **data quality**, additional effort in this exercise was placed on **validation, testing, and correctness** within the time available.

---

## 1. Project Structure

├─ models/
│ ├─ staging/
│ ├─ intermediate/
│ ├─ star/
│ └─ marts/
├─ seeds/
├─ analyses/
├─ tests/
├─ macros/
├─ dbt_project.yml
├─ part_1_documentation.md
├─ part_2_documentation.md
├─ part_3_documentation.md
├─ part_4_documentation.md
└─ README.md

This repository also includes four standalone documents, each addressing a specific required part of the assignment:
- part_1_documentation.md - Incoming Data Quality Framework
- part_2_documentation.md - Transformation Pipeline
- part_3_documentation.md - Business Analysis
- part_4_documentation.md - Production Monitoring
These documents provide deeper explanations, diagrams, and reasoning behind the technical implementation contained in the dbt project.

### `models/staging/`
- One model per raw source table (e.g., event streams, ad platform exports, orders).
- Standardizes column naming, typing, timestamp formatting.
- Performs lightweight cleansing (dedupe, filtering invalid events).
- **Goal:** Clean, consistent, trustworthy base tables for downstream modeling.
- staging.yml documents the models in this folder and defines the data tests configured for them.

### `models/intermediate/`
- Business logic + multi-source joins.
- Examples: sessionization, touchpoint enrichment, order-to-event relationships.
- Encodes logic once → reused across star models.
- **Goal:** Central place for important business transformations.
- intermediate.yml documents the models in this folder and defines the data tests configured for them.

### `models/star/`
- Dimensional **facts & dimensions** with clearly documented grain.
- Examples: `fct_events`, `dim_users`, `fct_marketing_touches`.
- **Goal:** Analyst-friendly, joinable semantic layer following Kimball principles.
- star.yml documents the models in this folder and defines the data tests configured for them.

### `models/marts/`
- Final business views tailored for stakeholders.
- Examples: channel ROAS, CAC & payback, funnel performance, cohorts.
- **Goal:** BI-ready tables that can power dashboards/reports directly.


### `tests/`
- Contains custom data tests written specifically for this assignment.
- These tests go beyond dbt's built-in generic tests (not_null, unique, accepted_values, etc.) to validate deeper data quality expectations that are critical for marketing analytics.

---

## 2. Technology Used

This project was **implemented using:**

- **dbt Cloud** (free-tier account)
- **Snowflake** (free-tier account)
- **GitHub**

These choices reflect the enterprise-grade tooling commonly used in modern DTC and marketing analytics stacks.

---

## 3. Running the Project

You may run this code in one of two ways:

### Option A — Run using **dbt Cloud + Snowflake** (recommended)

A free dbt Cloud account and a free Snowflake account are sufficient.

Setup instructions:  
👉 https://docs.getdbt.com/docs/cloud/about-cloud-setup