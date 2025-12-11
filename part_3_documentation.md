# Part 3: Business Analysis

## Overview

A preliminary analysis of the transformed event data reveals meaningful opportunities to understand user behavior, channel performance, and revenue drivers. However, significant data quality issues prevent us from drawing reliable business conclusions at this stage. Before presenting a full performance assessment, it is essential to address gaps in tracking completeness, attribution signals, and revenue consistency.

The sections below outline (1) the most critical issues affecting data trustworthiness, and (2) the types of insights the business will be able to generate once data quality is restored.

---

## 1. Critical Data Quality Issues Impacting Analysis

### Incomplete Customer Journey Tracking
Out of **284 users who completed checkout**, substantial portions of the buyer journey are missing:

- Only **131** had a *checkout started* event → **46% completeness**  
- Only **158** had a *product added to cart* event → **56% completeness**  
- Only **234** had a *page viewed* event → **82% completeness**

For nearly half of purchasers, the upstream steps in their journey are not recorded. This makes funnel analysis, conversion rate modeling, and channel optimization impossible to interpret reliably.

### Additional Integrity Issues Identified
Across the 14-day dataset, several material data quality issues were found:

- **2,908 raw events** are missing `client_id`, even after correcting the schema change  
- **5 entire days** where `referrer` values are missing  
- **4 duplicated `transaction_id`s**, which should be unique  
- **77 of 294 (26%) transactions** show revenue mismatches between order-level totals and line-item details  

These issues suggest inconsistencies in the event pipeline and raise concern about the accuracy of revenue reporting, attribution logic, and user-level analytics.

### Impact on Business Insights
Given the above issues, any conclusions drawn from the current dataset would be unreliable. Conversion rates, channel performance metrics, and revenue attribution would all be distorted by missing events, incomplete funnels, and inconsistent transaction data.

**Before moving forward with performance interpretation, the business needs a stable and trustworthy data foundation.**

---

## 2. Insights That Become Possible Once Data Quality Is Resolved

Once tracking gaps and schema issues are addressed, the transformation layer built in this project will support a wide range of high-value analyses for Marketing, Product, and Executive teams.

---

### A. Customer Cohort Behavior
- Conversion rates by acquisition cohort (day, week, campaign, channel)  
- Which channels bring high-quality customers (higher conversion, faster conversion, higher LTV)  
- Comparison of lifetime value across acquisition sources  

This enables budget prioritization and forecasting.

---

### B. Device, Browser, & Technical Performance
- Conversion rate differences between mobile and desktop  
- Technical issues (load times, errors) correlated with lower conversion  
- Behavioral differences between research-oriented and purchase-oriented devices  

This guides UX optimization and engineering prioritization.

---

### C. Revenue & Ordering Behavior
- Average order value by channel  
- Category-level performance by source  
- Revenue distribution by device, session behavior, or user type  

This supports merchandising decisions and channel ROAS assessments.

---

### D. Marketing Channel & Attribution Insights
- First-touch vs. last-touch vs. assisted conversion contributions  
- How often first-touch and last-touch disagree  
- Number of assisted conversions per channel  
- Incremental lift when a channel participates in the user journey  

These insights help determine which channels drive incremental revenue and where to invest.

---

## Conclusion

The business has strong potential to uncover meaningful insights about customer behavior, marketing effectiveness, and revenue drivers. However, **major data quality gaps must be addressed before performance can be evaluated with confidence.**

Once these foundational issues are resolved, the transformation architecture already built will enable robust customer journey analytics, accurate attribution, and actionable insights for senior leadership.
