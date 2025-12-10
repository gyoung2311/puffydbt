WITH web_events AS (
    SELECT 
        client_id,
        event_timestamp,
        page_url,
        referrer,
        device_type,
        base_url,
        event_name,
        utm_source,
        utm_medium,
        utm_campaign,
        utm_term,
        utm_content,
        google_click_id,
        ir_click_id,
        client_id_event_sequence
    FROM {{ ref('int_web_events') }}
),

first_events AS (
    SELECT 
        client_id,
        event_timestamp AS first_event_timestamp,
        page_url AS landing_page,
        referrer AS landing_referrer,
        device_type,
        base_url AS landing_base_url,
        event_name AS first_event_name,
        utm_source AS first_utm_source,
        utm_medium AS first_utm_medium,
        utm_campaign AS first_utm_campaign,
        utm_term AS first_utm_term,
        utm_content AS first_utm_content,
        google_click_id AS first_google_click_id,
        ir_click_id AS first_ir_click_id
    FROM web_events
    WHERE client_id_event_sequence = 1
),

client_aggregates AS (
    SELECT 
        client_id,
        MAX(web_events.event_timestamp) AS last_event_timestamp,
        MAX(CASE WHEN web_events.event_name = 'checkout_completed' THEN 1 ELSE 0 END) AS has_completed_checkout,
        MIN(CASE WHEN web_events.event_name = 'checkout_completed' THEN web_events.event_timestamp END) AS first_checkout_completed_at
    FROM web_events
    GROUP BY ALL
),

final as (
    SELECT
        first_events.*,
        client_aggregates.last_event_timestamp,
        client_aggregates.has_completed_checkout,
        client_aggregates.first_checkout_completed_at
    FROM first_events
    LEFT JOIN client_aggregates
        on client_aggregates.client_id = first_events.client_id

)

SELECT * from final

