# Part 2 — Transformation Pipeline: Methodology & Architecture

## 1. Design Philosophy

The transformation pipeline is designed around the **analyses the business needs to perform**.  
Rather than simply restructuring raw data, each model is built to support the core questions Marketing and Analytics teams need to answer:

### Example business questions that directly informed the design:

### User Behavior & Site Engagement
- Which pages or sequences of pages have the highest drop-off rates?
- How do new visitors behave differently from returning visitors?
- What percentage of users bounce within the first session?

### Channel & Attribution Insights
- What percentage of conversions come from first-touch vs. last-touch vs. assisted interactions?
- How often do first-click and last-click attribution disagree for the same conversion?
- How many assisted conversions does each channel contribute?
- What is the incremental lift of each marketing channel when included in the user journey?

### Customer Cohort Behavior
- How do conversion rates vary by acquisition cohort (day, week, channel, campaign)?
- Do certain channels produce higher-quality users (higher conversion rate, faster conversion, higher LTV)?
- What is the lifetime value (LTV) of customers acquired through different channels?

### Device, Browser, & Technical Performance
- Do conversion rates differ meaningfully by device type, OS, or browser?
- Are there performance issues (slow page load times, errors) associated with lower conversion rates?
- Do mobile sessions tend to be more research-focused while desktop sessions convert more frequently?

### Session Behavior Patterns
- How many sessions does it typically take for a user to convert?
- What proportion of users convert within their first session?
- How does session length impact conversion likelihood?

### Revenue & Ordering Behavior
- What is the average order value (AOV) by marketing channel?
- Are specific product categories associated with particular acquisition sources?
- How does revenue distribution differ across devices, sessions, or user types?

### Operational & Anomaly Detection
- Are there unusual spikes or drops in session volume, conversion rate, or revenue?
- Do certain channels experience tracking degradation (sudden missing referrer, inconsistent event patterns)?
- Are attribution inconsistencies or missing touchpoints increasing over time?

This ensures that the transformed data is not only technically correct but directly aligned with stakeholder workflows and decision-making.

---

## 2. Layered dbt Architecture

The solution uses a scalable, industry-standard **dbt layered modeling approach**: staging → intermediate → star → marts.

### `models/staging/`
- Normalizes raw incoming event data  
- Fixes schema drift issues  
- Standardizes column names, types, and timestamps  
- Introduces initial data tests for foundational data quality  
- Provides a clean, consistent starting point for downstream transformations  

### `models/intermediate/`
- Encodes **business logic** that is reused across multiple tables  
- Performs **sessionization**, device parsing, and back filling UTM parameters
- Extracting use case specific data from events. Ex: Line item details only for conversion events
- Derives marketing touchpoints, landing page logic, and referrer information  
- Produces reusable building blocks that can be assembled into analytics datasets  

### `models/star/` (Facts & Dimensions)
- Kimball star schema models

### `models/marts/`
- Curated, business-facing datasets designed for reporting and dashboards  
- Includes first-click and last-click attribution models (7-day lookback)  
- Supports channel/campaign performance, user engagement analyses, and funnel reporting  
- Represents the final “single source of truth” consumed by Marketing  

---

## 3. Architectural Choice: Kimball vs. Inmon vs. OBT

A key design decision was **selecting a Kimball-style star schema** as the foundation of the analytics warehouse.  
Here is the reasoning behind this choice:

### **Kimball Star Schema (Chosen Approach)**
- Organizes data into **facts and dimensions** with clear business meaning  
- Highly performant for analytical queries  
- Enables easy extensibility as new channels, events, or behaviors are added  
- Produces a **semantic layer** that analysts can understand intuitively  
- Works extremely well with dbt’s modular, incremental modeling approach  
- Reduces duplication and centralizes metric logic  

Given Puffy’s need for:
- Behavioral analytics  
- Attribution modeling  
- Marketing performance reporting  
- Flexible, reusable building blocks  

…the Kimball approach provides the strongest balance of structure, usability, and scalability.

---

### **Inmon (Corporate Information Factory)**
Not chosen because:

- Inmon emphasizes a **3NF enterprise warehouse**, which is normalized and integration-first  
- Excellent for very large, multi-domain enterprises with decades of data  
- But significantly **slower to build**, more rigid, and less intuitive for analysts  
- Requires additional modeling to convert normalized data into usable reporting tables  

Given this is a focused DTC business with a strong need for speed and iteration, Inmon introduces unnecessary overhead.

---

### **OBT (One Big Table)**
Not chosen because:

- While OBT makes initial development fast, it leads to:  
  - Heavy duplication  
  - Metrics defined in multiple places  
  - Increased compute costs  
  - Unmaintainable SQL over time  
- Changes in business logic require recalculating or rewriting large, monolithic tables  
- Attribution logic (especially first-click and last-click) becomes difficult to maintain or validate  

For a business growing rapidly and needing consistent marketing metrics, OBT would not scale operationally or analytically.

---

### **Why Kimball Was the Best Fit**
The Kimball star schema provides:

- **Fast development** (compared to Inmon)  
- **High maintainability** (compared to OBT)  
- **Clear, reusable data building blocks**  
- **A metric-first architecture for attribution and funnel analysis**  
- **Logical separation** between user, session, event, and marketing data  

This architecture balances agility with long-term sustainability—ideal for a modern DTC analytics stack.

---

## 4. Centralized Metric Definitions

The architecture is intentionally designed so that **metric logic is defined once and reused everywhere**.  
By consolidating definitions such as:

- Session rules  
- Attribution windows  
- Conversion logic  
- Revenue definitions  

…we ensure:

- Consistency across teams and dashboards  
- Reduced duplication in SQL logic  
- Easier updates when business rules evolve  
- Higher trust in KPIs  

This semantic-first approach aligns with modern data modeling best practices.

---

## 5. Reusable Data Assets as Building Blocks

The pipeline emphasizes creating **modular, reusable data assets** that can be quickly combined to support new analysis needs.

Examples:
- Sessionization logic is shared across attribution, engagement, and funnel models  
- Marketing touchpoint derivation feeds both first-click and last-click attribution  
- Dimensions such as channel, device, and user can join into any fact model without repeated logic  

This design dramatically reduces manual data prep and allows analysts to spend more time on **interpretation rather than transformation**.

---

## 6. End-to-End Data Quality Monitoring

Data quality is validated at every stage of the pipeline—not just ingestion.

This ensures data is not accidently filtered out during the transformation process or any fan-outs the would cause duplicate date to get introduced.

Continuous validation ensures that as data flows **raw → staging → intermediate → star → marts**, anomalies are caught early and prevented from influencing business metrics.


---
---
---

## How I Define Users

## Current Approach

Based on the available raw event data, I've implemented a straightforward user definition: **a `client_id` represents a user**. This identifier is used throughout the transformation pipeline to:

- Track user journeys across sessions (as implemented in `fct_client_journey.sql`)
- Build client-level dimensions and aggregates (in `dim_clients.sql`)
- Perform sessionization (grouping events by `client_id` with a 30-minute inactivity threshold)
- Calculate user-level metrics such as conversion rates, time-to-purchase, and lifetime value

## Limitations & Data Quality Considerations

This approach has known limitations that I've documented and accounted for:

1. **Missing identifiers**: 2,908 raw events are missing `client_id` values entirely, which means some user behavior cannot be attributed
2. **No cross-device stitching**: A user browsing on mobile and then purchasing on desktop would appear as two separate users
3. **No anonymous-to-identified mapping**: If a user starts as anonymous and later provides an email (captured in `event_data.user_email`), these events remain separate under the current model
4. **Cookie/browser limitations**: `client_id` is likely browser/cookie-based, so users clearing cookies or using multiple browsers appear as distinct users


---


## How I Approach Sessionization

Sessionization is the process of grouping individual raw events into coherent user sessions that reflect a visitor’s continuous interaction with the site. A well-defined session model is foundational for understanding user behavior, engagement, and eventual conversion paths.

### 1. Session Definition
A **session** is defined as a sequence of events from the same user (`client_id`) where **no more than 30 minutes of inactivity** occurs between consecutive events.  
This 30-minute threshold is the industry standard for web analytics and aligns with the natural patterns of browsing behavior.

Formally:
- A new session begins when:
  - The user has no prior event (first visit), or
  - The time difference from the previous event > **30 minutes**

### 2. Session Construction Logic
The sessionization model (`int_sessions` in dbt) performs the following steps:

1. **Sort events** by `client_id` and `event_ts`
2. **Calculate the time difference** to the previous event for each user
3. **Flag new sessions** whenever:
   - The session gap > 30 minutes  
   - Or the user ID changes
4. **Assign a session ID**:
   - A sequential session counter per user (`session_number`)
   - A composite key (`client_id || session_number`) or hashed surrogate key
5. **Identify the session’s landing attributes**:
   - `landing_page`
   - `landing_referrer`
   - `landing_device_type`
   - `landing_marketing_channel` (derived from UTM/referrer rules)


---

### What Attributes and Metrics Do You Choose to Calculate?

I focused on creating attributes and metrics that directly help the business understand user behavior, funnel performance, and marketing effectiveness.

**Revenue Metrics**
- Total revenue, as well as daily and weekly revenue trends  
  (to monitor performance and quickly detect anomalies)

**Funnel & Conversion Metrics**
- Conversion rates and drop-off rates through the key customer journey steps:  
  *landing → product added to cart → checkout started → checkout completed*  
- These reveal where users abandon the journey and where optimizations are needed.

**Session Behavior Metrics**
- Number of sessions it takes for a user to make their first purchase  
  (helps identify whether users convert immediately or require multiple touchpoints)

**Time-to-Conversion Metrics**
- How long it takes users to reach each milestone in the journey  
  (e.g., time from landing to first action, time from checkout start to purchase)

Together, these metrics provide a holistic picture of how users interact with the site, how effectively marketing channels drive engagement and revenue, and where the biggest opportunities for improving the customer journey exist.


---

### Marketing Channel Categorization

To determine which marketing channels should receive credit for driving revenue, we first need a reliable way to classify each session or visit into a meaningful channel. 
In the dataset provided, there is not enough information to fully determine marketing channels out of the box. In practice, channel classification typically requires a combination of:

1. **Click IDs** (highest fidelity signal)  
2. **UTM parameters** (medium, source, campaign)  
3. **Referrer and landing page patterns** as fallback

This layered approach ensures robustness even when some fields are missing or inconsistently captured.

#### Example of a Simple, Robust Channel Mapping Ruleset

Below is an example classification framework commonly used in performance marketing analytics:

1. **Paid Search**  
   - If `gclid` exists  
   - Or (`utm_source = google` AND `utm_medium IN ('cpc', 'paid_search')`)  
   - Or `msclkid` exists (Microsoft Ads)

2. **Paid Social**  
   - If `utm_medium IN ('paid_social', 'cpc_social')`  
   - Or `utm_source` belongs to known paid social platforms (Meta, TikTok, Snap) *and* medium indicates paid traffic  

3. **Email**  
   - If `utm_medium = 'email'`  
   - Or referrer matches known ESP redirect domains  

4. **Affiliate / Partner**  
   - If `utm_medium IN ('affiliate', 'partner')`

5. **Referral**  
   - If `utm_medium = 'referral'`
   - Or referrer is present but not a search engine or social platform  

6. **Organic Search**  
   - If referrer is a known search engine (Google, Bing, Yahoo)  

7. **Organic Social**  
   - If referrer is a social platform and UTMs do not indicate paid traffic  

8. **Direct**  
   - Everything else (no UTMs, no referrer, or user typed URL manually)


---

### Validation: How I Prove the Transformation Is Correct

To ensure the transformation layer is accurate, complete, and reliable, I validated each major component of the pipeline using a combination of manual checks, reconciliation tests, and automated dbt data tests. This ensures both one-time correctness and ongoing integrity as data continues to flow through the system.

---

## 1. Revenue Validation

**Manual Reconciliation (Initial Validation)**  
- I first manually reconciled `transaction_id` revenue values between `stg_web_events` and `int_web_checkout_completed_attribution`.  
- For every transaction, the summed revenue in staging matched the attributed revenue downstream.

**Automated Continuous Validation**  
- After confirming correctness manually, I implemented a `dbt_expectations.expect_table_aggregation_to_equal_other_table` test to continuously verify that the **sum of attributed revenue equals the sum of raw checkout revenue**.
- I then validated the relationship between order-level revenue and line-item revenue in `int_web_checkout_completed_order_details`.  
  - This surfaced **71 transaction_ids** where line-item totals did not equal the order revenue in staging.
  - To monitor this going forward, I added a dbt data test (`revenue_matches_item_sum`) to detect mismatches.

This two-step process—manual truth-checking followed by automated enforcement—ensures revenue integrity throughout the attribution pipeline.

---

## 2. UTM Parameter Filling (First- and Last-Touch Attribution)

To validate the session-level marketing metadata (forward-filled UTMs, first-touch UTMs, last-touch UTMs):

**Manual Validation Across Random and Edge-Case Users**
- I randomly sampled multiple `client_id`s and manually traced event sequences to confirm that UTMs were filled correctly within each session.
- I then validated more complex edge cases, such as users whose UTM parameters changed partway through a session (e.g., `client_id = 1741367456-uz2V75aLolvU`).  
  - These cases verified that the logic correctly assigned first-touch and last-touch values based on time-ordering.
- I also identified users with the largest number of distinct UTM combinations and manually validated their session logic to ensure attribution behaved as expected.

This combination of random sampling and targeted edge-case testing confirmed that UTM filling and attribution logic were functioning as designed.

---

## 3. Client Purchase Funnel Validation

To validate the transformation that powers the purchase funnel (landing → add to cart → checkout start → checkout completed):

**Manual Event Path Tracing**
- I selected multiple `client_id`s and manually reconciled their funnel stages against the raw events.

**Investigation of Unusual Cases**
- I intentionally searched for anomalies, such as:
  - A user having a checkout completed event but no checkout started event  
  - A user completing checkout without an add-to-cart event  
- For each anomaly, I manually traced all raw event data to ensure the transformation correctly represented the underlying behavior and that the issue originated from source data, not transformation logic.

This confirmed that the funnel logic accurately reflects user behavior—even in unusual cases—and that the pipeline does not introduce false assumptions.

---