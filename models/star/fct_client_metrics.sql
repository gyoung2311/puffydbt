WITH web_events AS (
    SELECT 
        client_id,
        event_timestamp,
        event_name,
        revenue,
        session_number
    FROM {{ ref('int_web_events') }}
),

client_aggregates AS (
    SELECT 
        client_id,
        MIN(event_timestamp) AS first_event_timestamp,
        MAX(web_events.event_timestamp) AS last_event_timestamp,

        COUNT(*) AS total_events,
        COUNT(DISTINCT session_number) AS total_sessions,
        SUM(COALESCE(revenue, 0)) AS total_revenue
    FROM web_events
    GROUP BY client_id
),

final as (
    SELECT 
        client_id,
        total_events,
        total_sessions,
        total_revenue,
        DATEDIFF('day', first_event_timestamp, last_event_timestamp) AS days_active

    FROM client_aggregates 
)

select * from final