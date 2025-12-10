WITH 

web_events AS (
    SELECT 
        client_id,
        event_name,
        event_timestamp,
    FROM {{ ref('stg_web_events') }}
    WHERE event_name IN (
        'page_viewed',
        'product_added_to_cart',
        'checkout_started',
        'checkout_completed'
    )
),

milestone_timestamps AS (
    SELECT 
        client_id,
        MIN(CASE WHEN event_name = 'page_viewed' THEN event_timestamp END) AS page_viewed_at,
        MIN(CASE WHEN event_name = 'product_added_to_cart' THEN event_timestamp END) AS product_added_to_cart_at,
        MIN(CASE WHEN event_name = 'checkout_started' THEN event_timestamp END) AS checkout_started_at,
        MIN(CASE WHEN event_name = 'checkout_completed' THEN event_timestamp END) AS checkout_completed_at
    FROM web_events
    GROUP BY client_id
),

final as (
    SELECT 
        client_id,
        page_viewed_at,
        product_added_to_cart_at,
        checkout_started_at,
        checkout_completed_at
    FROM milestone_timestamps
)

select * from final
