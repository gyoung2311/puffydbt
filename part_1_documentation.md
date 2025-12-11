# Part 1 — Incoming Data Quality Framework

This document outlines the data quality validation framework built to detect issues in the incoming raw event stream before data enters production analytics. The goal is to ensure that schema drift, missing values, and revenue inconsistencies are caught early—preventing incorrect metrics in dashboards, as occurred during this 14-day period.

Data Tests implemented using a combination of out of the box dbt tests, custom written tests and dbt expectations package.

---

## 1. What the Framework Checks and Why

### 1.1 Schema Drift Detection
The provided raw dataset exhibited **schema drift**, which is one of the most common and high-impact issues in event pipelines.

Identified issues:
- `client_id` field renamed to `clientid` beginning **27-Feb-2025**
- `referrer` column missing entirely beginning **4-Mar-2025**

Schema drift can silently break downstream models by producing nulls, incorrect joins, and missing fields.

To detect this class of issues, the framework includes:
- Column-level **not-null tests** for required fields
- A custom dbt test: **`not_null_for_entire_day`**, which flags when a column becomes **fully null for any day**, indicating a structural change or ingestion failure

The custom test is parameterized and reusable across any column.

Code: 
    staging.yml
    stg_web_events.sql
    not_null_for_entire_day.sql
---

### 1.2 Required Field Completeness
Certain fields should never be null because they are necessary for joining, attribution, and analytical correctness:

- `client_id`
- `page_url`
- `event_ts`
- `event_name`

dbt tests were added to ensure these fields are always present.

Code: 
    staging.yml
    stg_web_events.sql
    
---

### 1.3 Expected Values Validation
Some columns are expected to contain only a known, controlled set of values.

For example, `event_name` should only contain:

- `product_added_to_cart`
- `checkout_completed`
- `email_filled_on_popup`
- `page_viewed`
- `checkout_started`

dbt’s `accepted_values` test enforces this constraint and prevents misspelled or unintended event types from entering production analytics.

Code: 
    staging.yml
    stg_web_events.sql

---

### 1.4 Revenue Consistency Checks
The event data includes both:
- **A total revenue amount at the order level**, and  
- **Individual line items**, each with its own revenue value.

Because of this structure, the **sum of all line-item revenue values should always equal the total order revenue** for a given `transaction_id`. Any mismatch indicates an upstream data integrity problem that would cause incorrect revenue reporting.

To validate this, the framework includes tests that check:
- **Line-item revenue sum = total order revenue**  
- **`transaction_id` is unique**

Code: 
    int_web_events.sql
    int_web_checkout_completed_attribution.sql
    int_web_checkout_completed_order_details.sql
    intermediate.yml
    revenue_matches_item_sum.sql


---

## 2. Issues Identified by the Framework
- `client_id` field renamed to `clientid` beginning **27-Feb-2025**
- `referrer` column missing entirely beginning **4-Mar-2025**
- 2,908 raw events rows do not have client_id values, even after manually correcting for the schema change that renamed client_id to clientid.
- 5 days where there is no referrer values in raw events
- 4 transaction_ids that are duplicated
- 77/294 or 26% of transactions ID have mismatch revenue between order total and line items

---

## 3. Future Extensions

The framework is intentionally lightweight but can be expanded to include:

### Volume and Anomaly Detection
- Alerts for days when events, orders, or revenue fall outside expected historical ranges

### Cross-System Revenue Reconciliation
- Compare daily event-stream revenue to a source of truth  
  (e.g., Stripe, eCommerce or ERP)
- Alert when differences exceed a threshold

This protects against silent ingestion failures and enhances monitoring coverage.

---