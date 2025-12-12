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

checkouts_completed as (
    select * from {{ ref('int_web_checkout_completed_attribution') }}    
),

total_number_checkouts_completed as (
    select
        client_id,
        max(client_purchase_sequence) as total_checkouts_completed
    from checkouts_completed
    group by all
),

final as (
    SELECT 
        client_aggregates.client_id,
        client_aggregates.total_events,
        client_aggregates.total_sessions,
        client_aggregates.total_revenue,
        DATEDIFF('day', first_event_timestamp, last_event_timestamp) AS days_active,
        total_number_checkouts_completed.total_checkouts_completed
        
    FROM client_aggregates 

    LEFT JOIN total_number_checkouts_completed
        on total_number_checkouts_completed.client_id = client_aggregates.client_id
    
    WHERE client_aggregates.client_id is not null
)

select * from final