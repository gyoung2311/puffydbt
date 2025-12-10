WITH web_events AS (
    SELECT 
        *
    FROM {{ ref('int_web_events') }}
),

first_events AS (
    SELECT 
        client_id,
        event_timestamp AS first_event_timestamp,
        page_url AS landing_page,
        referrer AS landing_referrer,
        device_type
    FROM web_events
    WHERE client_id_event_sequence = 1
),

final as (
    SELECT 
        client_id,
        first_event_timestamp,
        landing_page,
        landing_referrer,
        device_type 
    FROM first_events
)

select * from final
