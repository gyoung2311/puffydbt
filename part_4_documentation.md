# Part 4 — Production Monitoring Framework

A daily production pipeline must be continuously monitored to ensure that the data feeding dashboards and marketing decisions is both **accurate** and **fresh**. The monitoring system designed here focuses on detecting issues early, preventing incorrect metrics, and providing clear, actionable alerts to stakeholders.

All tests run automatically as part of the dbt pipeline. Failures and warnings can be routed to Slack or a monitoring tool such as DataDog for rapid visibility.

---

## 1. What We Monitor and Why

Our monitoring framework focuses on three categories of checks:

### **A. Data Quality (Correctness)**
Ensures that the data entering the warehouse is complete, valid, and internally consistent.

### **B. Data Freshness**
Ensures that new data continues to arrive as expected.

### **C. Business-Critical Validations**
Ensures that key revenue and attribution metrics remain accurate during daily operations.

This layered approach reduces risk by catching upstream collection issues, schema drift, transformation errors, and unexpected gaps before they impact decision-making.

---

## 2. Data Quality Checks (Automated Daily)

### **Web Events Staging Layer (`stg_web_events`)**
This is the first point where raw activity data enters the analytics system.

We monitor:

- **Client ID present**  
  Required to connect events to users. Missing values indicate tracking failures.

- **Page URL present**  
  Ensures accurate behavior analysis and funnel attribution.

- **Event Name valid**  
  - Must be one of five expected event types.  
  - Prevents typos, malformed events, and instrumentation bugs.

- **Event Timestamp present**  
  Without timestamps, sessionization and attribution fail.

- **Referrer completeness (custom test)**  
  We detect if an **entire day** is missing referrer data. This protects against ingestion or client-side tracking failures.

- **Transaction ID uniqueness**  
  Ensures that purchases are not double-counted.

These checks detect schema drift, ingestion gaps, and malformed events—issues that commonly cause incorrect revenue or funnel reporting.

---

### **Intermediate Web Events (`int_web_events`)**
After sessionization:

- **Client ID present**  
- **Event Timestamp present**

These ensure that the process of generating sessions has preserved critical user and event metadata.

---

### **Checkout Attribution (`int_web_checkout_completed_attribution`)**
This table must be highly accurate because it powers revenue dashboards.

We validate:

- **Transaction ID present**  
- **Revenue present**  
- **Client ID present**  
- **Checkout timestamp present**

#### **Revenue Accuracy Checks**
Two critical reconciliation tests ensure revenue integrity:

1. **Revenue matches sum of item-level revenue**  
   Detects upstream mismatches or partial ingestion.  
   Previously identified **77 of 294 (26%)** transactions with inconsistent totals.

2. **Revenue matches raw source data (`stg_web_events`)**  
   Ensures that transformations do not alter totals.

Both are implemented using **dbt-expectations** for ongoing monitoring.

---

### **Order Details (`int_web_checkout_completed_order_details`)**
We verify:

- `transaction_id` present  
- `item_revenue` present  
- `client_id` present  
- `event_timestamp` present  

This ensures the completeness of transaction line-item data—critical for revenue, AOV, and product mix reporting.

---

### **Final Marts (`dim_clients`, `fct_client_journey`, `fct_client_metrics`)**
These do not yet have data quality checks, but would be included in future phases, such as:

- Funnel step ordering validation  
- Impossible sequence detection (e.g., checkout completed without event chain)  
- Attribution completeness checks  

---

## 3. Custom Quality Checks

### **1. Not-Null-for-Entire-Day**
Detects whether a field is missing *all day*, which is a common signal of:

- Client-side tag firing issues  
- Analytics platform outages  
- Misconfigured instrumentation  

Used today to monitor referrer completeness.

---

### **2. Revenue Matches Item Sum**
A reconciliation test verifying that:
    SUM(order_total) == SUM(line_item_total)


Critical for:
- ROAS
- CAC
- Revenue dashboards  
- Finance reconciliation  

---

## 4. Data Freshness Monitoring

### **Source Freshness (`sources.yml`)**

We monitor how recently new raw website events have arrived:

- **Warning at 12 hours** — early signal of delays  
- **Error at 24 hours** — indicates ingestion failure and requires immediate action  

This protects the business from making decisions on stale data and ensures morning dashboards reflect the latest ordering behavior and traffic.

---

## 5. How We Detect When Something Is Wrong

When a threshold is breached or a test fails:

- dbt marks the run with warnings/errors  
- Alerts are sent to Slack, DataDog, or PagerDuty  
- The data team is notified before dashboards refresh  
- The bad data can be quarantined, preventing inaccurate metrics from reaching executives

This minimizes damage and makes the system resilient to:

- Tracking outages  
- Schema changes  
- Broken ETL logic  
- Upstream platform issues  

---

## 6. Why This Monitoring System Works

- **Comprehensive:** Covers raw data, transformations, revenue, attribution, and freshness  
- **High-signal:** Focuses on issues that materially impact business reporting  
- **Automated & daily:** Tests run every pipeline execution  
- **Actionable:** Clear alerts tell the team exactly where the issue is  
- **Scalable:** New checks can be added as new events, channels, or models are introduced  

This ensures that the company’s operational dashboards and marketing decisions are always powered by accurate, trustworthy data.


